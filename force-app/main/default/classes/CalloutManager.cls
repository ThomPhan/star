public class CalloutManager {
    public CalloutManager() {

    }

    public class VIPBookingResponse{

        public Decimal ADT;
        public Decimal tierPointsBalance;
        public Decimal casinoPoints;
        public String loyaltyTier;
        public Decimal pointsToNextTier;
        public Integer rank;
        public Decimal pointsToCurrentTier;
        public Integer customerNumber;
        public Integer compPoints;
        public String loyaltyProgram;
    }

    /*
    Httprequest req = new HttpRequest();
    req.setMethod('GET');
    req.setEndpoint('https://seg-integration-apim-dev.azure-api.net/vipbookings/v1/customers/1139');
    req.setHeader('apikey', 'e5bfdc7952914d14b7a90f68cb6f02bb');

    Http http = new Http();        
    HttpResponse response = http.send(req);
    System.debug(response);*/

}