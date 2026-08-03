@RestResource(urlMapping='/MTDYTDDeleteRecords/*')
global with sharing class MTDYTDDeleteRecords 
{
@HttpDelete 
    global static void doDelete()
     {
       List<MTDYTD_Trend_Data__c> customObj = [select Id FROM MTDYTD_Trend_Data__c LIMIT 50];
       if(!customObj.isEmpty())
         delete customObj;
     }
}