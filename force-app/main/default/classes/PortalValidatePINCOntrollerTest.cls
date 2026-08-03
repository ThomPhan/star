@isTest
public class PortalValidatePINCOntrollerTest {
    @testSetup static void setup() {
        // Create common test accounts
        Id uId = UserInfo.getUserId();
        User us = [select Id,ContactId,token__c,token_a__c from User where Id =:uId];
        us.token__c = '1234';
        us.token_a__c = '2345';
        update us;
        
    }
    @isTest static void testValidatePIN() {
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new HttpCallout());
        //Object test = new Object();
        String response = PortalValidatePINController.validatePIN('test');
        System.assertEquals('200', response,'Response not received');
        Test.Stoptest();
    }
    @isTest static void updatePINTest() {
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new HttpCallout()); 
        Integer response1 = PortalValidatePINController.updatePIN('test','test');
        System.assertEquals(200, response1,'Response not received');
        Test.Stoptest();
    }
}