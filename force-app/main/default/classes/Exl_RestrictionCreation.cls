public without sharing class Exl_RestrictionCreation {
    private static final String REQUESTED_STATUS = 'Requested';
    private static final String PENDING_STATUS = 'Pending';
    private static final String EXCLUSION_PENDING_STATUS = 'Exclusion Pending';
    private static final String REVOCATION_PENDING_STATUS = 'Revocation Pending'; 

    private static final Set<String> REQUESTED_RESTRICTION_TYPES = new Set<String>{
        'Discounts',
        'Hotel Bookings',
        'Parking benefits'
    };

    public class inputWrapper {
        @InvocableVariable(required=true)
        public Id exclusionId;
    }

    private class RestrictionTemplate {
        public String restrictionType;
        public String restrictionDescription;
        public String enforcedBy;
        public String stopCode;
    }

    private class JunctionTemplate {
        public Id exclusionId;
        public Id restrictionId;
        public Id patronId;
        public String exclusionStatus;
        public String enforcementScope;
        public String stopCode;
        public String name;
    }

    @InvocableMethod(label='Create Restrictions for Patron' description='Bulk-safe processing for Restriction and Exclusion-Restriction junction records from Exclusion inserts')
    public static void process(List<inputWrapper> inputs) {        
        Id restrictionRecordTypeId = Schema.SObjectType.Exl_Restriction__c.getRecordTypeInfosByName().get('Exl Restrictions').getRecordTypeId();
        Id exclusionRestrictionRecordTypeId = Schema.SObjectType.Exl_ExclusionRestrictionJunc__c.getRecordTypeInfosByName().get('Exl Exclusion Restrictions').getRecordTypeId();
        List<Exl_Exclusion__c> exclusionList = new List<Exl_Exclusion__c>();
        Set<Id> patronIds = new Set<Id>();
        Set<String> poeLabels = new Set<String>();

        Set<Id> exclusionIds = new Set<Id>();
        for (inputWrapper input : inputs) {
            if (input != null && input.exclusionId != null) {
                exclusionIds.add(input.exclusionId);
            }
        }

        List<Exl_Exclusion__c> exclusions = [
            SELECT Id, Contact__c, Contact__r.FirstName, Contact__r.LastName, Status__c, Revocation_Date__c, POE_Type__c
            FROM Exl_Exclusion__c WHERE Id IN :exclusionIds ];

        Map<Id, Exl_Exclusion__c> exclusionById = new Map<Id, Exl_Exclusion__c>(exclusions);

        for (Exl_Exclusion__c exclusionRecord : exclusions) {
            exclusionList.add(exclusionRecord);
            patronIds.add(exclusionRecord.Contact__c);
            poeLabels.add(String.valueOf(exclusionRecord.POE_Type__c));
        }

        Map<String, String> poeTypeIdByLabel = getPoeTypeIdByLabel(poeLabels);
        Map<String, List<RestrictionTemplate>> templatesByPoeType = getRestrictionTemplatesByPoeType(new Set<String>(poeTypeIdByLabel.values()));

        Set<String> neededRestrictionTypes = new Set<String>();
        for (List<RestrictionTemplate> templateList : templatesByPoeType.values()) {
            for (RestrictionTemplate templateItem : templateList) {
                neededRestrictionTypes.add(templateItem.restrictionType);
            }
        }

        Map<String, Exl_Restriction__c> restrictionByKey = new Map<String, Exl_Restriction__c>();
        Set<String> existingRestrictionKeys = new Set<String>();

        for (Exl_Restriction__c existingRestriction : [ SELECT Id, Patron__c, Restriction_Type__c, Enforcement_Status__c
                                                        FROM Exl_Restriction__c WHERE Patron__c IN :patronIds
                                                        AND Restriction_Type__c IN :neededRestrictionTypes]) {
            String key = buildRestrictionKey(existingRestriction.Patron__c, existingRestriction.Restriction_Type__c);
            if (!restrictionByKey.containsKey(key)) {
                restrictionByKey.put(key, existingRestriction);
                existingRestrictionKeys.add(key);
            }
        }


        List<Exl_Restriction__c> restrictionsToInsert = new List<Exl_Restriction__c>();
        List<String> insertKeys = new List<String>();
        Map<Id, Exl_Restriction__c> restrictionsToUpdateById = new Map<Id, Exl_Restriction__c>();

        for (Exl_Exclusion__c exclusionRecord : exclusionList) {
            String poeTypeId = poeTypeIdByLabel.get(String.valueOf(exclusionRecord.POE_Type__c));
            if (poeTypeId == null || !templatesByPoeType.containsKey(poeTypeId)) {
                continue;
            }

            for (RestrictionTemplate templateItem : templatesByPoeType.get(poeTypeId)) {
                String key = buildRestrictionKey(exclusionRecord.Contact__c, templateItem.restrictionType);
                Exl_Restriction__c existingOrStagedRestriction = restrictionByKey.get(key);

                if (existingOrStagedRestriction == null) {
                    Exl_Restriction__c newRestriction = new Exl_Restriction__c(
                        Patron__c = exclusionRecord.Contact__c,
                        Restriction_Type__c = templateItem.restrictionType,
                        Enforcement_Description__c = templateItem.restrictionDescription,
                        Enforced_By__c = templateItem.enforcedBy,
                        Enforcement_Status__c = getNewRestrictionStatus(templateItem.restrictionType, PENDING_STATUS)
                    );
                    if (restrictionRecordTypeId != null) {
                        newRestriction.RecordTypeId = restrictionRecordTypeId;
                    }

                    restrictionsToInsert.add(newRestriction);
                    insertKeys.add(key);
                    restrictionByKey.put(key, newRestriction);
                    continue;
                }

                if (existingOrStagedRestriction.Id != null && existingRestrictionKeys.contains(key)) {
                    String targetExistingStatus = getExistingRestrictionStatus(templateItem.restrictionType);
                    if (existingOrStagedRestriction.Enforcement_Status__c != targetExistingStatus && !restrictionsToUpdateById.containsKey(existingOrStagedRestriction.Id)) {
                        if((existingOrStagedRestriction.Restriction_Type__c == 'Access to Digital Channels' || existingOrStagedRestriction.Restriction_Type__c == 'Casino Points' 
                            || existingOrStagedRestriction.Restriction_Type__c == 'Tier Level Lost' || existingOrStagedRestriction.Restriction_Type__c == 'Funds'
                            || existingOrStagedRestriction.Restriction_Type__c == 'Receive Marketing Communications' ) 
                        	&& (existingOrStagedRestriction.Enforcement_Status__c == 'Pending' || existingOrStagedRestriction.Enforcement_Status__c == 'Active' )){
                        	//do nothing		
                        } else {
                        	restrictionsToUpdateById.put( existingOrStagedRestriction.Id, new Exl_Restriction__c( Id = existingOrStagedRestriction.Id, Enforcement_Status__c = targetExistingStatus ) );
                        }
                    }
                }
            }
        }

        if (!restrictionsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(restrictionsToInsert, false);
            for (Integer index = 0; index < insertResults.size(); index++) {
                if (insertResults[index].isSuccess()) {
                    restrictionByKey.put(insertKeys[index], restrictionsToInsert[index]);
                }
            }
        }

        if (!restrictionsToUpdateById.isEmpty()) {
            Database.update(restrictionsToUpdateById.values(), false);
        }

        List<JunctionTemplate> junctionTemplates = new List<JunctionTemplate>();
        Set<Id> neededRestrictionIds = new Set<Id>();

        for (Exl_Exclusion__c exclusionRecord : exclusionList) {
            String poeTypeId = poeTypeIdByLabel.get(String.valueOf(exclusionRecord.POE_Type__c));
            if (poeTypeId == null || !templatesByPoeType.containsKey(poeTypeId)) {
                continue;
            }

            for (RestrictionTemplate templateItem : templatesByPoeType.get(poeTypeId)) {
                String key = buildRestrictionKey(exclusionRecord.Contact__c, templateItem.restrictionType);
                Exl_Restriction__c restrictionRecord = restrictionByKey.get(key);
                if (restrictionRecord == null || restrictionRecord.Id == null) {
                    continue;
                }

                JunctionTemplate junctionTemplate = new JunctionTemplate();
                junctionTemplate.exclusionId = exclusionRecord.Id;
                junctionTemplate.restrictionId = restrictionRecord.Id;
                junctionTemplate.patronId = exclusionRecord.Contact__c;
                junctionTemplate.exclusionStatus = exclusionRecord.Status__c;
                junctionTemplate.enforcementScope = templateItem.restrictionType;
                junctionTemplate.stopCode = templateItem.stopCode;
                junctionTemplate.name = buildJunctionName(exclusionRecord);
                junctionTemplates.add(junctionTemplate);
                neededRestrictionIds.add(restrictionRecord.Id);
            }
        }

        Set<String> existingJunctionKeys = new Set<String>();
        if (!neededRestrictionIds.isEmpty()) {
            for (Exl_ExclusionRestrictionJunc__c existingJunction : [
                        SELECT Id, Exclusion__c, Restriction__c
                        FROM Exl_ExclusionRestrictionJunc__c
                        WHERE Exclusion__c IN :exclusionIds
                        AND Restriction__c IN :neededRestrictionIds ]) {
                existingJunctionKeys.add(buildJunctionKey(existingJunction.Exclusion__c, existingJunction.Restriction__c));
            }
        }

        List<Exl_ExclusionRestrictionJunc__c> junctionsToInsert = new List<Exl_ExclusionRestrictionJunc__c>();
        Set<String> stagedJunctionKeys = new Set<String>();

        for (JunctionTemplate junctionTemplate : junctionTemplates) {
            String junctionKey = buildJunctionKey(junctionTemplate.exclusionId, junctionTemplate.restrictionId);
            if (existingJunctionKeys.contains(junctionKey) || stagedJunctionKeys.contains(junctionKey)) {
                continue;
            }

            Exl_ExclusionRestrictionJunc__c junctionRecord = new Exl_ExclusionRestrictionJunc__c(
                Exclusion__c = junctionTemplate.exclusionId,
                Restriction__c = junctionTemplate.restrictionId,
                Patron_Id__c = junctionTemplate.patronId,
                Stop_Code__c = junctionTemplate.stopCode,
                Name = junctionTemplate.name,
                Exclusion_Status__c = junctionTemplate.exclusionStatus,
                Enforcement_Scope__c = junctionTemplate.enforcementScope
            );
            if (exclusionRestrictionRecordTypeId != null) {
                junctionRecord.RecordTypeId = exclusionRestrictionRecordTypeId;
            }

            junctionsToInsert.add(junctionRecord);
            stagedJunctionKeys.add(junctionKey);
        }

        if (!junctionsToInsert.isEmpty()) {
            Database.insert(junctionsToInsert, false);
        }

    }

    private static Map<String, String> getPoeTypeIdByLabel(Set<String> poeLabels) {
        Map<String, String> result = new Map<String, String>();
        if (poeLabels.isEmpty()) {
            return result;
        }

        for (Exl_POE_Type__mdt poeType : [ SELECT Id, Label FROM Exl_POE_Type__mdt WHERE Label IN :poeLabels ]) {
            result.put(poeType.Label, String.valueOf(poeType.Id));
        }
        return result;
    }

    private static Map<String, List<RestrictionTemplate>> getRestrictionTemplatesByPoeType(Set<String> poeTypeIds) {
        Map<String, List<RestrictionTemplate>> templatesByPoeType = new Map<String, List<RestrictionTemplate>>();
        if (poeTypeIds.isEmpty()) {
            return templatesByPoeType;
        }

        for (Exl_POE_Restriction_Junction__mdt junctionMdt : [ SELECT POE_Type__c, Stop_Code__c, Stop_Code_Label__c, 
                                                                       Restriction_Category__r.MasterLabel,
                                                                       Restriction_Category__r.Restriction_Description__c,
                                                                       Restriction_Category__r.Enforcement_System__c
                                                                FROM Exl_POE_Restriction_Junction__mdt
                                                                WHERE POE_Type__c IN :poeTypeIds
                                                                AND Restriction_Category__c != null
                                                                ORDER BY POE_Type__c ASC ]) {
            RestrictionTemplate templateItem = new RestrictionTemplate();
            templateItem.restrictionType = junctionMdt.Restriction_Category__r.MasterLabel;
            templateItem.restrictionDescription = junctionMdt.Restriction_Category__r.Restriction_Description__c;
            templateItem.enforcedBy = junctionMdt.Restriction_Category__r.Enforcement_System__c;
            templateItem.stopCode = junctionMdt.Stop_Code_Label__c;

            String poeTypeId = String.valueOf(junctionMdt.POE_Type__c);
            if (!templatesByPoeType.containsKey(poeTypeId)) {
                templatesByPoeType.put(poeTypeId, new List<RestrictionTemplate>());
            }
            templatesByPoeType.get(poeTypeId).add(templateItem);
        }

        return templatesByPoeType;
    }

    private static String getNewRestrictionStatus(String restrictionType, String defaultStatus) {
        return REQUESTED_RESTRICTION_TYPES.contains(restrictionType) ? REQUESTED_STATUS : defaultStatus;
    }

    private static String getExistingRestrictionStatus(String restrictionType) {
        return REQUESTED_RESTRICTION_TYPES.contains(restrictionType) ? REQUESTED_STATUS : PENDING_STATUS;
    }

    private static String buildRestrictionKey(Id patronId, String restrictionType) {
        return String.valueOf(patronId) + '|' + restrictionType;
    }

    private static String buildJunctionKey(Id exclusionId, Id restrictionId) {
        return String.valueOf(exclusionId) + '|' + String.valueOf(restrictionId);
    }

    private static String buildJunctionName(Exl_Exclusion__c exclusionRecord) {
        String firstName = exclusionRecord.Contact__r != null && exclusionRecord.Contact__r.FirstName != null ? exclusionRecord.Contact__r.FirstName : '';
        String lastName = exclusionRecord.Contact__r != null && exclusionRecord.Contact__r.LastName != null ? exclusionRecord.Contact__r.LastName : '';

        String fullName = (firstName + ' ' + lastName).trim();
        if (String.isBlank(fullName)) {
            fullName = 'Unknown Patron';
        }

        return fullName + ' - ' + String.valueOf(exclusionRecord.POE_Type__c);
    }

}