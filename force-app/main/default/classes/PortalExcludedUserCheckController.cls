public with sharing class PortalExcludedUserCheckController {
    @AuraEnabled
    public static String getUserDetails(){
        Id uId = UserInfo.getUserId();
        String resultStatus = 'FALSE';
        
        try {
            // Query the User object to include Portal_ReLoginRequired__c
            User us = [SELECT Id, token__c, token_a__c, Portal_ReLoginRequired__c,Portal_LoyaltyConversionInitiated__c FROM User WHERE Id = :uId];
            // Check if Portal_ReLoginRequired__c is true
            if(us.Portal_ReLoginRequired__c) {
                // Set Portal_ReLoginRequired__c to false
                us.Portal_ReLoginRequired__c = false;
                update us;
                
                /*
                // Invalidate all sessions (log out from all devices)
                List<AuthSession> sessions = [SELECT Id FROM AuthSession WHERE UsersId = :uId];
                if (!sessions.isEmpty()) {
                delete sessions; // This deletes all sessions for the user, logging them out globally
                }*/
                
                // Return 'RELOGIN_REQUIRED' and exit since user needs to relogin
                return 'RELOGIN_REQUIRED';
            }
            else if(us.Portal_LoyaltyConversionInitiated__c) {
                // Return 'RELOGIN_REQUIRED' and exit since user needs to relogin
                return 'LOYALTY_CONVERSION_INITIATED';
            }
            
            // Proceed with existing logic if Portal_ReLoginRequired__c is false
            AuthProvider authProvider = [SELECT Id, FriendlyName FROM AuthProvider LIMIT 1];
            String accessToken = Auth.AuthToken.getAccessToken(authProvider.Id, authProvider.FriendlyName);
            Portal_Client_Credentials__mdt userinfo = [SELECT Id, Client_ID__c, Client_Secret__c, Endpoint_URL__c, x_seg_clientid__c 
                                                       FROM Portal_Client_Credentials__mdt 
                                                       WHERE MasterLabel = 'Userinfo API'];
            
            // Only mock the refreshToken map for test scenarios
            Map<String, String> refreshToken = new Map<String, String>();
            
            // If running test, set the values manually, otherwise call the actual method
            if (Test.isRunningTest()) {
                refreshToken.put('AccessToken', null);
                refreshToken.put('RefreshError', 'Access token was not returned');
            } else {
                // Actual method call when not in test
                refreshToken = Auth.AuthToken.refreshAccessToken(authProvider.Id, authProvider.FriendlyName, accessToken);
            }
            accessToken = refreshToken.get('AccessToken');
            
            // Setup HTTP request to the user info API
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + us.token_a__c);
            req.setEndpoint(userinfo.Endpoint_URL__c);
            req.setHeader('x-seg-clientid', 'Web');
            req.setHeader('x-id-token', us.token__c);
            req.setMethod('GET');
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String responseBody = res.getBody();
            system.debug('user info response body-> ' + responseBody);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            // Check if user is excluded based on the API response
            String isExcluded = (String) responseMap.get('isExcluded');
            if('TRUE'.equalsIgnoreCase(isExcluded)) {
                resultStatus = 'EXCLUDED';
            }
        } catch (Exception e) {
            // Log any exception for debugging and monitoring purposes
            ErrorLogger.createLog('PortalExcludedUserCheckController', 'getUserDetails', e, '', 'Apex Class');
        }
        
        return resultStatus;
    }
}