/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-05-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-01-2020   sakshi.chauhan@simplus.com   Initial Version
**/
@isTest
public class LoyaltyProgramUIControllerTest {

    //Positive Scenario
    @isTest
    public static void testGetLoyaltyInfo(){
        Contact patron = new Contact();
        patron.FirstName = 'John';
        patron.LastName = 'Smith';
        patron.email='test@gmail.com';
        insert patron;

        Loyalty_Program__c prog = new Loyalty_Program__c(Name='Gold Membership');
        insert prog;

        Loyalty__c loyaltyObj = new Loyalty__c();

        loyaltyObj.Points_to_Retain_Current_Tier__c = 90;
        loyaltyObj.Tier_Review_Date__c = System.Today() +30;
        loyaltyObj.Points_To_Next_Tier__c = 800;

        loyaltyObj.Patron__c = patron.Id;
        loyaltyObj.Tier__c = 'Silver';
        loyaltyObj.Next_Tier__c= 'Gold';
        loyaltyObj.Next_Tier__c= 'Gold';
        loyaltyObj.Loyalty_Program__c= prog.Id;
        loyaltyObj.Last_Successful_Update__c= '2022-05-25T02:04:28.557+0';


        loyaltyObj.currentTierImage__c = 'Silver.png';
        loyaltyObj.NextTierImage__c = 'Gold.png';
        loyaltyObj.Review_CountdownImage__c = 'silverGoldCountDown.png';

        insert loyaltyObj;

        LoyaltyProgramUIController.LoyaltyInfoWrapper  wrapObj;
        Test.startTest();
             wrapObj = LoyaltyProgramUIController.getLoyaltyInfo(patron.Id);
        Test.stopTest();

        system.assert(wrapObj.pointToMaintainCurrentTier!= null);
        system.assert(wrapObj.pointToGetToNextTier != null);
        system.assert(wrapObj.reviewCountDown!= null);

        system.assert(wrapObj.currentTierImageName!= null);
        system.assert(wrapObj.nextTierImageName!= null);
        system.assert(wrapObj.countdownImage!= null);

        system.assert(wrapObj.currentTierName!= null);
        system.assert(wrapObj.nextTierName!= null);

    }

    //Negative Scenario
    @isTest
    public static void testGetLoyaltyInfoNoDataExists(){
        Contact patron = new Contact();
        patron.FirstName = 'John';
        patron.LastName = 'Smith';
        patron.email='test@gmail.com';
        insert patron;

        LoyaltyProgramUIController.LoyaltyInfoWrapper  wrapObj;
        Test.startTest();
             wrapObj = LoyaltyProgramUIController.getLoyaltyInfo(patron.Id);
        Test.stopTest();

        system.assert(wrapObj == null);

    }
}