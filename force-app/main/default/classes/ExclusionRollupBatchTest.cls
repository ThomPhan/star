@isTest
private class ExclusionRollupBatchTest {

    // Test data setup method
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
    static void testBatchExecution() {
        // Setup test data
        List<exl_exclusion__c> exclusions = setupTestData();

        // Execute the batch
        Test.startTest();
        ExclusionRollupBatch batch = new ExclusionRollupBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify the results
        for (exl_exclusion__c exclusion : [SELECT Id, RecalculateDLRS__c FROM exl_exclusion__c]) {
            System.assertEquals(false, exclusion.RecalculateDLRS__c, 'RecalculateDLRS__c should be set to false');
        }
		
    }
}