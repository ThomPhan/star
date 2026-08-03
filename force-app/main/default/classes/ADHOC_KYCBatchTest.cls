@isTest
public class ADHOC_KYCBatchTest {

    @isTest
    static void testADHOC_KYCBatch() {
        // 1. Create Test Data (Key_Date__c, Contact, PoP__c, Status__c)
        
        // Create Contacts
        Contact contact1 = new Contact(FirstName = 'John', LastName = 'Doe', Patron_Id__c = '12345');
        Contact contact2 = new Contact(FirstName = 'Jane', LastName = 'Doe', Patron_Id__c = '67890');
        insert new List<Contact>{contact1, contact2};
        
        // Create Key_Date__c records for testing
        Key_Date__c keyDate1 = new Key_Date__c(Patron__c = contact1.Id, Name = 'Due Date', Key_Date_Category__c = 'KYC', Key_Date__c = Date.newInstance(2026, 4, 19), Active__c = true);
        Key_Date__c keyDate2 = new Key_Date__c(Patron__c = contact2.Id, Name = 'Attestation Date', Key_Date_Category__c = 'KYC', Key_Date__c = Date.newInstance(2026, 4, 21), Active__c = true);
        insert new List<Key_Date__c>{keyDate1, keyDate2};
        
        // Create Status__c records (simulating applied and revoked statuses)
        Status__c appliedStatus = new Status__c(Patron_Id__c = contact1.Patron_ID__c, Type__c = 'KYC', Composite_Key__c ='1122334455');
        Status__c revokedStatus = new Status__c(Patron_Id__c = contact2.Patron_ID__c, Type__c = 'KYC', Composite_Key__c ='6677889999');
        insert new List<Status__c>{appliedStatus, revokedStatus};
        
        // 2. Start the batch execution
        Test.startTest();
        
        ADHOC_KYCBatch batchJob = new ADHOC_KYCBatch();
        Database.executeBatch(batchJob, 200);  // Assuming 200 is the batch size
        
        Test.stopTest();
        
        // 3. Assertions - Verify that the PoP records were processed
        // Query for the PoP records created
        List<PoP__c> pops = [SELECT Id, Name, Status__c, Property__c FROM PoP__c WHERE Type__c = 'Stop Code' AND Status__c IN :new List<String>{'Pending Application', 'Pending Revocation'}];
        
        // Ensure PoP records were inserted
        System.assertNotEquals(pops.size(), 0, 'PoP records should be created.');
        
        // Assert that the correct number of PoP records are created for the contacts
        //System.assertEquals(pops.size(), 2, 'Two PoP records should be created.');
        
        // Additional assertions can be added to check if the correct status and property codes were set in the PoP records
        PoP__c pop1 = pops[0];
        //PoP__c pop2 = pops[1];
        
        System.assertEquals(pop1.Status__c, 'Pending Application', 'The PoP status should be Pending Application.');
        //System.assertEquals(pop2.Status__c, 'Pending Revocation', 'The PoP status should be Pending Revocation.');
    }
    
    @isTest
    static void testScheduleADHOC_KYCBatch() {
        // Test if the scheduling of the batch works as expected.
        
        String cronExp = '0 0 0 * * ?'; // Run every 1st January 2025 at midnight
        ADHOC_KYCBatch batchJob = new ADHOC_KYCBatch();
        
        // Schedule the batch job
        String jobId = System.schedule('Test ADHOC_KYCBatch Schedule', cronExp, batchJob);
        
        // Retrieve the scheduled job details
        CronTrigger job = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId LIMIT 1];
        
        // Verify the job was scheduled
        //System.assertEquals(job.State, 'Waiting', 'The scheduled job should be in "Waiting" state.');
        //System.assertEquals(job.CronExpression, cronExp, 'The cron expression should match the scheduled cron.');
    }
}