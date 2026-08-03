global class DeleteAllStatusRecsBatch implements Database.batchable<sObject>{ 
    global Database.QueryLocator start(Database.BatchableContext info){ 
        String query = 'SELECT Id FROM Status__c';
        return Database.getQueryLocator(query); 
    }     
    global void execute(Database.BatchableContext info, List<sObject> statusList){
        
        delete statusList;
    }     
    public void finish(Database.BatchableContext info){     
    } 
 }