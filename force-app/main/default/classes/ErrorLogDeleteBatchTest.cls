@isTest
public class ErrorLogDeleteBatchTest {

    @TestSetup
    private static void testDataSetup(){

        ErrorLog__c err = new ErrorLog__c();
        err.Apex_Class__c = 'Test';
        insert err;

        Test.setCreatedDate(err.Id, Date.valueOf('2025-01-01'));
    }
    
    @isTest
    static void testErrorLogBatch_Schedule() {
        
        test.startTest();
        ErrorLogDeleteBatch errLogSched = new ErrorLogDeleteBatch ();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, errLogSched);
        test.stopTest();
    }
}