public With Sharing class KeyDateTriggerHandler extends TriggerHandlerBase {
    private static Boolean hasRun = false;
    
    public KeyDateTriggerHandler(String triggerName) {
        super(triggerName);
    }
    // Before Insert
    public override void beforeInsert(List<SObject> newRecords) {
        processKeyDateBeforeInsertOrUpdate(newRecords, null);
    }
    // Before Update
    public override void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
        processKeyDateBeforeInsertOrUpdate(newRecords, oldRecordMap);
    }
    // After Insert
    public override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        processKeyDateAfterInsertOrUpdate(newRecords, null);
    }
    // After Update
    public override void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
        processKeyDateAfterInsertOrUpdate(newRecords, oldRecordMap);
    }
    
    
    
    // Centralized method to handle both afterInsert and afterUpdate logic
    private void processKeyDateAfterInsertOrUpdate(List<SObject> newRecords, Map<ID, SObject> oldRecordMap) {
        Set<Id> conSFIdsDueDateCalReq = new Set<Id>();
        
        Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap = KYCUtility.getPatronIdsForChangedKeyDateAttestations(newRecords, oldRecordMap);
        
        for (String key : patronExtIdToKeyDateAttestMap.keySet()) {
            conSFIdsDueDateCalReq.add(patronExtIdToKeyDateAttestMap.get(key).Patron__c);
        }
        
        if (!conSFIdsDueDateCalReq.isEmpty()) {
            KYCUtility.processContactsForDueDates(conSFIdsDueDateCalReq, patronExtIdToKeyDateAttestMap);
        }
        
        //Clean the attestation records for API Operations.
        KYCUtility.cleanOutdatedKeyDates(newRecords, oldRecordMap);
        
        //List<Key_Date__c> keyDates = [select id, Patron__c from Key_Date__c where id ='a059r00000J4hA7AAJ'];
        KYCUtility.processKeyDatesForAttestation(patronExtIdToKeyDateAttestMap.values());
        
        
    }
    
    // Main method to handle both beforeInsert and beforeUpdate logic
    private void processKeyDateBeforeInsertOrUpdate(List<SObject> newRecords, Map<ID, SObject> oldRecordMap) {
        // Prepare necessary data
        Map<Id, Contact> contactIdToContactMap =KYCUtility.prepareContactData(newRecords);
        Map<Id, Integer> contactDueDateCount = KeyDateSelector.getContactDueDateCount(contactIdToContactMap.keySet(), ConstantHelper.STRING_KEYDATE_DUEDATE);
        Map<Id, Integer> contactOverrideDueDateCount = KeyDateSelector.getContactDueDateCount(contactIdToContactMap.keySet(), ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE);
        
        // Process each Key_Date__c record
        processKeyDateRecords((List<Key_Date__c>) newRecords, oldRecordMap, contactIdToContactMap, contactDueDateCount, contactOverrideDueDateCount);
    }
    
    // Helper method to process each Key_Date__c record
    private void processKeyDateRecords(
        List<Key_Date__c> newKeyDates,
        Map<ID, SObject> oldRecordMap,
        Map<Id, Contact> contactIdToContactMap,
        Map<Id, Integer> contactDueDateCount,
        Map<Id, Integer> contactOverrideDueDateCount
    ) {
        for (Key_Date__c keyDateRecord : newKeyDates) {
            Key_Date__c oldKeyDate = (keyDateRecord.Id != null && oldRecordMap.containsKey(keyDateRecord.Id)) 
                ? (Key_Date__c) oldRecordMap.get(keyDateRecord.Id) 
                : null;
            
            Boolean keyDateNameUpdatedValidation = oldKeyDate != null 
                ? (oldKeyDate.Name != keyDateRecord.Name 
                   && (keyDateRecord.Name == ConstantHelper.STRING_KEYDATE_DUEDATE 
                       || keyDateRecord.Name == ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE)) 
                : true;
            
            if (keyDateRecord.Patron__c != null && keyDateRecord.Active__c && keyDateRecord.Key_Date_Category__c == ConstantHelper.STRING_KYC && keyDateNameUpdatedValidation) {
                Integer existingDueDateCount = contactDueDateCount.get(keyDateRecord.Patron__c);
                if (keyDateRecord.Name == ConstantHelper.STRING_KEYDATE_DUEDATE && existingDueDateCount != null && existingDueDateCount >= 1) {
                    keyDateRecord.addError('Only one active DueDate is allowed per Patron.');
                }

                /*Integer existingOverrideCount = contactOverrideDueDateCount.get(keyDateRecord.Patron__c);
                if (keyDateRecord.Name == ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE && existingOverrideCount != null && existingOverrideCount >= 1) {
                    keyDateRecord.addError('Only one active override DueDate is allowed per Patron.');
                }*/
            }
            
            // Logic for API User Attestation Record Upsertion.
            if (keyDateRecord.Key_Date_Time__c != null && keyDateRecord.Name == ConstantHelper.STRING_KEYDATE_ATTESTATION && keyDateRecord.Patron__c != null && FeatureManagement.checkPermission(ConstantHelper.STRING_SKIP_VALIDATION_CP)) {
                KYCUtility.processKeyDateForTimezoneAdjustment(keyDateRecord, oldRecordMap, contactIdToContactMap);
            } else {
                System.debug('Key_Date_Time__c is null, skipping date calculation.');
            }
        }
    }
    
    
    
    public class DueDateCalculationException extends Exception {}
    
}