global class Update365CheckboxBatch implements Database.batchable<sObject>{ 
   global Database.QueryLocator start(Database.BatchableContext info){ 
       String query = 'SELECT Id, is_within_365_days__c, Entry_Date__c, Entry_State__c FROM Trip__c WHERE is_within_365_days__c = TRUE';
       return Database.getQueryLocator(query); 
   }     
   global void execute(Database.BatchableContext info, List<Trip__c> tripList){
       List<Trip__c> newTripList = new List<Trip__c>();
       Date dateToday = Date.today();
       Integer tripDuration;
       for(Trip__c tripObj : tripList){
           tripDuration = tripObj.Entry_Date__c.daysBetween(dateToday);
           if(tripDuration>365){
               tripObj.is_within_365_days__c = FALSE;
               newTripList.add(tripObj);
           }
       }
       
       if(!newTripList.isEmpty()){
           Database.update(newTripList, true);
       }
   }     
   public void finish(Database.BatchableContext info){     
   } 
}