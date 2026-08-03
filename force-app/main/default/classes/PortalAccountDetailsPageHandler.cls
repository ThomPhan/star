public class PortalAccountDetailsPageHandler {
    public Static Contact con;
    
    @AuraEnabled
    public static Contact getContactDetails(){
        try{
            Id uId = UserInfo.getUserId();
            User us = [select Id,ContactId,token__c from User where Id =:uId];
            system.debug('id token'+us.token__c);
            con = new Contact();
            Id conId = us.ContactId;
            if(conId != null){
                con = [select Id,Patron_ID__c,FirstName,Name,Email,MobilePhone,HomePhone,MailingStreet,MailingState,MailingCity,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode,Direct_Mail_Consent__c,Preferred_Address__c,Email_Consent__c,SMS_Consent__c,Portal_Email_Update_Sync_Wait__c,Portal_Mobile_Update_Sync_Wait__c from Contact where Id=:conId];
            }
        }catch (Exception e){
            //execute the Error Logger object
            ErrorLogger.createLog('PortalAccountDetailsPageHandler', 'getContactDetails', e, '', 'Apex Class');
        }
        return con;
    }
    
    @AuraEnabled
    public static Map<String, Object> getContactAndUserDetails() {
        Map<String, Object> responseMap = new Map<String, Object>();
        
        try {
            Id uId = UserInfo.getUserId();
            // Fetch the User record along with the additional fields from the User object
            User us = [SELECT Id, ContactId, token__c, Portal_EmailVerified__c, Portal_PhoneNumberVerified__c, Portal_LoginMethod__c 
                       FROM User 
                       WHERE Id =: uId];
            
            responseMap.put('userEmailVerified', us.Portal_EmailVerified__c);
            responseMap.put('userPhoneVerified', us.Portal_PhoneNumberVerified__c);
            responseMap.put('loginWithPIN', us.Portal_LoginMethod__c != null && us.Portal_LoginMethod__c.contains('pin'));
            // Fetch Contact details if the User has a related Contact
            if (us.ContactId != null) {
                con = [SELECT Id, Patron_ID__c, FirstName, Name, Email, MobilePhone, HomePhone, 
                       MailingStreet, MailingState, MailingCity, MailingCountry, MailingPostalCode, 
                       OtherStreet, OtherCity, OtherState, OtherCountry, OtherPostalCode, 
                       Direct_Mail_Consent__c, Preferred_Address__c, Email_Consent__c, 
                       SMS_Consent__c, Portal_Email_Update_Sync_Wait__c, Portal_Mobile_Update_Sync_Wait__c 
                       FROM Contact 
                       WHERE Id =: us.ContactId];
                responseMap.put('contact', con);
            }
        } catch (Exception e) {
            // Log the error
            ErrorLogger.createLog('PortalAccountDetailsPageHandler', 'getContactAndUserDetails', e, '', 'Apex Class');
        }
        
        return responseMap;
    }
    
    @AuraEnabled
    public static Contact contactSyncUpdate(String event_type){
        try{
            Id uId = UserInfo.getUserId();
            User us = [select Id,ContactId,token__c from User where Id =:uId];
            con = new Contact();
            Id conId = us.ContactId;
            if(conId != null){
                con = [select Id,Patron_ID__c,FirstName,Name,Email,MobilePhone,HomePhone,MailingStreet,MailingState,MailingCity,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode,Direct_Mail_Consent__c,Preferred_Address__c,Email_Consent__c,SMS_Consent__c,Portal_Email_Update_Sync_Wait__c,Portal_Mobile_Update_Sync_Wait__c from Contact where Id=:conId];
            }
            system.debug('event_type'+event_type);
            if(event_type != null){
                if(event_type == 'Email Update'){
                    con.Portal_Email_Update_Sync_Wait__c = true;
                    con.Portal_Email_Updated_Time__c = System.now();
                }else if(event_type == 'Mobile Update'){
                    con.Portal_Mobile_Update_Sync_Wait__c = true;
                    con.Portal_Mobile_Updated_Time__c = System.now();
                }
                update con;
            }
        }catch (Exception e){
            //execute the Error Logger object
            ErrorLogger.createLog('PortalAccountDetailsPageHandler', 'getContactDetails', e, '', 'Apex Class');
        }
        return con;
    }
    @AuraEnabled
    public static void updateContactDetails(Boolean emailConsent, Boolean smsConsent, String prefAdd) {
        Contact con1 = getContactDetails();
        system.debug('con1 :11: ' + con1);
        system.debug('emailConsent :11: ' + emailConsent);
        system.debug('smsConsent :11: ' + smsConsent);
        system.debug('prefAdd :11: ' + prefAdd);

        if (con1.Email_Consent__c != emailConsent) {
            con1.Email_Consent__c = emailConsent;
        }
        if (con1.SMS_Consent__c != smsConsent) {
            con1.SMS_Consent__c = smsConsent;
        }
        
        if (prefAdd != null && !String.isEmpty(prefAdd) && !String.isBlank(prefAdd)) {
            if (con1.Preferred_Address__c != prefAdd || !con1.Direct_Mail_Consent__c) {
                con1.Direct_Mail_Consent__c = true;
                con1.Preferred_Address__c = prefAdd;
            }
        } else {
            // Only set Direct_Mail_Consent__c to false if prefAdd is explicitly an empty string
            con1.Direct_Mail_Consent__c = false;
            con1.Preferred_Address__c = '';
        }

        try {
            system.debug('con1 :22: ' + con1);
            update con1;
        } catch (DmlException e) {
            ErrorLogger.createLog('PortalAccountDetailsPageHandler', 'updateContactDetails', e, '', 'Apex Class');
        }
    }

    @AuraEnabled
    public static Map<String,String> getPingOneURLS(){
        Map<String,String> pingOneMap = new Map<String,String>();
        try{
            List<Portal_Client_Credentials__mdt> urlList = [Select Id,MasterLabel,Client_ID__c,Authorize_URL__c,Policy_ID__c,Redirect_URL__c,Target_URL__c from Portal_Client_Credentials__mdt where MasterLabel LIKE '%PingOne Update'];
            for(Portal_Client_Credentials__mdt url : urlList){
                String pingUrl = url.Authorize_URL__c + '?client_id=' + url.Client_ID__c + '&redirect_uri=' + url.Redirect_URL__c + '&target_link_uri=' + url.Target_URL__c + '&response_type=code&scope=openid%20role&acr_values=' + url.Policy_ID__c;
                pingOneMap.put(url.MasterLabel,pingUrl);
            }
        }catch(DmlException e) {
            ErrorLogger.createLog('PortalAccountDetailsPageHandler', 'getPingOneURLS', e, '', 'Apex Class');
        }
        system.debug('pingOneMap==>'+pingOneMap);
        return pingOneMap;
    }
    
    @AuraEnabled
    public static void updatePortalReLoginRequired() {
        Id userId = UserInfo.getUserId();
        List<User> userRecords = [SELECT Id, Portal_ReLoginRequired__c FROM User WHERE Id = :userId LIMIT 1];
        
        if (!userRecords.isEmpty()) {
            User userRecord = userRecords[0];
            userRecord.Portal_ReLoginRequired__c = true;
            
            try {
                update userRecord;
            } catch (Exception e) {
                System.debug('Error updating Portal_ReLoginRequired: ' + e.getMessage());
                throw new AuraHandledException('Error updating user information');
            }
        } else {
            throw new AuraHandledException('User record not found');
        }
    }
    
}