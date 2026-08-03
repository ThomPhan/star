@isTest
public class Portal_LoyaltyConversionTest {

    // Test setup to create necessary data
    @testSetup
    static void setupTestData() {
        // Create a test user with a unique username by appending a timestamp
        String uniqueUsername = 'testuser_' + System.currentTimeMillis() + '@example.com';

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = uniqueUsername, // Ensure the username is unique
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            Portal_LoyaltyConversionInitiated__c = false,
            Portal_ConversionAttemptCount__c = 0,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // You don't need to set Patron_ID__c directly, as it might not be writable.
        // It will be handled in the logic using Test.isRunningTest().
    }

    @isTest
    static void testUpdateMembershipSuccess() {
        // Set mock response for successful HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        // Fetch the test user created in setupTestData
        User testUser = [SELECT Id, ContactId, token__c, token_a__c, Patron_ID__c, Portal_LoyaltyConversionInitiated__c, Portal_ConversionAttemptCount__c FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        // Run test as the user created in test setup
        System.runAs(testUser) {
            Test.startTest();

            // Call the method we are testing
            String result = Portal_LoyaltyConversion.updateMembership();
            
            // Validate the result
            System.assertEquals('Success', result, 'The membership update should succeed.');
            
            Test.stopTest();
        }
    }
    
    // Mock class for a successful HTTP response
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulate a successful HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202); // Simulating the "Accepted" status
            res.setBody('{"status":"Success"}');
            return res;
        }
    }
}