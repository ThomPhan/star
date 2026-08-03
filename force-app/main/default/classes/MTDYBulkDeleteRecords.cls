public class MTDYBulkDeleteRecords {
    
    @future (callout=true)
    static public  void clearAllMTDYRecords()
    {
         System.debug('Inside the ClearAllMTDY Method');
        List<MTDYTD_Trend_Data__c> MTDYList = new List<MTDYTD_Trend_Data__c>([Select Id From MTDYTD_Trend_Data__c Limit 49000]);
        If(!MTDYList.isEmpty())
        {
            Delete MTDYList;
        } 
    }
}