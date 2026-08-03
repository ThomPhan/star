public with sharing class ExlSendRevocationNotification {

    @InvocableMethod(
        label='Send Revocation Custom Notification'
        description='Sends a Salesforce custom notification for a revocation case to a list of recipients.'
    )
    public static void send(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;
        for (Request req : requests) {
            if (req.recipientIds == null || req.recipientIds.isEmpty()) continue;
            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(req.notifTypeId);
            notif.setTitle(req.title);
            notif.setBody(req.body);
            notif.setTargetId(req.targetId);
            notif.send(new Set<String>(req.recipientIds));
        }
    }

    public class Request {
        @InvocableVariable(required=true label='Notification Type Id')
        public String notifTypeId;

        @InvocableVariable(required=true label='Recipient Ids')
        public List<String> recipientIds;

        @InvocableVariable(required=true label='Title')
        public String title;

        @InvocableVariable(required=true label='Body')
        public String body;

        @InvocableVariable(required=true label='Target Record Id')
        public String targetId;
    }
}