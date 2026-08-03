/*
 * @Class Name  : BookingServiceTriggerHandler
 * @Summary     : Helper class for the 'BookingServiceTrigger' trigger 
 * @author      : Simplus
 * @Description : This class contains the logic when creating Service Records
 * @version     : $Revision: 1.0 $, $Date: 2022-02-28
 *                2.0 1/18/2023 - Commented out methods since VIP Booking will not be used anymore
*/
@isTest
public class BookingServiceTriggerHandlerTest {
    @testSetup
    static void testDataFactory(){
        Contact testContact = TestDataFactory.createSingleContact('TestClass');   
        
        Service__c limoService = new Service__c();
        limoService.Property__c = 'Sydney';
        limoService.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Limo Booking');
        limoService.Booking_Date_and_Time__c = System.today();
        INSERT limoService;   
    }

    @isTest static void testAmendmentUpdate(){
        Service__c testServiceRest = new Service__c();
        testServiceRest.Property__c = 'Sydney';
        testServiceRest.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Restaurant Booking');
        testServiceRest.Booking_Date_and_Time__c = System.today();
        INSERT testServiceRest;
        
        test.startTest();
        
        testServiceRest.Restaurant_Booking_Status__c = 'Confirmed';
        testServiceRest.Pax__c = 15;
        testServiceRest.Booking_Date_and_Time__c = System.today()+1;
        update testServiceRest;
        test.stopTest();
        
        Service__c testServiceRec = [SELECT Id, Restaurant_Booking_Status__c FROM Service__c WHERE Id =: testServiceRest.Id];
        System.assertEquals('Amendment', testServiceRec.Restaurant_Booking_Status__c);
    }

    @isTest static void testAmendmentUpdate2(){
        Service__c testServiceRest = new Service__c();
        testServiceRest.Property__c = 'Sydney';
        testServiceRest.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Flight Booking');
        testServiceRest.Booking_Date_and_Time__c = System.today();
        testServiceRest.Depart_Date_and_Time__c = System.today();
        testServiceRest.Returning_Date_and_Time__c = System.today();
        INSERT testServiceRest;
        
        test.startTest();
        
        testServiceRest.Flight_Booking_Status__c = 'Confirmed';
        testServiceRest.Passport_Number__c = '1234';
        testServiceRest.Depart_Date_and_Time__c = System.today()+1;
        testServiceRest.Returning_Date_and_Time__c = System.today()+1;
        testServiceRest.Flight_Region__c = 'Domestic';
        testServiceRest.Flying_to__c = 'Sydney';
        testServiceRest.Flying_from__c = 'Melbourne';
        testServiceRest.One_way_OR_Return__c = 'One-way';
        update testServiceRest;
        test.stopTest();
        
        Service__c testServiceRec = [SELECT Id, Flight_Booking_Status__c FROM Service__c WHERE Id =: testServiceRest.Id];
        System.assertEquals('Amendment', testServiceRec.Flight_Booking_Status__c);
    }

    @isTest static void testAmendmentUpdate3(){
        Service__c testServiceRest = new Service__c();
        testServiceRest.Property__c = 'Sydney';
        testServiceRest.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Hotel Booking');
        testServiceRest.Booking_Date_and_Time__c = System.today();
        testServiceRest.Arrival_Date__c = Date.today();
        testServiceRest.Departure_Date__c = Date.today()+5;
        INSERT testServiceRest;
        
        test.startTest();
        
        testServiceRest.Hotel_Booking_Status__c = 'Confirmed';
        testServiceRest.Arrival_Date__c = System.today() + 1;
        testServiceRest.Hotel_Confirmation_Number__c = 'TC001';
        testServiceRest.Hotel__c = 'SYD - The Star Grand';
        testServiceRest.Special_Request__c = 'ADP – International Adaptors';
        testServiceRest.MOP_Status__c = 'CALL REP';
        update testServiceRest;
        test.stopTest();
        
        Service__c testServiceRec = [SELECT Id, Hotel_Booking_Status__c FROM Service__c WHERE Id =: testServiceRest.Id];
        System.assertEquals('Amendment', testServiceRec.Hotel_Booking_Status__c);
    }

