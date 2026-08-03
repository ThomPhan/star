@RestResource(urlMapping='/GetMTDYRecords/*')
global with sharing class RestTest 
{
    @HttpGet
    global static List<MTDYTD_Trend_Data__c> getMTDYList()
    {
        List<MTDYTD_Trend_Data__c> MTDYList = new List<MTDYTD_Trend_Data__c>([Select Id From MTDYTD_Trend_Data__c]);
        System.debug('MTDYLIST : ' +MTDYList);
        MTDYBulkDeleteRecords.clearAllMTDYRecords();
        return MTDYList;
    }
}