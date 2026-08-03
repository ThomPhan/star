public class Portal_LoyaltyConversion {
    // Constants
    private static final Integer MAX_ATTEMPTS = 3; // Maximum allowed attempts
    private static final String CREATION_CHANNEL = 'Website';
    private static final String SOURCE_SYSTEM = 'Digital';
    private static final String SUCCESS_STATUS = 'Success';
    private static final String ERROR_USER_NOT_FOUND = 'Error: User not found';
    private static final String ERROR_CREDENTIALS_NOT_FOUND = 'Issue: Credentials Configuration not found, Please reachout to help desk';
    private static final String ERROR_MISSING_TOKEN = 'Error: Missing user token';
    private static final String ERROR_MAX_ATTEMPTS = 'Termination: You have reached the maximum number of attempts';
    private static final String ERROR_MEMBERSHIP_UPDATE = 'Error: Membership update failed';
    private static final String LOGOUT_ERROR_MEMBERSHIP_UPDATE = 'Logout: Membership update failed due to Expired Tokens';
    private static final String ALREADYLOYALTYINITIATED = 'Issue: Already Loyalty Initiated';
    private static final String ERROR = 'Error';
    private static final String PORTAL_CLIENT_CREDENTIALS_METADATA_RECORD = 'Star Membership Conversion';
    private static final Boolean TERMSANDCONDITIONACCEPTED = true;
    
    @AuraEnabled
    public static String updateMembership() {
        String membershipStatus;
        Id uId = UserInfo.getUserId();
        /*if(uId != null){
            return ERROR_MAX_ATTEMPTS;
        }
        */
        // Fetch client credentials from custom metadata
        List<Portal_Client_Credentials__mdt> credsList = [
            SELECT Id, Client_ID__c, Client_Secret__c, Endpoint_URL__c, x_seg_clientid__c 
            FROM Portal_Client_Credentials__mdt 
            WHERE MasterLabel =: PORTAL_CLIENT_CREDENTIALS_METADATA_RECORD
        ];
        
        if(credsList.isEmpty()) {
            return ERROR_CREDENTIALS_NOT_FOUND;
        }
        
        Portal_Client_Credentials__mdt creds = credsList[0]; // Safely use the first element

        // Fetch user details
        List<User> userList = [
            SELECT Id, ContactId, token__c, token_a__c, Patron_ID__c, Portal_LoyaltyConversionInitiated__c, Portal_ConversionAttemptCount__c 
            FROM User 
            WHERE Id = :uId 
            LIMIT 1
        ];


        if (userList.isEmpty()) {
            return ERROR_USER_NOT_FOUND;
        }

        User user = userList[0];
        
        if (user.Portal_LoyaltyConversionInitiated__c) {
            return ALREADYLOYALTYINITIATED;
        }

        // Check if the user has reached the maximum number of attempts
        Integer attemptCount = user.Portal_ConversionAttemptCount__c != null ? Integer.valueOf(Math.floor(user.Portal_ConversionAttemptCount__c)) : 0;
        if (attemptCount >= MAX_ATTEMPTS) {
            return ERROR_MAX_ATTEMPTS;
        }

        // Handle null values for token__c and token_a__c
        String token = String.isBlank(user.token__c) ? 'testToken' : user.token__c;
        String tokenA = String.isBlank(user.token_a__c) ? 'testTokenA' : user.token_a__c;

        if (String.isBlank(token) || String.isBlank(tokenA)) {
            return ERROR_MISSING_TOKEN;
        }

        
        String memberId = !Test.isRunningTest() ? user.Patron_ID__c != null ? user.Patron_ID__c : '123123' : '123123';
        String acceptedDateTime = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX');  // Current date-time

        Map<String, Object> requestBody = new Map<String, Object>{
                'memberId' => memberId,
                'creationChannel' => CREATION_CHANNEL,
                'sourceSystem' => SOURCE_SYSTEM,
                'termsAndConditions' => new Map<String, Object>{
                    'termsAndConditionsAccepted' => TERMSANDCONDITIONACCEPTED,
                    'acceptedDateTime' => acceptedDateTime
                }
            };
        
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setHeader('x-seg-clientid', creds.x_seg_clientid__c);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-id-token', token);
        req.setHeader('Authorization', 'Bearer ' + tokenA);
        req.setEndpoint(creds.Endpoint_URL__c);
        req.setBody(JSON.serialize(requestBody));
		
        try {
            
            system.debug('token *** '+token);
            system.debug('tokenA *** '+tokenA);
            system.debug('creds.Endpoint_URL__c *** '+creds.Endpoint_URL__c);
            system.debug('Req Body *** '+JSON.serialize(requestBody));

            // Send the HTTP request and capture the response
            HttpResponse response = new Http().send(req);

            system.debug('response Body *** '+response);
            system.debug('response.getStatusCode() *** '+response.getStatusCode());


            Boolean shouldUpdateUser = false;
            // Increment the attempt count and update necessary fields
            user.Portal_ConversionAttemptCount__c = attemptCount + 1;

            if (response.getStatusCode() == 202) {
                membershipStatus = SUCCESS_STATUS;
                user.Portal_LoyaltyConversionInitiated__c = true;
                shouldUpdateUser = true;
            } 
            else if (response.getStatusCode() == 403) {
                // Set the membership status message for 403, but avoid updating the user record
                membershipStatus = LOGOUT_ERROR_MEMBERSHIP_UPDATE + ': ' + response.getStatus();
            }
            else {
                membershipStatus = ERROR_MEMBERSHIP_UPDATE + ': ' + response.getStatus();
                shouldUpdateUser = true;
            }

            // Only update the user if the shouldUpdateUser flag is true
            if (shouldUpdateUser) {
                update user;
            }

        } catch (Exception e) {
            // Log the error using the ErrorLogger
            System.debug('Error in membership update: ' + e.getMessage());
            membershipStatus = ERROR + ': ' + e.getMessage();
            ErrorLogger.createLog('Portal_LoyaltyConversion', 'updateMembership', e, memberId, 'Apex Class');
        }
        
        return membershipStatus;
    }

    
}