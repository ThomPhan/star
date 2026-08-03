/**
 * @description       : Trigger handler class for ContentDocumentLink
 * @author            : Simplus
 * @group             : Simplus
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   11-09-2023   Simplus                      Initial Version
 */
public class  ContentDocumentLinkTriggerHandler extends TriggerHandlerBase { //extending the trigger framework
    static final String APEXCLASSNAME = 'ContentDocumentLinkTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';

    //new method which is required when we extend the TriggerHandlerBase class
    public ContentDocumentLinkTriggerHandler (String triggerName) {
      super(triggerName);
    }

    //public static void handleAfterInsert(List<ContentDocumentLink> contDocLinkList){
    public override void afterInsert(List<SObject> tempContDocLinkList, Map<Id, SObject> newContDocMap){
        List<ContentDocumentLink> contDocLinkList = (List<ContentDocumentLink>)tempContDocLinkList;
        Map<Id, Contact> contMap = new Map<Id, Contact>();
        Schema.SObjectType contSobjType = Schema.Contact.SObjectType;
        Schema.SObjectType exclusionType = Exl_Exclusion__c.SObjectType;
        Set<Id> exclusionIds = new Set<Id>();
        
        for (ContentDocumentLink cDocLink : contDocLinkList) {
            if (cDocLink.LinkedEntityId != null) {
                Schema.SObjectType linkedType = cDocLink.LinkedEntityId.getSObjectType();
                System.debug('LinkedEntityId: ' + cDocLink.LinkedEntityId + ', Type: ' + linkedType);
                
                if (linkedType == contSobjType) {
                    if (!contMap.containsKey(cDocLink.LinkedEntityId)) {
                        Contact c = new Contact();
                        c.Id = cDocLink.LinkedEntityId;
                        c.SoW_Update_DateTime__c = DateTime.now();
                        contMap.put(c.Id, c);
                    }
                } else if (linkedType == exclusionType) {
                    exclusionIds.add(cDocLink.LinkedEntityId);
                }
            }
        }
        
        if (!contMap.isEmpty()) {
            try {
                update contMap.values();
            } catch (Exception e) {
                System.debug('Error updating Contacts: ' + e.getMessage());
            }
        }
        
        if (!exclusionIds.isEmpty()) {
            try {
                system.debug('Call:: WOLIStatusUpdater.updateWOLIStatusBasedOnDocuments:: '+exclusionIds);
                WOLIStatusUpdater.updateWOLIStatusBasedOnDocuments(exclusionIds);
            } catch (Exception e) {
                System.debug('Error in WOLIStatusUpdater: ' + e.getMessage());
            }
        }
    }

    public override void beforeInsert(List<SObject> tempContDocLinkList){

        List<ContentDocumentLink> contDocLinkList = (List<ContentDocumentLink>)tempContDocLinkList;
        System.debug('Goes here beforeInsert CONT DOC LINK');
        Set<Id> contIdSet = new Set<Id>();
        Schema.SObjectType contSobjType = Schema.Contact.getSObjectType();

        for(ContentDocumentLink cDocLink : contDocLinkList){

            if(cDocLink.LinkedEntityId.getSObjectType() == contSobjType){

                contIdSet.add(cDocLink.LinkedEntityId);
            }
        }

        if(!contIdSet.isempty()){
            
            System.debug('Goes here');
            Map<Id, Contact> contMap = new Map<Id, Contact>([SELECT Id, Patron_Status__c FROM Contact WHERE Id IN: contIdSet]);

            if(!contMap.isEmpty()){

                for(ContentDocumentLink contDocLink : contDocLinkList){

                    if(contMap.containsKey(contDocLink.LinkedEntityId)){
                        
                        if(contMap.get(contDocLink.LinkedEntityId).Patron_Status__c == 'Duplicate'){
                            contDocLink.addError('Attachment could not be uploaded as Customer Status is Duplicate');
                        }
                    }
                }
            }
        }
    }
}