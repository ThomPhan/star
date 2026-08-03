@isTest
public class CompRoomNightDataProviderTest implements HttpCalloutMock {
    
	public HTTPResponse respond(HTTPRequest request){

        CompRoomNightDataProvider.JsonData jsonData = new CompRoomNightDataProvider.JsonData();
        CompRoomNightDataProvider.JsonResponseHeader jsonHeader = new CompRoomNightDataProvider.JsonResponseHeader();
        CompRoomNightDataProvider.JsonResponse jsonResponse = new CompRoomNightDataProvider.JsonResponse();
        List<CompRoomNightDataProvider.JsonMonthlyBalances> jsonMonthlyBalancesList = new List<CompRoomNightDataProvider.JsonMonthlyBalances>();
     
        CompRoomNightDataProvider.JsonMonthlyBalances jsonMonthlyBalances06 = new CompRoomNightDataProvider.JsonMonthlyBalances();
        jsonMonthlyBalances06.month = '06';
        jsonMonthlyBalances06.year = '2022';
        jsonMonthlyBalances06.used = '0';
        jsonMonthlyBalances06.remaining = '0';
        jsonMonthlyBalancesList.add(jsonMonthlyBalances06);

        jsonResponse.monthlyBalances = jsonMonthlyBalancesList;
        jsonResponse.balance = '106';
        jsonResponse.entitlement ='';
        
        jsonHeader.code = '0';
        jsonHeader.msg = 'Success';

		jsonData.responseHeader =   jsonHeader;     
        jsonData.response =   jsonResponse;
        
        //req.requestBody = Blob.valueOf(JSON.serialize(jsonData));   
        
        //Set Mock up  data that will be received on callout during testing 
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type','application/json');
        response.setBody(JSON.serialize(jsonData));
		response.setStatusCode(200);
        response.setStatus('OK');
        
        
        return response;
    }
    @TestSetup
    static void setupData(){
        Contact conRec = new Contact();
        conRec.FirstName = 'John';
        conRec.LastName = 'Smith';
        conRec.email='test@gmail.com';
        conRec.Patron_ID__c ='1001';
        conRec.Source_of_Wealth__c='Test';
        insert conRec;

        Loyalty_Program__c prog = new Loyalty_Program__c(Name='Gold Membership');
        insert prog;

        Loyalty__c loyaltyObj = new Loyalty__c();

        loyaltyObj.Points_to_Retain_Current_Tier__c = 90;
        loyaltyObj.Tier_Review_Date__c = System.Today() +30;
        loyaltyObj.Points_To_Next_Tier__c = 800;

        loyaltyObj.Patron__c = conRec.Id;
        loyaltyObj.Tier__c = 'Silver';
        loyaltyObj.Next_Tier__c= 'Gold';
        loyaltyObj.Next_Tier__c= 'Gold';
        loyaltyObj.Loyalty_Program__c= prog.Id;
        loyaltyObj.Last_Successful_Update__c= '2022-05-25T02:04:28.557+0';


        loyaltyObj.currentTierImage__c = 'Silver.png';
        loyaltyObj.NextTierImage__c = 'Gold.png';
        loyaltyObj.Review_CountdownImage__c = 'silverGoldCountDown.png';

        insert loyaltyObj;
    }
	@isTest
    static void runCallOutTest(){
        Contact conRec = [SELECT Id, Name FROM Contact WHERE Patron_ID__c = '1001'  LIMIT 1];
        Loyalty__c loyaltyObj = [SELECT Id, Name, Patron__r.Patron_ID__c, Last_Successful_Update__c FROM Loyalty__c WHERE Patron__c =:conRec.Id LIMIT 1];
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new CompRoomNightDataProviderTest());
        CompRoomNightDataProvider.runCallOut(loyaltyObj.Id);
       
        system.assertEquals(conRec.Id, loyaltyObj.Patron__c, 'Error in Patron');
        Test.stopTest();

    }
    @isTest
    static void runCallOutTestSalesConsole(){
        Contact conRec = [SELECT Id, Name FROM Contact WHERE Patron_ID__c = '1001'  LIMIT 1];
        Loyalty__c loyaltyObj = [SELECT Id, Name, Patron__r.Patron_ID__c, Last_Successful_Update__c FROM Loyalty__c WHERE Patron__c =:conRec.Id LIMIT 1];
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new CompRoomNightDataProviderTest());
        CompRoomNightDataProvider.runCallOutSalesConsole(conRec.Id);
       
        system.assertEquals(conRec.Id, loyaltyObj.Patron__c, 'Error in Patron');
        Test.stopTest();

    }
    @isTest
    static void loyaltyTest(){
        Contact conRec = [SELECT Id, Name FROM Contact WHERE Patron_ID__c = '1001'  LIMIT 1];
        Loyalty__c loyaltyObj = [SELECT Id, Name, Patron__r.Patron_ID__c, Last_Successful_Update__c FROM Loyalty__c WHERE Patron__c =:conRec.Id LIMIT 1];
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new CompRoomNightDataProviderTest());
       CompRoomNightDataProvider.getLoyaltyRec(loyaltyObj.Id);
        system.assertEquals('2022-05-25T02:04:28.557+0', loyaltyObj.Last_Successful_Update__c, 'Error in Last Successful update');
        Test.stopTest();

    }
}