@RestResource(urlMapping='/MTDYTDGetRecordCount/*')
global with sharing class MTDYTDGetRecordCount 
{
  @HttpGet 
  global static Integer GetRecordCount()
  {
    return [select count() FROM MTDYTD_Trend_Data__c];
  }
}