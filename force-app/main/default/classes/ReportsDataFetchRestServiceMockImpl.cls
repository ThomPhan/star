/**
 * @description       : Mock class for ReportsDataFetchRestService
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
@isTest
global class ReportsDataFetchRestServiceMockImpl implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        res.setStatusCode(200);
        ReportDataFetchRestResponseWrapper resWrapper = new ReportDataFetchRestResponseWrapper();
        resWrapper.totalSize = 1;
        resWrapper.done = true;
        resWrapper.records = new List<ReportDataFetchRestResponseWrapper.Records>();
        ReportDataFetchRestResponseWrapper.Records recData = new ReportDataFetchRestResponseWrapper.Records();
        
        recData.expr0 = 242424;
        recData.attributes = new ReportDataFetchRestResponseWrapper.Attributes();
        recData.attributes.type_Z = 'sum';
        resWrapper.records.add(recData);
        res.setBody(JSON.serialize(resWrapper));
        return res;
    }
}