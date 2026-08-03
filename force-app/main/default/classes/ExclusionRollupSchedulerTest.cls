@isTest
private class ExclusionRollupSchedulerTest {

    private static List<exl_exclusion__c> setupTestData() {
        List<exl_exclusion__c> exclusions = new List<exl_exclusion__c>();
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert testContact;

        for (Integer i = 0; i < 10; i++) {
            exclusions.add(new exl_exclusion__c(
                RecalculateDLRS__c = true,
                Contact__c = testContact.Id
            ));
        }
        insert exclusions;
        return exclusions;
    }

    @isTest
    static void testSchedulerExecution() {
        // Setup test data
        List<exl_exclusion__c> exclusions = setupTestData();

        // Schedule the job
        Test.startTest();
        String jobId = System.schedule('Test Exclusion Rollup Scheduler', '0 0 0 * * ?', new ExclusionRollupScheduler());
        Test.stopTest();

    }
}