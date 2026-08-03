/**
 * @description       : Controller to return Loyalty info related to Patron
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-05-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-15-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public without sharing class LoyaltyProgramUIController {
    
    @AuraEnabled
    public static LoyaltyInfoWrapper getLoyaltyInfo(Id contactId){
        LoyaltyInfoWrapper wrapperObj = new LoyaltyInfoWrapper();
        Loyalty__c loyalInfo = getLoyaltyData(contactId);
        if(loyalInfo != null){
            wrapperObj.pointToMaintainCurrentTier = loyalInfo.Points_to_Retain_Current_Tier__c;
            wrapperObj.pointToGetToNextTier = loyalInfo.Points_To_Next_Tier__c;
            wrapperObj.reviewCountDown = Integer.valueOf(loyalInfo.Tier_Review_Countdown__c);
            wrapperObj.currentTierImageName = loyalInfo.currentTierImage__c;
            wrapperObj.nextTierImageName = loyalInfo.NextTierImage__c;
            wrapperObj.countdownImage = loyalInfo.Review_CountdownImage__c;
            system.debug(wrapperObj.countdownImage);
            wrapperObj.currentTierName = loyalInfo.Tier__c;
            wrapperObj.nextTierName = loyalInfo.Next_Tier__c;
            if(loyalInfo.Last_Successful_Update__c != null){
                //wrapperObj.lastSuccessfulUpdate = loyalInfo.Last_Successful_Update__c.format('dd/MM/yyyy, hh:mm a', + 'Pacific');
                if(loyalInfo.Last_Successful_Update__c.contains('T')){
                    wrapperObj.lastSuccessfulUpdate = DateTime.ValueofGmt(loyalInfo.Last_Successful_Update__c.replace('T', ' ')).format('dd/MM/yyyy, hh:mm a', + 'Pacific');
                }
                else{
                    wrapperObj.lastSuccessfulUpdate = loyalInfo.Last_Successful_Update__c;
                }
            }
        }
        else{
            wrapperObj = null;
        }
      
        return wrapperObj;
        
    }

    public static Loyalty__c getLoyaltyData(String contactId){
        List<Loyalty__c> loyaltyRecs =  [SELECT currentTierImage__c, Tier_Review_Countdown__c,Last_Successful_Update__c,NextTierImage__c,Review_CountdownImage__c,Points_to_Retain_Current_Tier__c,Points_To_Next_Tier__c,Patron__c,Tier__c,Next_Tier__c FROM Loyalty__c WHERE Patron__c =: contactId];
        if( loyaltyRecs.size () >0 ) return loyaltyRecs[0];
        return null;
    }

    public class LoyaltyInfoWrapper{
        @AuraEnabled public Decimal pointToMaintainCurrentTier{ get; set;}
        @AuraEnabled public Decimal pointToGetToNextTier{ get; set;}
        @AuraEnabled public Integer reviewCountDown{ get; set;}
        @AuraEnabled public String lastSuccessfulUpdate{ get; set;}

        @AuraEnabled public String currentTierImageName{ get; set;}
        @AuraEnabled public String nextTierImageName{ get; set;}
        @AuraEnabled public String countdownImage{ get; set;}

        @AuraEnabled public String currentTierName{ get; set;}
        @AuraEnabled public String nextTierName{ get; set;}


    }
}