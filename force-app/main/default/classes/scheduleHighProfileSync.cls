global class scheduleHighProfileSync Implements Schedulable
{
    private String sessionId;

    global  scheduleHighProfileSync(){}
    global void execute(SchedulableContext sc) {
        scheduleHighProfileService();
        
    }
    // Set the sessionId passed in from Exec Anonymous Apex when the job starts
    global scheduleHighProfileSync( String sessionId ) {
        this.sessionId = sessionId;
        //  System.debug('Session ID Inside class '+sessionId);
    }
    
    @future(callout=true)
    public static void scheduleHighProfileService()//String sessionId)
    {
        HighProfileSyncSetting__c hpSetting = HighProfileSyncSetting__c.getOrgDefaults();
        Integer numOfDays = 0;

        if(hpSetting.Num_of_Days__c == null){
            numOfDays = 90;
        }
        else{
            numOfDays = (Integer)hpSetting.Num_of_Days__c;
        }

        // set the session id passed in to a local variable
        //String sId = sessionId;
        DateTime dt = DateTime.now();
        dt = dt.addDays(-numOfDays);
        String dynamicDate = 'AND EventDate >= ' + dt.format('yyyy-MM-dd', 'Australia/Sydney') + 'T00:00:00Z';
        System.debug('Dynamic Date for this Run is: ' + dynamicDate);
        String sId = UserInfo.getSessionId();
        String host = System.Url.getSalesforceBaseUrl().toExternalForm();
        // system.debug('Host : ' +host);
        String url = host + '/services/data/v51.0/async-queries/';
        
        // system.debug('URL : ' +url);
        StaticResource static_resource = [SELECT Id, body,SystemModStamp
                                          FROM StaticResource 
                                          WHERE Name = 'HPQuery'];
        
        String res_json_body = static_resource.body.toString();
        res_json_body = res_json_body.replace('dynamicDate', dynamicDate);
        system.debug('REQUEST Body : '+res_json_body);
        
        HttpResponse response;
        Try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setHeader('Content-type','application/json');
            Request.setHeader('Authorization', 'OAuth ' +sId);
            request.setTimeout(120000);
            // Set the body as a JSON object
            request.setBody(res_json_body);
            response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 201) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus());
                System.debug(response.getBody());
                
            } else {
                System.debug(response.getBody());
                System.debug(response.getStatusCode());
            }
        } 
        catch(System.CalloutException e) 
        {
            ErrorLogger.createLog('ScheduleHighProfileSync','scheduleHighProfileSync',e,null,'Apex Class'); 
            //System.debug('Response : ' +response.getStatusCode());
        }
        
        //return response; method set to void
    }
    
}