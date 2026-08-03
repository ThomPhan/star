public class WhatsOnDetailPageHandler {
    public static String responseData ='';
    @Auraenabled
    public Static String getEvents(){
        try {
            Portal_Client_Credentials__mdt content = [Select Id,Client_ID__c,Client_Secret__c,Endpoint_URL__c,x_seg_clientid__c from Portal_Client_Credentials__mdt where MasterLabel = 'Content API'];
            HTTP h = new HTTP();
            HTTPRequest req = new HTTPRequest();
            req.setEndPoint(content.Endpoint_URL__c);
            req.setmethod('GET');
            req.setHeader('x-seg-clientid',content.x_seg_clientid__c);
            req.setHeader('Accept','application/json;version=1.0.0');
            HTTPResponse res = h.send(req);
            responseData = res.getBody();
            system.debug('Whats On Data '+res.getBody());
            return res.getBody();
        } catch (Exception e) {
            return null;
        }
    }
    @Auraenabled
    public Static String getEventDetailsOnClick(){
        String onClickResponse = '';
        if(responseData != ''){
            onClickResponse = responseData;
        }else {
            onClickResponse = getEvents();
        }
        return onClickResponse;
    }
}