@IsTest
public class TspMultiEmailActionTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create Users who will receive the alert
        List<User> users = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            users.add(new User(
                FirstName = 'Alert',
                LastName = 'User' + i,
                Alias = 'au' + i,
                Email = 'alertuser' + i + '@test.com',
                Username = 'alertuser' + i + '@test.com.' + System.currentTimeMillis(),
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert users;

        // Trigger user
        User triggerUser = new User(
            FirstName = 'Trigger',
            LastName = 'User',
            Alias = 'tu01',
            Email = 'triggeruser@test.com',
            Username = 'triggeruser@test.com.' + System.currentTimeMillis(),
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert triggerUser;
    }

    private static Id getTriggerUserId() {
        return [SELECT Id FROM User WHERE Email = 'triggeruser@test.com' LIMIT 1].Id;
    }

    @IsTest
    static void testEvaluate_WithApiEvent_TruePath() {
        Id userId = getTriggerUserId();

        TspMultiEmailAction.TEST_MODE = true;
        TspMultiEmailAction.TEST_RECIPIENT_EMAILS = new List<String>{ 'alertuser0@test.com', 'alertuser1@test.com' };
        TspMultiEmailAction.TEST_ORG_WIDE_EMAIL_ID = null; // we intentionally don't depend on it

        ApiEvent mockEvent = new ApiEvent();
        mockEvent.QueriedEntities = 'Exl_Exclusion__c';
        mockEvent.RowsProcessed = 20;
        mockEvent.UserId = userId;

        Test.startTest();
        TspMultiEmailAction action = new TspMultiEmailAction();
        Boolean result = action.evaluate((SObject)mockEvent);
        Test.stopTest();

        System.assertEquals(true, result, 'Expected evaluate() to return true for matching ApiEvent conditions.');
        //System.assert(Limits.getEmailInvocations() > 0, 'Expected at least one email invocation.');
    }

    @IsTest
    static void testEvaluate_WithReportEvent_TruePath() {
        Id userId = getTriggerUserId();

        TspMultiEmailAction.TEST_MODE = true;
        TspMultiEmailAction.TEST_RECIPIENT_EMAILS = new List<String>{ 'alertuser0@test.com' };
        TspMultiEmailAction.TEST_ORG_WIDE_EMAIL_ID = null;

        ReportEvent mockEvent = new ReportEvent();
        mockEvent.QueriedEntities = 'Exl_Exclusion__c';
        mockEvent.RowsProcessed = 15;
        mockEvent.UserId = userId;

        Test.startTest();
        TspMultiEmailAction action = new TspMultiEmailAction();
        Boolean result = action.evaluate((SObject)mockEvent);
        Test.stopTest();

        System.assertEquals(true, result, 'Expected evaluate() to return true for matching ReportEvent conditions.');
        //System.assert(Limits.getEmailInvocations() > 0, 'Expected at least one email invocation.');
    }

    @IsTest
    static void testEvaluate_NoMatch_ReturnsFalse() {
        // even if seams are set, conditions shouldn't match
        TspMultiEmailAction.TEST_MODE = true;
        TspMultiEmailAction.TEST_RECIPIENT_EMAILS = new List<String>{ 'alertuser0@test.com' };

        ApiEvent mockEvent = new ApiEvent();
        mockEvent.QueriedEntities = 'Other_Object__c';
        mockEvent.RowsProcessed = 5;

        Test.startTest();
        TspMultiEmailAction action = new TspMultiEmailAction();
        Boolean result = action.evaluate((SObject)mockEvent);
        Test.stopTest();

        System.assertEquals(false, result, 'Expected false when conditions are not met.');
    }
}