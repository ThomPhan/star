/**
* Class Name  : TspMultiEmailAction
* @author     : Capgemini
* @date       : 20/10/2025
**/
global with sharing class TspMultiEmailAction implements TxnSecurity.EventCondition, TxnSecurity.AsyncCondition {

    
    @TestVisible static Boolean TEST_MODE = false;
    @TestVisible static List<String> TEST_RECIPIENT_EMAILS;
    @TestVisible static Id TEST_ORG_WIDE_EMAIL_ID;

    global Boolean evaluate(SObject event) {
        // Deserialize the event SObject into a Map for field access
        Map<String,Object> data = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(event));

        switch on event {
            when ApiEvent apiEvent {
                return evaluate(apiEvent.QueriedEntities, apiEvent.RowsProcessed, data, apiEvent);
            }
            when ReportEvent reportEvent {
                return evaluate(reportEvent.QueriedEntities, reportEvent.RowsProcessed, data, reportEvent);
            }
            when else {
                return false;
            }
        }
    }

    private Boolean evaluate(String queriedEntities, Decimal rowsProcessed, Map<String,Object> data, sObject event) {

        if ('Exl_Exclusion__c'.equalsIgnoreCase(queriedEntities) && rowsProcessed > 10) {

            Object attributes = data.get('attributes');
            if (attributes != null) {

                Map<String,Object> attribMap =
                    (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(attributes));

                if (attribMap != null) {

                    String type = (String) attribMap.get('type');
                    if (String.isBlank(type)) {
                        type = String.valueOf(event.getSObjectType());
                    }

                    if (String.isNotBlank(type)) {

                        List<String> emails = new List<String>();

                        if (TEST_MODE && TEST_RECIPIENT_EMAILS != null) {
                            emails.addAll(TEST_RECIPIENT_EMAILS);
                        } else {
                            // Get user list from custom label (names)
                            List<String> userList = new List<String>();
                            if (!String.isBlank(System.label.Exl_Exclusion_Transaction_Security_Policy_Users)) {
                                for (String s : System.label.Exl_Exclusion_Transaction_Security_Policy_Users.split(',')) {
                                    if (String.isNotBlank(s)) userList.add(s.trim());
                                }
                            }

                            if (!userList.isEmpty()) {
                                for (User u : [SELECT Email FROM User WHERE Name IN :userList]) {
                                    if (!String.isBlank(u.Email)) emails.add(u.Email);
                                }
                            }
                        }

                        if (emails.isEmpty()) {
                            return true; // policy matched; nothing to notify (prevents false negatives)
                        }

                        // Get triggering user safely
                        String userId = (String) data.get('UserId');

                        String triggerUserName = 'Unknown User';
                        if (String.isNotBlank(userId)) {
                            List<User> triggerUsers = [SELECT Name FROM User WHERE Id = :userId LIMIT 1];
                            if (!triggerUsers.isEmpty()) triggerUserName = triggerUsers[0].Name;
                        }

                        Id orgWideId;
                        if (TEST_MODE && TEST_ORG_WIDE_EMAIL_ID != null) {
                            orgWideId = TEST_ORG_WIDE_EMAIL_ID;
                        } else {
                            String emailAdd = System.label.Exl_Transaction_Security_Policy_Email;

                            if (!String.isBlank(emailAdd)) {
                                List<OrgWideEmailAddress> owea =
                                    [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :emailAdd LIMIT 1];
                                if (!owea.isEmpty()) orgWideId = owea[0].Id;
                            }
                        }

                        String subject = 'Transaction Security Alert: ' + type;
                        String body = 'Alert Details:\n' +
                            '==============\n' +
                            'Event Type: ' + type + '\n' +
                            'Entity: ' + queriedEntities + '\n' +
                            'Rows Returned: ' + rowsProcessed + '\n' +
                            'User: ' + triggerUserName + '\n' +
                            'Timestamp: ' + DateTime.now().format() + '\n\n' +
                            'Action: This transaction has been blocked due to excessive data export.';

                        sendEmail(emails, subject, body, orgWideId);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    @Future
    public static void sendEmail(List<String> emails, String subject, String body, Id orgWideId) {

        if (emails == null || emails.isEmpty()) return;

        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(emails);
        m.setSubject(subject);
        m.setPlainTextBody(body);
        m.setSaveAsActivity(false);

        if (orgWideId != null) {
            m.setOrgWideEmailAddressId(orgWideId);
        }

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ m }, false);
        } catch (Exception e) {
            System.debug('errorCode: ' + e.getCause() + ' message: ' + e.getMessage());
        }
    }
}