@isTest
global class HttpCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"access_token":"243-sd3hh","id":"014drr45hd738","status":"Succeeded"}');
        response.setStatusCode(200);
        return response; 
    }
}