public class CompRoomNightDataProvider {
    
    @AuraEnabled(cacheable=true)
    public static JsonResponse runCallOut(String loyaltyId){
        Loyalty__c loyaltyRec = [SELECT Id, Name, Patron__r.Patron_ID__c, Last_Successful_Update__c FROM Loyalty__c WHERE Id = :loyaltyId LIMIT 1];
        Comp_Room_Nights_Detail__mdt compRoomNightsRec= [SELECT Id, Comp_Room_Nights_Cust_Subscription_Key__c, Comp_Room_Nights_Endpoint__c FROM Comp_Room_Nights_Detail__mdt LIMIT 1];
        
        string endpoint = String.valueOf(compRoomNightsRec.Comp_Room_Nights_Endpoint__c);
        string customer_subscription_key = String.valueOf(compRoomNightsRec.Comp_Room_Nights_Cust_Subscription_Key__c);
        string method = 'GET';
        string patronId = loyaltyRec.Patron__r.Patron_ID__c;
        
        http h = new http();
        HttpRequest hr = new HttpRequest();
        
        //set endpoint and method
        hr.setEndpoint(endpoint);
        hr.setHeader('customer-subscription-key', customer_subscription_key);
        hr.setHeader('patronId', patronId);
        hr.setMethod(method);
        
        //send the request
        HttpResponse hResp = new HttpResponse();
        hResp = h.send(hr);
        
        String responseBody = hResp.getBody();
        system.debug('Test: ' + responseBody);
        JsonResponse jr = new JsonResponse();
        if(responseBody != null){
            JsonData jd = (JsonData)Json.deserialize(responseBody, JsonData.class);
            //system.debug('crnEntitlement+crnBalance = ' + jd.responseHeader + ' ' + jd.response);
            //system.debug('monthlyBalances ' + jd.monthlyBalances.month + ', ' + jd.monthlyBalances.year);
            system.debug('Test: ' + jd);
            
            jr = jd.response;	
        }
        return jr;
    }
    
    @AuraEnabled(cacheable=true)
    public static JsonResponse runCallOutSalesConsole(String contactId){
        Loyalty__c loyaltyRec = [SELECT Id, Name, Patron__r.Patron_ID__c, Last_Successful_Update__c FROM Loyalty__c WHERE Patron__c = :contactId LIMIT 1];
        Comp_Room_Nights_Detail__mdt compRoomNightsRec= [SELECT Id, Comp_Room_Nights_Cust_Subscription_Key__c, Comp_Room_Nights_Endpoint__c FROM Comp_Room_Nights_Detail__mdt LIMIT 1];
        
        string endpoint = String.valueOf(compRoomNightsRec.Comp_Room_Nights_Endpoint__c);
        string customer_subscription_key = String.valueOf(compRoomNightsRec.Comp_Room_Nights_Cust_Subscription_Key__c);
        string method = 'GET';
        string patronId = loyaltyRec.Patron__r.Patron_ID__c;
        
        http h = new http();
        HttpRequest hr = new HttpRequest();
        
        //set endpoint and method
        hr.setEndpoint(endpoint);
        hr.setHeader('customer-subscription-key', customer_subscription_key);
        hr.setHeader('patronId', patronId);
        hr.setMethod(method);
        
        //send the request
        HttpResponse hResp = new HttpResponse();
        hResp = h.send(hr);
        
        String responseBody = hResp.getBody();
        system.debug('Test: ' + responseBody);
        JsonResponse jr = new JsonResponse();
        if(responseBody != null){
            JsonData jd = (JsonData)Json.deserialize(responseBody, JsonData.class);
            //system.debug('crnEntitlement+crnBalance = ' + jd.responseHeader + ' ' + jd.response);
            //system.debug('monthlyBalances ' + jd.monthlyBalances.month + ', ' + jd.monthlyBalances.year);
            system.debug('Test: ' + jd);
            
            jr = jd.response;	
        }
        return jr;
    }
    
    @AuraEnabled(cacheable=true)
    public static string getLoyaltyRec(String loyaltyId){
        string formattedDate;
        Loyalty__c loyaltyRec = [SELECT Id, Last_Successful_Update__c, Comp_Room_Night_Entitlement__c, Comp_Room_Night_Used__c, Comp_Room_night_remaining_for_the_Month__c, Comp_Room_Night_Remaining__c FROM Loyalty__c WHERE Id = :loyaltyId LIMIT 1];
        if(loyaltyRec.Last_Successful_Update__c != null){
            if(loyaltyRec.Last_Successful_Update__c.contains('T')){
                formattedDate = DateTime.ValueofGmt(loyaltyRec.Last_Successful_Update__c.replace('T', ' ')).format('dd/MM/yyyy, hh:mm a', + 'Pacific');
            }
            else{
                formattedDate = loyaltyRec.Last_Successful_Update__c;
            }
        }
        
        return formattedDate;
    }
    public class JsonData{
        public JsonResponseHeader responseHeader;
        public JsonResponse response;
    }
    
    public class JsonResponseHeader{
        public string code;
        public string msg;
    }
    
    public class JsonResponse{
        @AuraEnabled
        public string entitlement { get; set; }
        @AuraEnabled
        public string balance { get; set; }
        @AuraEnabled
        public JsonMonthlyBalances[] monthlyBalances { get; set; }
    }
    
    public class JsonMonthlyBalances{
        @AuraEnabled
        public string month;
        @AuraEnabled
        public string year;
        @AuraEnabled
        public string used;
        @AuraEnabled
        public string remaining;
    }
    public static JsonResponse parse(String jsonString) {
        return (JsonResponse)JSON.deserialize(jsonString, JsonResponse.class);
    }
}