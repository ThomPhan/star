public class PortalValidatePINController {
    @AuraEnabled
    public static String validatePIN(String oldPIN) {
        Integer responseCode;
        String responseMessage = '';
        Id uId = UserInfo.getUserId();
        Portal_Client_Credentials__mdt pinValidate = [SELECT Id, Client_ID__c, Client_Secret__c, Endpoint_URL__c, x_seg_clientid__c FROM Portal_Client_Credentials__mdt WHERE MasterLabel = 'PIN validate API'];
        User us = [SELECT Id, ContactId, token__c, token_a__c FROM User WHERE Id = :uId];
        
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('POST');
        req1.setHeader('Content-Type', 'application/json');
        req1.setHeader('x-seg-clientid', 'Web');
        req1.setHeader('x-id-token', us.token__c);
        req1.setEndpoint(pinValidate.Endpoint_URL__c);
        req1.setHeader('Authorization', 'Bearer ' + us.token_a__c);
        req1.setBody('{"pin": "' + oldPIN + '"}');
        
        Http http1 = new Http();
        
        try {
            HTTPResponse response1 = http1.send(req1);
            responseCode = response1.getStatusCode();
            String responseBody = response1.getBody();
            
            // Logging the full response details
            System.debug('@@@ Response Status Code: ' + response1.getStatusCode());
            System.debug('@@@ Response Status: ' + response1.getStatus());
            
            // Accessing known response headers (replace 'Header-Name' with actual header names if needed)
            System.debug('@@@ Response Header Example: Content-Type=' + response1.getHeader('Content-Type'));
            System.debug('@@@ Response Body: ' + response1.getBody());
            
            // Use JSON.deserializeUntyped to parse the JSON response
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            // Check if "error" key exists and if it's "invalid_token"
            if (responseMap.containsKey('error') && responseMap.get('error') == 'invalid_token') {
                System.debug('@@@ Token is invalid or expired. Logging out user.');
                return string.valueOf(response1.getStatusCode()) +' - '+'LOGOUT_USER'; // Custom identifier for the front end to log out the user
            }
            else if (responseMap.containsKey('statusMessage') && responseMap.get('statusMessage') == 'Card Locked') {
                System.debug('@@@ Card is Locked. Logging out user.');
                return string.valueOf(response1.getStatusCode()) +' - '+'CARD_LOCKED';
            } 
            else if (responseMap.containsKey('statusMessage')) {
                responseMessage = string.valueOf(response1.getStatusCode()) +' - '+ (String) responseMap.get('statusMessage');
            } 
            else {
                responseMessage = string.valueOf(response1.getStatusCode()); // Return the actual status code
            }
            
        } catch (Exception e) {
            ErrorLogger.createLog('PortalValidatePINController', 'validatePIN', e, '', 'Apex Class');
            System.debug('@@@ Exception: ' + e.getMessage());
        }
        
        // Return the appropriate value as a String or Integer, wrapped in Object
        return responseMessage;
    }


    @AuraEnabled
    public static Integer updatePIN(String oldPIN,string newPIN){
        Id uId = UserInfo.getUserId();
        Portal_Client_Credentials__mdt pinUpdate = [Select Id,Client_ID__c,Client_Secret__c,Endpoint_URL__c,x_seg_clientid__c from Portal_Client_Credentials__mdt where MasterLabel = 'PIN Update API'];
        User us = [select Id,ContactId,token__c,token_a__c from User where Id =:uId];
        
        System.debug('@@@@@token1 ' + us.token__c);
        System.debug('@@@@@token2 ' + us.token_a__c);
        System.debug('@@@@@oldPIN ' + oldPIN);
        System.debug('@@@@@newPIN ' + newPIN);
        
        Id conId = us.ContactId;
        Contact con = new Contact();
        if(conId != null){
            con = [select Id,Patron_ID__c from Contact where Id=:conId];
        }
        System.debug('@@@@@con ' + con );
        
        Integer responsecode;
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('PUT');
        req1.setHeader('Content-Type','application/json');
        req1.setEndpoint(pinUpdate.Endpoint_URL__c);
        req1.setHeader('Authorization', 'Bearer ' + us.token_a__c);
        req1.setHeader('x-seg-clientid','Web');
        req1.setHeader('x-id-token',us.token__c);
        // Constructing the request body
        String requestBody = '{"oldPin": '+oldPIN+',"newPin": '+newPIN+'}';
        req1.setBody(requestBody);
        
        // Logging the full request details
        System.debug('@@@ Request Method: ' + req1.getMethod());
        System.debug('@@@ Request Endpoint: ' + req1.getEndpoint());
        System.debug('@@@ Request Headers: Content-Type=' + req1.getHeader('Content-Type') +
                    ', x-seg-clientid=' + req1.getHeader('x-seg-clientid') +
                    ', x-id-token=' + req1.getHeader('x-id-token') +
                    ', Authorization=' + req1.getHeader('Authorization'));
        System.debug('@@@ Request Body: ' + requestBody);
                     
        Http http1 = new Http();
        
        try{
            HTTPResponse response1 = http1.send(req1);
            // Logging the full response details
            System.debug('@@@ Response Status Code: ' + response1.getStatusCode());
            System.debug('@@@ Response Status: ' + response1.getStatus());
            
            // Accessing known response headers (replace 'Header-Name' with actual header names if needed)
            System.debug('@@@ Response Header Example: Content-Type=' + response1.getHeader('Content-Type'));
            
            System.debug('@@@ Response Body: ' + response1.getBody());
            responsecode = response1.getStatusCode();

        }catch (Exception e){
            //execute the Error Logger object
            ErrorLogger.createLog('PortalValidatePINController', 'updatePIN', e, '', 'Apex Class');
        }
        return responsecode;
    }
}