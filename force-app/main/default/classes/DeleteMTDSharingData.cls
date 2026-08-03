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
public class DeleteMTDSharingData implements Database.Batchable<sObject>{
    public String query = '';
    public DeleteMTDSharingData() {
        query += ' SELECT Id FROM MTDYTD_Trend_Data__Share';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<MTDYTD_Trend_Data__Share> scope){
        try{
            delete scope;
        }
        catch(Exception e){
            system.debug('Cause' + e.getCause() );
            system.debug('Message ' + e.getMessage());
            
        }
    }

    public void finish(Database.BatchableContext BC){
        Database.executeBatch(new ShareMTDRecordsWithHostsBatchProcessor());
    }
}