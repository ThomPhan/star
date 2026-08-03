public class PortalPASComponentHandler {
    @AuraEnabled
    public String accesstoken = '';
    
    @AuraEnabled
    public static object generatePAS(String year,String month){
        Id uId = UserInfo.getUserId();
        object exportId;
        Portal_Client_Credentials__mdt creds = [Select Id,Client_ID__c,Client_Secret__c,Endpoint_URL__c,x_seg_clientid__c from Portal_Client_Credentials__mdt where MasterLabel = 'PAS Export'];
        User us = [select Id,ContactId,token__c,token_a__c from User where Id =:uId];
        
        
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('POST');
        req1.setHeader('x-seg-clientid','Web');
        req1.setHeader('Content-Type','application/json');
        req1.setHeader('x-id-token',us.token__c);
        req1.setEndpoint(creds.Endpoint_URL__c);
        req1.setHeader('Authorization', 'Bearer ' + us.token_a__c);
        req1.setBody('{"year": '+year+',"month": '+month+'}');
        
        System.debug('POST');
        System.debug('x-seg-clientid -> ' + 'Web');
        System.debug('body -> ' + '{"year": '+year+',"month": '+month+'}');
        System.debug('x-id-token -> ' + us.token__c );
        System.debug('Authorization '+' Bearer  -> ' + us.token_a__c);
        System.debug('@@@@@req1  -> ' + req1 );
        
        Http http1 = new Http();
        try{
            HTTPResponse response1 = http1.send(req1);
            System.debug('Body ' + response1.getBody());
            Map<String, object> authMap1 = (Map<String, object>) JSON.deserializeUntyped(response1.getBody());
            exportId = authMap1.get('id');
            System.debug('Body ' + exportId);       
        }catch (Exception e){
			//execute the Error Logger object
			ErrorLogger.createLog('PortalPASComponentHandler', 'generatePAS', e, '', 'Apex Class');
		}
        
        return exportId;
    }

    @AuraEnabled
    public static String getPASPDF(object exportId){
        Id uId = UserInfo.getUserId();
        Portal_Client_Credentials__mdt credStatus = [Select Id,Client_ID__c,Client_Secret__c,Endpoint_URL__c,x_seg_clientid__c from Portal_Client_Credentials__mdt where MasterLabel = 'PAS Export Status'];
        Portal_Client_Credentials__mdt credPDF = [Select Id,Client_ID__c,Client_Secret__c,Endpoint_URL__c,x_seg_clientid__c from Portal_Client_Credentials__mdt where MasterLabel = 'PAS Export PDF'];
        User us = [select Id,ContactId,token__c,token_a__c from User where Id =:uId];
        object status;
        Blob responseDetails;
        String resBody;
        
        String endpointStatus = credStatus.Endpoint_URL__c.replace('exportId', (String)exportId);
        String endpointPDF = credPDF.Endpoint_URL__c.replace('exportId', (String)exportId);
        system.debug('endpoint==>'+endpointStatus+endpointPDF);
        HttpRequest req2 = new HttpRequest();
        HTTPResponse response3;
        req2.setMethod('GET');
        req2.setHeader('x-seg-clientid','Web');
        req2.setHeader('x-id-token',us.token__c);
        req2.setEndpoint(endpointStatus);
        req2.setHeader('Authorization', 'Bearer ' + us.token_a__c);
        req2.setTimeout(3*1000);
        Http http2 = new Http();
        try{
            HTTPResponse response2 = http2.send(req2);
            Map<String, object> statusList = (Map<String, object>) JSON.deserializeUntyped(response2.getBody());
            status = statusList.get('status');
            System.debug('status ' + status);
            if(status == 'Succeeded'){
                System.debug('Body ' + status);
                
                HttpRequest req3 = new HttpRequest();
                req3.setMethod('GET');
                req3.setHeader('Content-Type','application/pdf');
                req3.setHeader('x-seg-clientid','Web');
                req3.setHeader('x-id-token',us.token__c);
                req3.setEndpoint(endpointPDF);
                req3.setHeader('Authorization', 'Bearer ' + us.token_a__c);
                Http http3 = new Http();
                response3 = http3.send(req3);
                system.debug('response ==>'+response3.getBody());
                system.debug('response blob===>'+response3.getBodyAsBlob());
                responseDetails = response3.getBodyAsBlob();
                resBody = EncodingUtil.base64Encode(responseDetails);
                system.debug('response encode==>'+resBody);
                System.debug('Body ' + responseDetails);
            }
        }catch (Exception e){
		//execute the Error Logger object
		ErrorLogger.createLog('PortalPASComponentHandler', 'getPASPDF', e, '', 'Apex Class');
		}
        return resBody;
    }

    @AuraEnabled(cacheable=true)
    public static void downloadPDF(Blob responseDetails){
        system.debug('BLob'+responseDetails);

    }

    static void sleep(Long milliseconds){
        Integer start = System.Now().millisecond();
        while(System.now().millisecond() < start + milliseconds) {
        }
    }
}