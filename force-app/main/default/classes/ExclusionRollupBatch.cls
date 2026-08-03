global class ExclusionRollupBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RecalculateDLRS__c, Contact__c, Start_Date__c
            FROM Exl_Exclusion__c 
            WHERE Start_Date__c >= LAST_N_DAYS:39 OR RecalculateDLRS__c = true
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<exl_exclusion__c> scope) {
        List<Internal_Event_Log__e> eventsToPublish = new List<Internal_Event_Log__e>();
        
        Set<Id> contactIds = new Set<Id>();
        List<exl_exclusion__c> exlToBeUpdated = new List<exl_exclusion__c>();
        
        for(exl_exclusion__c rec : scope) {
            contactIds.add(rec.Contact__c);
            if(rec.RecalculateDLRS__c == true){
                rec.RecalculateDLRS__c = false;
            	exlToBeUpdated.add(rec);
            }
        }
        if (contactIds != null && !contactIds.isEmpty()) {
            for(Id conId : contactIds){
                eventsToPublish.add(new Internal_Event_Log__e(
                    Record_Id__c = conId,
                    Source__c = 'ExclusionRollupBatch'
                ));
            }
        }
        
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
        }
        
        if(!exlToBeUpdated.isEmpty()){
            update exlToBeUpdated;
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
    }
}