/**
* @File Name          : LoyaltyLastSuccessfulUpdateBatch.apxc
* @Description        : Batch Job that runs everyday to update 'Last Succesful Update' field of up to 70000 Loyalty records
* @Author             : Gil Panican
* @Group              : Simplus
* @Last Modified By   : Gil Panican
* @Last Modified On   : 03/08/22
**/
global class LoyaltyLastSuccessfulUpdateBatch implements Database.Batchable<sObject>,Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT External_ID__c,last_successful_update__C,CasinoBalance__c,CompBalance__c,Tier_Balance__c, LastModifiedDate FROM Loyalty__c WHERE (CasinoBalance__c <= 0 OR CasinoBalance__c = NULL) AND (CompBalance__c <= 0 OR CompBalance__c = NULL) and (Tier_Balance__c <= 0 OR Tier_Balance__c = NULL) and last_successful_update__C = null LIMIT 70000';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Loyalty__c> loyaltyList){
        System.debug('***Batch Started***');
        for (Loyalty__c loyaltyRec : loyaltyList){
            loyaltyRec.Last_Successful_Update__c = loyaltyRec.LastModifiedDate.format('dd/MM/yyyy, hh:mm a', + 'Australia/Sydney');
        }
        update loyaltyList;
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('***Batch Finished***');
    }
    
    global void execute(SchedulableContext sc) {
        LoyaltyLastSuccessfulUpdateBatch b = new LoyaltyLastSuccessfulUpdateBatch();
        Database.executebatch(b);
    }
}