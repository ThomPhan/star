/**
* @File Name          : CampaignDeleteBatch.apxc
* @Description        : Delete Campaign Members older than 365 days
* @Group              : Simplus
**/
global class CampaignDeleteBatchParent implements Database.Batchable<sObject> {

    Integer numOfDays = 0;
    CampaignDeleteBatchSetting__c campDeleteSetting = CampaignDeleteBatchSetting__c.getOrgDefaults();
    Set<Id> adHocId = new Set<Id>();

    global CampaignDeleteBatchParent(){}

    global CampaignDeleteBatchParent(Set<Id> adHocId){

        this.adHocId.addAll(adHocId);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        if(campDeleteSetting.Num_of_Days__c == null){
            numOfDays = 365;
        }
        else{
            numOfDays = (Integer)campDeleteSetting.Num_of_Days__c;
        }
        DateTime dt = Date.today();
        dt = dt.addDays(-numOfDays);
        System.debug('NumOfDays: ' + numOfDays);
        String query;

        //If adHocId == null, use default query else, use adHocId as filter for Campaign Query
        if(adHocId.isEmpty()){

            query = 'SELECT Id FROM Campaign WHERE RecordType.DeveloperName = \'Offer\' AND CreatedDate <= ' + dt.format('yyyy-MM-dd', 'Australia/Sydney') + 'T00:00:00Z';
        }
        else{

            query = 'SELECT Id FROM Campaign WHERE RecordType.DeveloperName = \'Offer\' AND Id IN: adHocId';
        }

        System.debug('Query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Campaign> campaignList){

        try{
            
            if(!campaignList.isEmpty()){

                delete campaignList;
            }
        }
        catch(Exception e){
            ErrorLogger.createLog('CampaignDeleteBatchParent', 'execute', e, '', 'Apex Class');
        }
    }

    global void finish(Database.BatchableContext BC){
        
        //No finish method
    }
}