@isTest
public class Update365CheckboxBatchTest {
    static testmethod void testBatchClass(){
        Contact testContact = TestDataFactory.createSingleContact('Test Class');
        Date dateToday = System.today();
        List<Trip__c> tripList = new List<Trip__c>();
        
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = FALSE;
        
        tripList.add(firstTrip);
        
        Trip__c secondTrip = new Trip__c();
        secondTrip.Contact__c = testContact.Id;
        secondTrip.Entry_State__c = 'QLD';
        secondTrip.Entry_Date__c = dateToday;
        secondTrip.Exit_Date__c = secondTrip.Entry_Date__c.addDays(14);
        secondTrip.Cancelled__c = FALSE;
        secondTrip.is_within_365_days__c = TRUE;
        
        tripList.add(secondTrip);
        
        INSERT tripList;
        
        test.startTest();
        Update365CheckboxBatch myBatchObject = new Update365CheckboxBatch(); 
        Id batchId = Database.executeBatch(myBatchObject);
        test.stopTest();
    }

    static testmethod void testBatchClass2(){

        Test.startTest();
        String CRON_EXP = '0 6 * * * ?';
        String jobId = System.schedule('Test Sched', CRON_EXP, new ScheduleTripsUpdate());
        Test.stopTest();
    }
}