/**
* @File Name          : CampaignDeleteBatch.apxc
* @Description        : Delete Campaign Members older than 365 days
* @Group              : Simplus
**/
global class CampaignDeleteBatch implements Database.Batchable<sObject>, Schedulable {

    Integer numOfDays = 0;
    CampaignDeleteBatchSetting__c campDeleteSetting = CampaignDeleteBatchSetting__c.getOrgDefaults();
    Set<Id> adHocId = new Set<Id>();

    global CampaignDeleteBatch(){}

    global CampaignDeleteBatch(Set<Id> adHocId){

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

            query = 'SELECT Id, CampaignId FROM CampaignMember WHERE Campaign.RecordType.DeveloperName = \'Offer\' AND Campaign.CreatedDate <= ' + dt.format('yyyy-MM-dd', 'Australia/Sydney') + 'T00:00:00Z';
        }
        else{

            query = 'SELECT Id, CampaignId FROM CampaignMember WHERE Campaign.RecordType.DeveloperName = \'Offer\' AND Campaign.Id IN: adHocId';
        }

        System.debug('Query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<CampaignMember> campaignMemberList){

        try{
        
            //Delete Campaign along with Campaign Member
            if(!campaignMemberList.isEmpty()){
                delete campaignMemberList;
            }
        }
        catch(Exception e){
            ErrorLogger.createLog('CampaignDeleteBatch', 'execute', e, '', 'Apex Class');
        }
    }

    global void finish(Database.BatchableContext BC){
        
        if(adHocId.isEmpty()){

            CampaignDeleteBatchParent cdbp = new CampaignDeleteBatchParent();
            Database.executeBatch(cdbp, 2000);
        }
        else{
            
            CampaignDeleteBatchParent cdbp = new CampaignDeleteBatchParent(adHocId);
            Database.executeBatch(cdbp, 2000);
        }
    }

    //Schedule this Batch Apex Class
    global void execute(SchedulableContext ctx){
        CampaignDeleteBatch cbj = new CampaignDeleteBatch();
        Database.executeBatch(cbj, 2000);
    }
}