    @isTest static void testAmendmentUpdate4(){
        Service__c testServiceRest = new Service__c();
        testServiceRest.Property__c = 'Sydney';
        testServiceRest.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Limo Booking');
        testServiceRest.Booking_Date_and_Time__c = System.today();
        testServiceRest.Pick_Up_Date_and_Time__c = System.today();
        INSERT testServiceRest;
        
        test.startTest();
        
        testServiceRest.Limo_Booking_Status__c = 'Confirmed';
        testServiceRest.Pax__c = 10;
        testServiceRest.Pick_Up_Date_and_Time__c = System.today()+1;
        testServiceRest.Pick_Up_Location__c = 'The Star Grand';
        testServiceRest.Drop_Off_Location__c = 'The Star Residences';
        update testServiceRest;
        test.stopTest();
        
        Service__c testServiceRec = [SELECT Id, Limo_Booking_Status__c FROM Service__c WHERE Id =: testServiceRest.Id];
        System.assertEquals('Amendment', testServiceRec.Limo_Booking_Status__c);
    }
    
    @isTest static void testgetServiceRecord(){
        Service__c testServiceRest = new Service__c();
        testServiceRest.Property__c = 'Sydney';
        testServiceRest.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Hotel Booking');
        testServiceRest.Booking_Date_and_Time__c = System.today();
        testServiceRest.Arrival_Date__c = Date.today();
        testServiceRest.Departure_Date__c = Date.today()+5;
        INSERT testServiceRest;
        
        test.startTest();
        
        Service__c testServiceRec = BookingServiceTriggerHandler.getServiceRecord(testServiceRest.Id);
        
        update testServiceRest;
        test.stopTest();
        
        System.assertEquals('Sydney', testServiceRec.Property__c);
    }

    @isTest
    static void testStaticDateInsert(){

        Test.startTest();

        List<Service__c> sList = new List<Service__c>();

        Service__c testServiceLimo = new Service__c();
        testServiceLimo.Property__c = 'Sydney';
        testServiceLimo.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Limo Booking');
        testServiceLimo.Pick_Up_Date_and_Time__c = System.today();
        sList.add(testServiceLimo);

        Service__c testServiceFlight = new Service__c();
        testServiceFlight.Property__c = 'Sydney';
        testServiceFlight.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Flight Booking');
        testServiceFlight.Depart_Date_and_Time__c = System.today();
        testServiceFlight.Arrival_Date__c = System.today()+1;
        sList.add(testServiceFlight);

        Service__c testServiceRest = new Service__c();
        testServiceRest.Property__c = 'Sydney';
        testServiceRest.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Restaurant Booking');
        testServiceRest.Booking_Date_and_Time__c = System.today()+2;
        sList.add(testServiceRest);

        Service__c testServiceLimo2 = new Service__c();
        testServiceLimo2.Property__c = 'Brisbane';
        testServiceLimo2.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Limo Booking');
        testServiceLimo2.Pick_Up_Date_and_Time__c = System.today()+3;
        sList.add(testServiceLimo2);
        //update testServiceLimo2;

        Service__c testServiceLimo3 = new Service__c();
        testServiceLimo3.Property__c = 'Gold Coast';
        testServiceLimo3.RecordTypeId = BookingServiceTriggerHandler.returnRecordTypeId('Limo Booking');
        testServiceLimo3.Pick_Up_Date_and_Time__c = System.today()+4;
        sList.add(testServiceLimo3);
        //update testServiceLimo3;

        insert sList;
        update testServiceFlight;
        update testServiceRest;
        update testServiceLimo2;
        update testServiceLimo3;
        Test.stopTest();
    }
}