/**
* @File Name          : SOWBatchJob1700.apxc
* @Description        : Batch Job that updates 50 Contact records every 3 mins (1700 records)
* @Author             : Gil Panican
* @Group              : Simplus
* @Last Modified By   : Gil Panican
* @Last Modified On   : 26/09/2022
**/
global class SOWBatchJob1700 implements Database.Batchable<sObject>,Schedulable{
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Name, Is_updated__c FROM SOW_Id__c WHERE Is_updated__c = false LIMIT 50';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SOW_Id__c> sowIdList){
        System.debug('***Batch Started***');
        System.debug('Number of Records included: ' + sowIdList.size());
        
        Set<String> patronIdSet = new Set<String>();
        for (SOW_Id__c sowId : sowIdList){
            patronIdSet.add(sowId.Name);
            sowId.Is_updated__c = true;
        }
        List<Contact> contList = [SELECT Id, Bulk_Update_for_Data_Fix__c FROM Contact WHERE Patron_ID__c in :patronIdSet];
        System.debug('ContLIst: ' + contList);
        for (Contact contRec : contList){
            contRec.Bulk_Update_for_Data_Fix__c = true;
        }
        Database.update(contList, false);
        Database.update(sowIdList, false);
        
        
        
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('***Batch Finished***');
    }
    
    global void execute(SchedulableContext sc) {
        SOWBatchJob1700 b = new SOWBatchJob1700();
        Database.executebatch(b);
    }
}