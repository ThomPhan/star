@isTest
public class FlightServiceExtractTest {
    @testSetup
    static void testDataFactory(){
        Contact testContact = TestDataFactory.createSingleContact('TestClass');
        
        VIP_Booking__c testVipBooking = new VIP_Booking__c();
        testVipBooking.Contact__c = testContact.Id;
        testVipBooking.Property__c = 'Sydney';
        INSERT testVipBooking;
        
    }
    static testmethod void callFlightServiceExtract(){
        VIP_Booking__c testBooking = [SELECT Id, Booking_Start_Date__c FROM VIP_Booking__c LIMIT 1];
        
        Service__c testServiceFl = new Service__c();
        testServiceFl.VIP_Booking__c = testBooking.Id;
        testServiceFl.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Flight Booking');
        testServiceFl.Property__c = 'Sydney';
        testServiceFl.Depart_Date_and_Time__c = System.today();
        INSERT testServiceFl;
        
        
        Test.StartTest(); 
        ApexPages.currentPage().getParameters().put('id',testServiceFl.Id);  
        ApexPages.StandardController sc = new ApexPages.StandardController(testServiceFl);
        FlightServiceExtract flightserviceRec = new FlightServiceExtract(sc);
        flightserviceRec.getOtherTraveller();
        flightserviceRec.getPatronDetails();
        flightserviceRec.getDevice();
        
        Test.StopTest();
        
    }
}