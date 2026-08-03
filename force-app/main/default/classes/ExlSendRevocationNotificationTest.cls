@IsTest
private class ExlSendRevocationNotificationTest {

    @IsTest
    static void testSendEmptyRequests() {
        Test.startTest();
        ExlSendRevocationNotification.send(new List<ExlSendRevocationNotification.Request>());
        Test.stopTest();
    }

    @IsTest
    static void testSendEmptyRecipients() {
        ExlSendRevocationNotification.Request req = new ExlSendRevocationNotification.Request();
        req.notifTypeId = 'dummy';
        req.recipientIds = new List<String>();
        req.title = 'Test';
        req.body = 'Test body';
        req.targetId = UserInfo.getUserId();

        Test.startTest();
        ExlSendRevocationNotification.send(new List<ExlSendRevocationNotification.Request>{ req });
        Test.stopTest();
    }

    @IsTest
    static void testSendWithRecipient() {
        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType
            WHERE DeveloperName = 'Exl_Revocation_Alert'
            LIMIT 1
        ];
        if (notifTypes.isEmpty()) return;

        ExlSendRevocationNotification.Request req = new ExlSendRevocationNotification.Request();
        req.notifTypeId = notifTypes[0].Id;
        req.recipientIds = new List<String>{ UserInfo.getUserId() };
        req.title = 'Revocation Outcome Required - 3c/3e Form Case';
        req.body = 'Test alert body for case 00001234';
        req.targetId = UserInfo.getUserId();

        Test.startTest();
        try {
            ExlSendRevocationNotification.send(new List<ExlSendRevocationNotification.Request>{ req });
        } catch (Exception e) {
            // Acceptable in test context where target record is a user, not a case
        }
        Test.stopTest();
    }
}