/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-02-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-02-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class ShareMTDRecordsWithHostsBatchProcessor implements Database.Batchable<sObject>{
    public String query ='';
    public ShareMTDRecordsWithHostsBatchProcessor() {
        query += 'SELECT Id,BatchErrorMessage__c,Host_Brisbane__c,Host_GC__c,Host_International__c,Host_Sydney__c FROM MTDYTD_Trend_Data__c';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, list<MTDYTD_Trend_Data__c> scope){
        List<MTDYTD_Trend_Data__Share> sharingRecList = new List<MTDYTD_Trend_Data__Share>();
        Map<Id, Set<Id>> mtdRecordToUserMap = new Map<Id,Set<Id>>();

       
        for(MTDYTD_Trend_Data__c trendData : scope){
            Set<Id> userIdsSet = new Set<Id>();
            if( !userIdsSet.contains(trendData.Host_Brisbane__c) && !String.isEmpty(trendData.Host_Brisbane__c) ){
                userIdsSet.add(trendData.Host_Brisbane__c);
            }
            if( !userIdsSet.contains(trendData.Host_GC__c) && !String.isEmpty(trendData.Host_GC__c)  ){
                userIdsSet.add(trendData.Host_GC__c);
            }
            if( !userIdsSet.contains(trendData.Host_International__c) && !String.isEmpty(trendData.Host_International__c) ){
                userIdsSet.add(trendData.Host_International__c);
            }
            if( !userIdsSet.contains(trendData.Host_Sydney__c) && !String.isEmpty(trendData.Host_Sydney__c)  ){
                userIdsSet.add(trendData.Host_Sydney__c);
            }
            mtdRecordToUserMap.put(trendData.Id,userIdsSet);
        }
        for(Id mtdRecordId : mtdRecordToUserMap.keySet()){
            for(Id userId : mtdRecordToUserMap.get(mtdRecordId)){
                sharingRecList.add( new MTDYTD_Trend_Data__Share(
                                AccessLevel = 'Read',
                                ParentId=mtdRecordId,
                                RowCause=Schema.MTDYTD_Trend_Data__Share.RowCause.Manual,
                                UserOrGroupId= userId
                                ) );

            }
            
        }

        List<Database.SaveResult> sharingRecs = Database.insert(sharingRecList,false);

        for(Database.SaveResult sr : sharingRecs){
            if(!sr.isSuccess()){
                
                // Get the first save result error.
                Database.Error err = sr.getErrors()[0];
                system.debug('err record ' + sr.getId() +  ' ' + err.getMessage() + ' ' + err.getFields());
            }
        }   
    }

    public void finish(Database.BatchableContext BC){
       system.debug('ShareMTDRecordsWithHostsBatchProcessor finished');
    }
}