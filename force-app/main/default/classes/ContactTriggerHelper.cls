/**
* Class Name  : ContactTriggerHelper
* @author     : Capgemini
* @Description: A utility class to contain the business logic for the Contact object trigger
* @version    : Version 1 : 24/10/2025
**/

public class ContactTriggerHelper {
    
    public static void updateUserEmailfromContact(List<Contact> contList, Map<Id, Contact> oldContMap){        
        Map<Id,String> conMap = new Map<Id,String>();
        List<User> userUpdateList = new List<User>();
        for(Contact c : contList){
            if(c.get('Email') != oldContMap.get(c.Id).get('Email') && (c.get('Loyalty_Program__c') == 'Social')){
                conMap.put((Id)c.get('Id'),(String)c.get('Email'));
            }
        }

        for(User u : [Select Id,Email,ContactId from User where contactId IN: conMap.keySet()]){
            u.Email = conMap.get(u.ContactId);
            userUpdateList.add(u);
        }

        if(userUpdateList.size() > 0){
            update userUpdateList;
        } 
    }
    
    
    public static void reconcileRestrictionRecords(List<Contact> newContactList, Map<Id, Contact> oldContMap){
        List<Id> conStatusList = new List<Id>();
        List<Id> conMarketingList = new List<Id>();
        List<Id> conTierLostList = new List<Id>();
        
        List<Id> conStatusRevList = new List<Id>();
        List<Id> conMarketingRevList = new List<Id>();
        List<Id> conTierLostRevList = new List<Id>();
        
        List<Exl_Restriction__c> restrictionUpdateList = new List<Exl_Restriction__c>();
        
        for(Contact c : newContactList){
            //Activate path - check if Contact Patron_Status__c field is changed and value is Excluded All
            if(c.Patron_Status__c == ConstantHelper.STRING_CONTACT_PATRON_STATUS_EXCLUDED_ALL && oldContMap.get(c.Id).Patron_Status__c != c.Patron_Status__c){
            	conStatusList.add(c.Id);
            }
            //Revoke path - check if Contact Patron_Status__c field is changed and OLD value is Excluded All
            else if(oldContMap.get(c.Id).Patron_Status__c == ConstantHelper.STRING_CONTACT_PATRON_STATUS_EXCLUDED_ALL
                     && oldContMap.get(c.Id).Patron_Status__c != c.Patron_Status__c){
            	conStatusRevList.add(c.Id);
            }
            
            //Receive Marketing communication
            //Activate path - check if Contact Direct_Mail_Consent__c / Email_Consent__c / SMS_Consent__c field is changed to FALSE
            if(!c.Direct_Mail_Consent__c && oldContMap.get(c.Id).Direct_Mail_Consent__c != c.Direct_Mail_Consent__c && !c.Email_Consent__c && !c.SMS_Consent__c
               || !c.Email_Consent__c && oldContMap.get(c.Id).Email_Consent__c != c.Email_Consent__c && !c.Direct_Mail_Consent__c && !c.SMS_Consent__c 
               || !c.SMS_Consent__c && oldContMap.get(c.Id).SMS_Consent__c != c.SMS_Consent__c && !c.Direct_Mail_Consent__c && !c.Email_Consent__c ){
                conMarketingList.add(c.Id);
            } 
            //Revoke path - check if Contact Direct_Mail_Consent__c / Email_Consent__c / SMS_Consent__c field is changed to TRUE
            else if(c.Direct_Mail_Consent__c && oldContMap.get(c.Id).Direct_Mail_Consent__c != c.Direct_Mail_Consent__c && c.Email_Consent__c && c.SMS_Consent__c
                   || c.Email_Consent__c && oldContMap.get(c.Id).Email_Consent__c != c.Email_Consent__c && c.Direct_Mail_Consent__c && c.SMS_Consent__c 
                   || c.SMS_Consent__c && oldContMap.get(c.Id).SMS_Consent__c != c.SMS_Consent__c && c.Direct_Mail_Consent__c && c.Email_Consent__c ){
                conMarketingRevList.add(c.Id);
            }
                        
            //Tier Level Lost
            if(c.Tier__c != oldContMap.get(c.Id).Tier__c){
            	//Activate path
				if( c.Tier__c == 'Bronze' ){
                	conTierLostList.add(c.Id);
                } 
                //Revoke path
                else if( oldContMap.get(c.Id).Tier__c == 'Bronze' ){
                    conTierLostRevList.add(c.Id);
                }
            }
            
        }
        
        //Exclusion Activation
        if( !conStatusList.isEmpty() || !conMarketingList.isEmpty() || !conTierLostList.isEmpty()){
            for(Exl_Restriction__c res : [SELECT Id, Restriction_Type__c, Enforcement_Status__c FROM Exl_Restriction__c 
                                          WHERE (Enforcement_Status__c != :ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE 
                                          AND ( (Patron__c IN :conStatusList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_FUNDS ) 
                                           OR (Patron__c IN :conMarketingList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_MARKETING_COMMS)
                                               OR (Patron__c IN :conTierLostList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_TIER_LEVEL_LOST)) ) ] ){
                if(res.Enforcement_Status__c == ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED){
                	res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_OVERRIDDEN;
                } else {
                	res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE;
                }
                restrictionUpdateList.add(res); 
            }
        }
        
        //Exclusion Revocation
        if( !conStatusRevList.isEmpty() || !conMarketingRevList.isEmpty() || !conTierLostRevList.isEmpty()){
            for(Exl_Restriction__c res : [SELECT Id, Restriction_Type__c, Enforcement_Status__c FROM Exl_Restriction__c 
                                          WHERE (Enforcement_Status__c != :ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED 
                                          AND ( (Patron__c IN :conStatusRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_FUNDS ) 
                                           OR (Patron__c IN :conMarketingRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_MARKETING_COMMS)
                                              OR (Patron__c IN :conTierLostRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_TIER_LEVEL_LOST)) ) ] ){
                //update status to active
                if(res.Enforcement_Status__c == ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE){
                	res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_OVERRIDDEN;
                } else {
                	res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED;
                }
                restrictionUpdateList.add(res); 
            }
        }
        
        //Update Restriction record 
        if(!restrictionUpdateList.isEmpty()){
        	update restrictionUpdateList;
        }
        
    }

}