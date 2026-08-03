/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public with sharing class ReportsDataFetchRestService {
    
    public static Decimal getAggregateDataFromMTDYTDByField( String fieldName,String sessionId){
        try{
            String endPoint = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v44.0/query/?q=SELECT+sum(' + fieldName + ')+from+MTDYTD_Trend_Data__c';
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            system.debug(res.getBody());
            if( res.getStatusCode() == 200 ){
               
                ReportDataFetchRestResponseWrapper result = (ReportDataFetchRestResponseWrapper)JSON.deserialize(res.getBody(), ReportDataFetchRestResponseWrapper.class);
    
                if( result != null){
                    return result.records[0].expr0 != null?result.records[0].expr0:0;
                }
            }
            return 0;  
        }
        catch(Exception e){
            system.debug( e.getMessage() + ' '+ e.getCause() + ' ' + e.getStackTraceString());
            ErrorLogger.createLog('ReportsDataFetchRestService','getAggregateDataFromMTDYTDByField',e,null,'Apex Class'); 
            throw e;
        }
    }

}