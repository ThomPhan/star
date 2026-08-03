/**
* @File Name          : VIPBookingMigrationBatch
* @Description        : Migrate VIP Booking records to Service records
* @Author             : JPalmero
* @Group              : Simplus
* @Last Modified By   : JPalmero
* @Last Modified On   : 17/01/23
**/
global class VIPBookingMigrationBatch implements Database.Batchable<sObject>{
    List<Service__c> updateServiceRecordList = new List<Service__c>();
    List<Id> vipBookingIdList = new List<Id>();
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Cost_Centre__c, VIP_Booking__c, Property__c, VIP_Booking__r.Property__c, 
                                         VIP_Booking__r.Cost_Centre__c, VIP_Booking__r.Contact__c, Contact__c FROM Service__c
                                         WHERE VIP_Booking__c != NULL]);
    }
    global void execute(Database.BatchableContext BC, List<Service__c> serviceList){
        for(Service__c serviceObj : serviceList){
            vipBookingIdList.add(serviceObj.VIP_Booking__c);
            serviceObj.Cost_Centre__c = serviceObj.VIP_Booking__r.Cost_Centre__c;
            serviceObj.Property__c = serviceObj.VIP_Booking__r.Property__c;
            serviceObj.Contact__c = serviceObj.VIP_Booking__r.Contact__c;
            if(serviceObj.VIP_Booking__r.Cost_Centre__c != NULL && serviceObj.VIP_Booking__r.Cost_Centre__c.contains('NSW & QLD')){
               serviceObj.Cost_Centre__c = 'NSW & QLD  – 1111';
                System.debug('@@@serviceObj.Cost_Centre__c ' + serviceObj.Cost_Centre__c);
            }
            updateServiceRecordList.add(serviceObj);
        }
        System.debug('@@@updateServiceRecordList ' + updateServiceRecordList);
        Database.update(updateServiceRecordList, true);
        
    }
    global void finish(Database.BatchableContext BC){
        
    }

}