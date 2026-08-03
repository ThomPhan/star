@isTest
public class LoyaltyHelperTest {
	@testSetup
    static void testDataFactory(){
        Contact testContact = new Contact();
        testContact.LastName = 'Class';
        testContact.Refused_to_provide_SOW__c = true;
        
        INSERT testContact;
        
        Loyalty_Program__c testLP = new Loyalty_Program__c();
        testLP.Name = 'Test Class Star';
        INSERT testLP;
        
        Loyalty__c testLoyalty = new Loyalty__c();
        testLoyalty.Name = 'Test Loyalty';
        testLoyalty.Patron__c = testContact.Id;
        testLoyalty.Loyalty_Program__c = testLP.Id;
        testLoyalty.Tier_Balance__c = 50;
        testLoyalty.Points_to_Retain_Current_Tier__c = 5;
        testLoyalty.Points_To_Next_Tier__c = 50;
        testLoyalty.Tier_Points_Earned_Today__c = 5;
        testLoyalty.Tier_Points_Earned_This_Week__c = 15;
        testLoyalty.Tier_Points_Earned_This_Month__c = 35;
        testLoyalty.CasinoBalance__c = 0;
        testLoyalty.CompBalance__c = 0;
        testLoyalty.Last_Successful_Update__c = '2022-05-25T02:04:28.557+0';
        
        INSERT testLoyalty;
    }
    
    static testMethod void testLoyaltyHelper(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        test.startTest();
        Loyalty__c assertLoyalty = LoyaltyHelper.getLoyaltyInfo(testContact.Id);
        test.stopTest();
        
        System.assertEquals('Test Loyalty', assertLoyalty.Name);
    }
    
    static testMethod void testLoyaltyHelperNegative(){
        Contact testContact = new Contact();
        testContact.LastName = 'Class';
        testContact.Refused_to_provide_SOW__c = true;
        
        INSERT testContact;

        test.startTest();
        try{
        	Loyalty__c assertLoyalty = LoyaltyHelper.getLoyaltyInfo(testContact.Id);
        }catch(Exception qExcp){
            System.assert(qExcp != NULL);
        }
        test.stopTest();
        
        
    }
}