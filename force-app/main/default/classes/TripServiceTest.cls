@isTest
public class TripServiceTest {
    @testSetup
    static void testDataFactory(){
        Contact testContact = TestDataFactory.createSingleContact('TestClass');
        TestDataFactory.createUser('TSEG CRM Manager', 'Management');
    }
    
    static testmethod void countTripDurationInsertTest(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Date dateToday = System.today();
        List<Trip__c> tripList = new List<Trip__c>();
        
        test.startTest();
        
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        tripList.add(firstTrip);
        
        Trip__c secondTrip = new Trip__c();
        secondTrip.Contact__c = testContact.Id;
        secondTrip.Entry_State__c = 'QLD';
        secondTrip.Entry_Date__c = firstTrip.Exit_Date__c;
        secondTrip.Exit_Date__c = secondTrip.Entry_Date__c.addDays(14);
        secondTrip.Cancelled__c = FALSE;
        secondTrip.is_within_365_days__c = TRUE;
        
        tripList.add(secondTrip);
        
        INSERT tripList;
        
        test.stopTest();
        System.assertEquals(secondTrip.Entry_Date__c, firstTrip.Exit_Date__c);
        Contact assertContact = [SELECT Id, Overlapping_Days__c FROM Contact WHERE Id =: testContact.Id];
        System.assertEquals(assertContact.Id, testContact.Id);
        System.assertEquals(assertContact.Overlapping_Days__c, 1);
    }
    
    static testmethod void countTripDurationUpdateTest(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testUser@starTest.com' LIMIT 1];
        Date dateToday = System.today();
        List<Trip__c> tripList = new List<Trip__c>();
        
        testContact.OwnerId = testUser.Id;
        update testContact; 
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        tripList.add(firstTrip);
        
        Trip__c secondTrip = new Trip__c();
        secondTrip.Contact__c = testContact.Id;
        secondTrip.Entry_State__c = 'QLD';
        secondTrip.Entry_Date__c = dateToday;
        secondTrip.Exit_Date__c = secondTrip.Entry_Date__c.addDays(14);
        secondTrip.Cancelled__c = FALSE;
        secondTrip.is_within_365_days__c = TRUE;
        
        tripList.add(secondTrip);
        
        INSERT tripList;
        
        Trip__c updateTrip = [SELECT Id, Entry_Date__c FROM Trip__c WHERE Id =: secondTrip.Id];
        
        test.startTest();
            System.runAs(testUser){
                updateTrip.Entry_Date__c = firstTrip.Exit_Date__c;
                UPDATE updateTrip;
            }
        test.stopTest();
        
        System.assertEquals(updateTrip.Entry_Date__c, firstTrip.Exit_Date__c);
        Contact assertContact = [SELECT Id, Overlapping_Days__c FROM Contact WHERE Id =: testContact.Id];
        System.assertEquals(assertContact.Id, testContact.Id);
        System.assertEquals(assertContact.Overlapping_Days__c, 1);
    }
    
    static testmethod void validateDuplicateTripRecord(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Date dateToday = System.today();
        
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        INSERT firstTrip;
        
        test.startTest();
        
        try{ 
            Trip__c secondTrip = new Trip__c();
            secondTrip.Contact__c = testContact.Id;
            secondTrip.Entry_State__c = 'NSW';
            secondTrip.Entry_Date__c = dateToday;
            secondTrip.Exit_Date__c = secondTrip.Entry_Date__c.addDays(14);
            secondTrip.Cancelled__c = FALSE;
            secondTrip.is_within_365_days__c = TRUE;
            
            INSERT secondTrip;    
        }catch(Exception e){
            System.assert(e.getMessage().contains('Duplicate or overlap trip with the same entry state and entry date'));
        }

        test.stopTest();
    }
    
    static testmethod void validateDuplicateTripRecordUpdate(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Date dateToday = System.today();
        
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        INSERT firstTrip;
        
        Trip__c secondTrip = new Trip__c();
        secondTrip.Contact__c = testContact.Id;
        secondTrip.Entry_State__c = 'QLD';
        secondTrip.Entry_Date__c = dateToday;
        secondTrip.Exit_Date__c = secondTrip.Entry_Date__c.addDays(14);
        secondTrip.Cancelled__c = FALSE;
        secondTrip.is_within_365_days__c = TRUE;
        
        INSERT secondTrip;   
        
        test.startTest();
        
        try{ 
            Trip__c dupeTrip = [SELECT Id, Entry_State__c FROM Trip__c WHERE Entry_State__c = 'QLD' AND Contact__c =: testContact.Id];
            dupeTrip.Entry_State__c = 'NSW';
            UPDATE dupeTrip;
        }catch(Exception e){
            System.assert(e.getMessage().contains('Duplicate or overlap trip with the same entry state and entry date'));
        }

        test.stopTest();
    }
    
    static testmethod void tripCancellationValidation(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Date dateToday = System.today();
        
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        INSERT firstTrip;
        
        Residency_Checklist__c testRC = new Residency_Checklist__c();
        testRC.Trip__c = firstTrip.Id;
        testRC.Approval_Status__c = 'Rejected';
        
        INSERT testRC;
        
        test.startTest();
        Trip__c testTrip = [SELECT Id, Cancelled__c FROM Trip__c WHERE Entry_State__c = 'NSW' AND Contact__c =: testContact.Id];
        testTrip.Cancelled__c = TRUE;
        
        UPDATE testTrip;
        System.assert(testTrip.Cancelled__c);
        test.stopTest();
    }
    
    static testmethod void countTripDurationDeleteTest(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testUser@starTest.com' LIMIT 1];
        Date dateToday = System.today();
        List<Trip__c> tripList = new List<Trip__c>();
        
        testContact.OwnerId = testUser.Id;
        update testContact; 
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        tripList.add(firstTrip);
        
        Trip__c secondTrip = new Trip__c();
        secondTrip.Contact__c = testContact.Id;
        secondTrip.Entry_State__c = 'QLD';
        secondTrip.Entry_Date__c = dateToday;
        secondTrip.Exit_Date__c = dateToday.addDays(7);
        secondTrip.Cancelled__c = FALSE;
        secondTrip.is_within_365_days__c = TRUE;
        
        tripList.add(secondTrip);
        
        INSERT tripList;
        
        test.startTest();
            System.runAs(testUser){
                DELETE secondTrip;
            }
        test.stopTest();
        
        Contact assertContact = [SELECT Id, Overlapping_Days__c FROM Contact WHERE Id =: testContact.Id];
        System.assertEquals(assertContact.Id, testContact.Id);
        System.assertEquals(assertContact.Overlapping_Days__c, 0);
    }
}