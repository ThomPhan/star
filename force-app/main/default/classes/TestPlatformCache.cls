public class TestPlatformCache {
    public TestPlatformCache() {
    }

    public static void doCache(){
        Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.VIPBooking');

        if(orgPartition.get('test') != null){
            system.debug(orgPartition.get('test'));
            System.debug('Pass Cache');
        }
        else{

            Httprequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint('https://seg-integration-apim-dev.azure-api.net/vipbookings/v1/customers/1139');
            req.setHeader('apikey', 'e5bfdc7952914d14b7a90f68cb6f02bb');

            Http http = new Http();        
            HttpResponse response = http.send(req);
            System.debug(response.getBody());
            orgPartition.put('test', response.getBody());
            System.debug('Not Cache');
        }
    }

    @future
    public static void cacheFuture(){

        Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.VIPBooking');
        String temp = String.valueOf(orgPartition.get('test'));
            
        for(Integer x = 0; x <= 50000; x++){

            orgPartition.put('test'+x, temp);
        }
    }
}