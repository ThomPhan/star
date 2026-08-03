global class ErrorLogDeleteBatch implements Schedulable, Database.batchable<sObject>{ 
    
    global Database.QueryLocator start(Database.BatchableContext info){ 
        
        Error_Log_Delete_Batch_Setting__mdt errLogBatchSetting = Error_Log_Delete_Batch_Setting__mdt.getInstance('Error_Log_Setting');
        Integer numOfDays = Integer.valueOf(errLogBatchSetting.Last_N_Days__c);
        
        String query = 'SELECT Id FROM ErrorLog__c WHERE CreatedDate < LAST_N_DAYS:' + numOfDays + ' ORDER BY CreatedDate DESC';
        System.debug(query);
        return Database.getQueryLocator(query); 
    }     
    
    global void execute(Database.BatchableContext info, List<sObject> errorLogList){
        
        delete errorLogList;
    }     
    
    global void finish(Database.BatchableContext info){     
    } 
    
    global void execute(SchedulableContext ctx) {
        
        ErrorLogDeleteBatch errLogBatch = new ErrorLogDeleteBatch();
        Database.executeBatch(errLogBatch);
    }
}