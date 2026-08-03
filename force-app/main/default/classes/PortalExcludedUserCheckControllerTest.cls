@isTest
public class PortalExcludedUserCheckControllerTest {
    @testSetup 
    static void setup() {
        User us = [SELECT Id, token__c, token_a__c FROM User WHERE Id = :UserInfo.getUserId()];
        us.token__c = '1234';
        us.token_a__c = '2345';
        us.Portal_ReLoginRequired__c = true;
        update us;
    }
    
    @isTest 
    static void generatePASTest1() {
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        Object response1 = PortalExcludedUserCheckController.getUserDetails();
        System.debug('Response for Test1: ' + response1);
        System.assertEquals('RELOGIN_REQUIRED', response1, 'Test1: Expected RELOGIN_REQUIRED');
        Test.StopTest();
    }
    
    @isTest 
    static void generatePASTest2() {
        User us = [SELECT Id, token__c, token_a__c FROM User WHERE Id = :UserInfo.getUserId()];
        us.token__c = '12345';
        us.token_a__c = '23456';
        us.Portal_ReLoginRequired__c = false;
        update us;
        
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        Object response2 = PortalExcludedUserCheckController.getUserDetails();
        System.debug('Response for Test2: ' + response2);
        Test.StopTest();
    }

    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202);
            
            if (req.getEndpoint().contains('userinfo')) {
                res.setBody('{"isExcluded": "TRUE"}');
            } else {
                res.setBody('{"AccessToken": "mockAccessToken123", "status": "Success"}');
            }
            
            return res;
        }
    }
}