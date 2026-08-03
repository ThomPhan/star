@isTest
global class scheduleHighProfileSynctest implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        String host = System.Url.getSalesforceBaseUrl().toExternalForm();
        system.debug('Host : ' +host);
        String url = host + '/services/data/v51.0/async-queries/';
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('HPQuery');  
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"example":"test"}');
        response.setStatusCode(201);
        System.assertEquals(url, req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        system.debug('RESPONSE : ' +response.getStatus());
        return response;
    }
    static  testmethod void testResourceCallout() {
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new scheduleHighProfileSynctest());
        
        scheduleHighProfileSync shp  = new scheduleHighProfileSync(UserInfo.getSessionId());
        System.schedule('scheduleHighProfileSync'+System.now(), '0 0 15 * * ?',  shp);   
     
        scheduleHighProfileSync.scheduleHighProfileService(); 
        //system.debug(response.getStatusCode());
        Test.stopTest();
    }   
    
    
    
    
}