public class PortalFAQHandler {
    @AuraEnabled
    public static String getFAQDetails(){
        String responseData;
        Portal_Client_Credentials__mdt faq = [Select Id,Client_ID__c,Client_Secret__c,Endpoint_URL__c,x_seg_clientid__c from Portal_Client_Credentials__mdt where MasterLabel = 'FAQ API'];
        HTTP h = new HTTP();
        HTTPRequest req = new HTTPRequest();
        req.setEndPoint(faq.Endpoint_URL__c);
        req.setHeader('Accept', 'application/json; version=1.0.0');
        req.setHeader('x-seg-clientid',faq.x_seg_clientid__c);
        req.setmethod('GET');
        try{
            HTTPResponse res = h.send(req);
            responseData = res.getBody();
        }catch (Exception e){
            //execute the Error Logger object
            ErrorLogger.createLog('PortalFAQHandler', 'getFAQDetails', e, '', 'Apex Class');
        }
            
        return responseData;
    }
}