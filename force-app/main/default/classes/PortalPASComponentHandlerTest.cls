@isTest
public class PortalPASComponentHandlerTest {
    @testSetup static void setup() {
        // Create common test accounts
        Id uId = UserInfo.getUserId();
        User us = [select Id,ContactId,token__c,token_a__c from User where Id =:uId];
        us.token__c = '1234';
        us.token_a__c = '2345';
        update us;
        
    }
    
	
    @isTest static void generatePASTest() {
        Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new exportResponseGenerator()); 
	Object response1 = PortalPASComponentHandler.generatePAS('2024','january');
        System.assertEquals('12345', response1,'Response not received');
        Test.Stoptest();
    }
    @isTest static void getPASPDFTest() {
        Test.StartTest();
      Test.setMock(HttpCalloutMock.class, new statusResponseGenerator()); 
	String response1 = PortalPASComponentHandler.getPASPDF('test1234');
        Test.Stoptest();
    }
    
     // Implement a mock http response generator for Concur. 
    public class exportResponseGenerator implements HttpCalloutMock 
    { 
        public HTTPResponse respond(HTTPRequest req) 
        { 
            
            HttpResponse res = new HttpResponse(); 
            res.setHeader('Content-Type', 'application/xml'); 
            res.setBody('{"id":"12345","given_name":"testFirstName","family_name":"testLastName","email":"testEmailAddress"}'); 
            res.setStatusCode(200); 
            return res; 
        } 
        
    } 
    
     // Implement a mock http response generator for Concur. 
    public class statusResponseGenerator implements HttpCalloutMock 
    { 
        public HTTPResponse respond(HTTPRequest req) 
        { 
            
            HttpResponse res = new HttpResponse(); 
            res.setHeader('Content-Type', 'application/xml'); 
            res.setBody('{"status":"Succeeded","given_name":"testFirstName","family_name":"testLastName","email":"testEmailAddress"}'); 
            res.setStatusCode(200); 
            return res; 
        } 
        
    } 
    
    
     // Implement a mock http response generator for Concur. 
    public class pdfResponseGenerator implements HttpCalloutMock 
    { 
        public HTTPResponse respond(HTTPRequest req) 
        { 
            
            HttpResponse res = new HttpResponse(); 
            res.setHeader('Content-Type', 'application/xml'); 
            res.setBody('Test Body'); 
            res.setStatusCode(200); 
            return res; 
        } 
        
    } 
}