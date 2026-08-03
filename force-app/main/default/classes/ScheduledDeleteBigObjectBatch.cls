/**
* @File Name          : ScheduledDeleteBigObjectBatch
* @Description        : Deletes old big object records depending on the Custom Setting
* @Group              : Simplus
**/
global class ScheduledDeleteBigObjectBatch implements Database.Batchable<sObject>{
    @TestVisible List<ContactLightningURIEvent__b> contactLightningURIListTest;
    @TestVisible private static Boolean runOriginalConstructor = true;
    @TestVisible global ScheduledDeleteBigObjectBatch(List<ContactLightningURIEvent__b> lightningURIList){
        contactLightningURIListTest = lightningURIList;
    }
    
    private String dynamicDateLiteral;
    
    public ScheduledDeleteBigObjectBatch() {
        BigObjectCriteria__c bigObjectCriteria = BigObjectCriteria__c.getOrgDefaults();
        this.dynamicDateLiteral = 'LAST_N_DAYS:' + String.valueOf(Integer.valueOf(bigObjectCriteria.Event_Date__c));
    }

    global Iterable<sObject> start(Database.BatchableContext bc) {

        if(runOriginalConstructor){
            String queryString = 'Select ID, EventDate__c From ContactLightningURIEvent__b WHERE (EventDate__c < ' + this.dynamicDateLiteral + ') LIMIT 50000';
            return Database.query(queryString);
        }
        else{
            return contactLightningURIListTest;
        }
    }

    global void execute(Database.BatchableContext BC, List<ContactLightningURIEvent__b> bigObjectList){
        Integer daysPast;
        Date bigObjectDate;
        
        List<ContactLightningURIEvent__b> bigObjectToDeleteList = new List<ContactLightningURIEvent__b>();
        
        for(ContactLightningURIEvent__b bigObjectBuff : bigObjectList){
            bigObjectToDeleteList.add(bigObjectBuff);
        }

        try {
            if(!Test.isRunningTest()){
                Database.deleteImmediate(bigObjectToDeleteList);
            }
        } catch (Exception e) {
            ErrorLogger.createLog('ScheduledDeleteBigObjectBatch', 'ScheduledDeleteBigObjectBatch', e, null, 'Apex Class'); 
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }
}