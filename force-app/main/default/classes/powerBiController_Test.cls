@isTest
public class powerBiController_Test{
    @isTest
    public static void callPowerBiReportController(){
        powerBiReportController.getMetadataValue();
    }

    @isTest
    public static void callPowerBiReportControllerGiv(){
        powerBiReportControllerGiv.getMetadataValue();
    }
    
    @isTest
    public static void callPowerBiController(){
        PowerBIController pbiController = new PowerBIController();
        pbiController.getValidateResult();
        pbiController.redirectOnCallback();
    }
    
    public class TestCalloutData {
        integer status = 200;
        string body = '';
        map<String, String> headers = new Map<String, String>();
        boolean throwError = false;
        
        @TestVisible
        TestCalloutData(Boolean forError) {
            this.throwError = forError;
        }        
        
        @TestVisible
        TestCalloutData(String body) {
            this.body = body;
        }
        
        @TestVisible
        TestCalloutData(integer status, String body) {
            this.status = status;
            this.body = body;
        }        
    }    
    
    public class TestCalloutMock implements HttpCalloutMock {
        private List<TestCalloutData> data = new List<TestCalloutData>();
        private integer iteration = 0;        
        
        @TestVisible
        TestCalloutMock(List<TestCalloutData> mockData) {
            this.data = mockData;
        }               
        
        public HTTPResponse respond(HttpRequest req)
        {
            if (iteration>=data.size()) iteration = data.size() - 1;
            TestCalloutData tdata = data[iteration];
            HttpResponse res = new HttpResponse();
            
            if (tdata.throwError) {
                throw new System.CalloutException('Read time out');
            } else {
                for (String key : tdata.headers.keySet()) {
                    res.setHeader(key, tdata.headers.get(key));
                }
                
                res.setBody(tdata.body);
                res.setStatusCode(tdata.status);
    
                iteration++;
                if (iteration > this.data.size()) iteration = 0;                
            }
            return res;            
        }
    }
	
    @isTest
    static void callPowerBiEmbedManager(){
        List<TestCalloutData> mockData = new List<TestCalloutData>();
        PowerBiEmbedManager.ClientCredentialResponse ccResponse = new PowerBiEmbedManager.ClientCredentialResponse();
        ccResponse.access_token = '';
        ccResponse.expires_in = '';
        ccResponse.ext_expires_in = '';
        ccResponse.token_type = '';       
        mockData.add(new TestCalloutData(JSON.serialize(ccResponse)));
        
        Test.setMock(HttpCalloutMock.class, new TestCalloutMock(mockData));
        
        Test.startTest();
        PowerBiEmbedManager.getEmbeddingDataForReport('String', 'String');
        PowerBiEmbedManager.getPowerBiAccessToken();
        Test.stopTest();
    }

    @isTest
    static void callPowerBiEmbedManagerGIV(){
        List<TestCalloutData> mockData = new List<TestCalloutData>();
        PowerBiEmbedManagerGIV.ClientCredentialResponse ccResponse = new PowerBiEmbedManagerGIV.ClientCredentialResponse();
        ccResponse.access_token = '';
        ccResponse.expires_in = '';
        ccResponse.ext_expires_in = '';
        ccResponse.token_type = '';       
        mockData.add(new TestCalloutData(JSON.serialize(ccResponse)));
        
        Test.setMock(HttpCalloutMock.class, new TestCalloutMock(mockData));
        
        Test.startTest();
        PowerBiEmbedManagerGIV.getEmbeddingDataForReport('String', 'String');
        PowerBiEmbedManagerGIV.getPowerBiAccessToken();
        Test.stopTest();
    }
    
    @isTest
    static void callOAuthController(){

        OAuthApp_pbi__c oauth = new OAuthApp_pbi__c();
        oauth.Name = 'Test';
        oauth.Client_Id__c = 'Test';
        oauth.client_secret__c = 'Test';
        oauth.Access_Token_URL__c = 'Test';
        oauth.Resource_URI__c = 'Test';
        oauth.Authorization_URL__c = 'Test';
        insert oauth;

        PageReference myVfPage = Page.FlightServicePrintableView;
        Test.setCurrentPage(myVfPage);
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        ApexPages.currentPage().getParameters().put('code', 'Test');
        Cookie cookie = new Cookie('name', 'value', null, -1, false);
        ApexPages.currentPage().setCookies(new Cookie[]{cookie});

        List<TestCalloutData> mockData = new List<TestCalloutData>();
        OAuthController oAController = new OAuthController();
        oAController.access_token = '';
        oAController.refresh_token = '';
        oAController.expires_on = '';
        oAController.isCallback = true;
        oAController.application_name = 'Test';
        
        mockData.add(new TestCalloutData(JSON.serialize(oAController)));
        
        Test.setMock(HttpCalloutMock.class, new TestCalloutMock(mockData));
        
        Test.startTest();
        oAController.validateCode('a','testURI');
        oAController.getAuthUrl();

        ApexPages.currentPage().getParameters().put('code', 'test');
        oAController.redirectOnCallback(new PageReference('Page.myPage'));

        oAController.refreshAccessToken(new PageReference('Page.myPage'));
        Test.stopTest();
    }













    
}