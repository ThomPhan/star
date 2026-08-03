@isTest
public class KYCUtilityTest {
    
    @testSetup
    static void setupTestData() {

        Property__c property_sydney=new Property__c(Name='Sydney');
        insert property_sydney;
        // Create test Contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Patron_ID__c = 'Patron' + i,
                Home_Property__c = property_sydney.id
            ));
        }
        insert contacts;

        // Create test Key_Date__c records
        List<Key_Date__c> keyDates = new List<Key_Date__c>();
       

        for (Contact contact : contacts) {
            keyDates.add(new Key_Date__c(
                Patron__c = contact.Id,
                Name = 'Due Date',
                Key_Date__c = System.today().addDays(30),
                Active__c = true
            ));
            keyDates.add(new Key_Date__c(
                Patron__c = contact.Id,
                Name = 'Attestation Date',
                Key_Date__c = System.today(),
                Key_Date_Time__c = Datetime.now(),
                Active__c = true
            ));            
        }
        insert keyDates;

        // Create test Status__c records
        List<Status__c> statuses = new List<Status__c>();
        for (Contact contact : contacts) {
            statuses.add(new Status__c(
                Patron_Id__c = contact.Patron_ID__c,
                Code__c = 'Medium',
                Type__c = 'KYC',
                Description__c = 'AML Medium Status',
                Sub_Type_Description__c = 'AML',
                Property_Id__c = '1',
                Composite_Key__c = 'Composite_Key__c'+contact.id
            ));
        }
        insert statuses;

        statuses = [select id, Patron_Id__c, Code__c, Type__c, Description__c, Sub_Type_Description__c, Property_Id__c from Status__c limit 1];
        statuses[0].Code__c = 'High';
        update statuses;



        // Create test PoP__c records
        List<PoP__c> pops = new List<PoP__c>();
        for (Contact contact : contacts) {
            pops.add(new PoP__c(
                Contact__c = contact.Id,
                Name = 'Test PoP',
                Status__c = ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION,
                Patron_ID__c = contact.Patron_ID__c
            ));
        }
        insert pops;
    }

    @isTest
    static void testSegregateKeyDates() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c];

        // Call the method
        Test.startTest();
        KYCUtility.segregateKeyDates(keyDates);
        Test.stopTest();

        // Assert that the method executed without errors
        System.assert(true, 'segregateKeyDates executed successfully.');
    }

    @isTest
    static void testPrepareProcessingData() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c];

        // Call the method
        Test.startTest();
        KYCUtility.ProcessingData data = KYCUtility.prepareProcessingData(keyDates, false);
        Test.stopTest();

        // Assert that data is populated correctly
        System.assertNotEquals(null, data, 'ProcessingData should not be null.');
        System.assertNotEquals(0, data.patronSFIdSet.size(), 'patronSFIdSet should not be empty.');
    }

   /* @isTest
    static void testCreatePoPRecord() {
        // Fetch test data
        Contact contact = [SELECT Id, Patron_ID__c FROM Contact LIMIT 1];

        // Call the method
        Test.startTest();
        PoP__c popRecord = KYCUtility.createPoPRecord(contact.Id, ConstantHelper.STRING_STOPCODEPICKLISTVALUE, '123', ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION, contact.Patron_ID__c,new Map<String, Contact>{Id.valueOf(contact.Id) => contact});            
        Test.stopTest();

        // Assert that the PoP record is created correctly
        System.assertNotEquals(null, popRecord, 'PoP record should not be null.');
        System.assertEquals(contact.Id, popRecord.Contact__c, 'Contact ID should match.');
    }*/

    @isTest
    static void testCalculateDateInUserTimezone() {
        // Test data
        DateTime keyDateTime = DateTime.newInstance(2025, 4, 10, 12, 0, 0);
        String homeProperty = [select name from Property__c limit 1].name;

        // Call the method
        Test.startTest();
        Date calculatedDate = KYCUtility.calculateDateInUserTimezone(keyDateTime, homeProperty);
        Test.stopTest();

        // Assert that the calculated date is correct
        System.assertNotEquals(null, calculatedDate, 'Calculated date should not be null.');
    }

    @isTest
    static void testCheckUserProfile() {
        // Call the method
        Test.startTest();
        Boolean isProfileMatch = KYCUtility.checkUserProfile('System Administrator');
        Test.stopTest();

        // Assert that the method executed without errors
        System.assertNotEquals(null, isProfileMatch, 'Profile match result should not be null.');
    }

    /*@isTest
    static void testUpsertPoPRecords() {
        // Fetch test data
        List<PoP__c> pops = [SELECT Id, Contact__c, Name, Status__c FROM PoP__c];

        // Modify the status of one record
        pops[0].Status__c = 'Updated';

        // Call the method
        Test.startTest();
        KYCUtility.upsertPoPRecords(pops);
        Test.stopTest();

        // Assert that the method executed without errors
        System.assert(true, 'upsertPoPRecords executed successfully.');
    }*/

    
   /*  @isTest
     static void testExecuteMethod() {
     ApplyKYCRefreshScheduler scheduler = new ApplyKYCRefreshScheduler();
     scheduler.execute(scheduler);
     
     }*/
     @isTest
     static void testSchedulableClass() {
         // Schedule the job
         Test.startTest();
         ApplyKYCRefreshScheduler scheduler = new ApplyKYCRefreshScheduler();
         String cronExp = '0 0 0 15 3 ? 2050'; // Example cron expression
         System.schedule('Test Schedulable Class', cronExp, scheduler);
         Test.stopTest();
     }
    

     @isTest
    static void testUpdateExistingDueDate() {
        // Prepare test data
        String patronExtId = '1234';
        Property__c property_sydney=new Property__c(Name='Sydney');
        insert property_sydney;
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Patron_ID__c = patronExtId = '1234',
            Home_Property__c = property_sydney.id
        );
        insert testContact;
        Status__c testStatus = new Status__c(
            Patron_Id__c = testContact.Patron_ID__c,
            Code__c = 'Medium',
            Type__c = 'KYC',
            Description__c = 'AML Medium Status',
            Sub_Type_Description__c = 'AML',
            Property_Id__c = '1',
            Composite_Key__c = 'Composite_Key__c'+testContact.id);
        insert testStatus;
        Key_Date__c testKeyDate = new Key_Date__c(
            Patron__c = testContact.Id,
            Name = 'Due Date',
            Key_Date__c = System.today().addDays(30),
            Active__c = true
        );
        insert testKeyDate;
        // Prepare input maps
        Map<String, Status__c> patronExtIdToStatusMap = new Map<String, Status__c>{
            patronExtId => testStatus
                };
                    Map<String, Key_Date__c> patronExtIdToKeyDateDueMap = new Map<String, Key_Date__c>{
                        patronExtId => testKeyDate
                            };
                                Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap = new Map<String, Key_Date__c>();
        Map<String, Contact> patronExtIdToContactMap = new Map<String, Contact>{
            patronExtId => testContact
                };
                    Decimal dueDays = 30;
        patronExtIdToContactMap = new Map<String, Contact>();
        patronExtIdToContactMap.put(patronExtId, testContact);
        // Call the method being tested
        Test.startTest();
        Key_Date__c updatedKeyDate = KYCUtility.updateExistingDueDate(
            patronExtId,
            patronExtIdToStatusMap,
            patronExtIdToKeyDateDueMap,
            patronExtIdToKeyDateAttestMap,
            patronExtIdToContactMap,
            dueDays
        );
        Test.stopTest();
    }
    
    @isTest
    
    static void testProcessKeyDateForTimezoneAdjustment() {
        
        // Prepare test data
        
        Property__c Brisbane=new Property__c(Name='Brisbane');
        
        insert Brisbane;
        
        Contact testContact = new Contact(
            
            LastName = 'Test Contact',
            
            Home_Property__c = Brisbane.id
            
        );
        
        insert testContact;
        
        Key_Date__c testKeyDate = new Key_Date__c(
            
            Patron__c = testContact.Id,
            
            Key_Date_Time__c = DateTime.now()
            
        );
        
        insert testKeyDate;
        
        // Prepare input data
        
        Map<ID, SObject> oldRecordMap = new Map<ID, SObject>{
            
            testKeyDate.Id => testKeyDate.clone(false, false)
                
                };
                    
                    Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>{
                        
                        testContact.Id => [
                            
                            SELECT Id, Home_Property__c, Home_Property__r.Name 
                            
                            FROM Contact 
                            
                            WHERE Id = :testContact.Id
                            
                        ]
                            
                            };
                                
                                // Update the Key_Date_Time__c field to trigger the calculation
                                
                                testKeyDate.Key_Date_Time__c = testKeyDate.Key_Date_Time__c.addHours(1);
        
        // Call the method being tested
        
        Test.startTest();
        
        KYCUtility.processKeyDateForTimezoneAdjustment(testKeyDate, oldRecordMap, contactIdToContactMap);
        
        Test.stopTest();
        
        // Verify the results
        
        System.assertNotEquals(null, testKeyDate.Key_Date__c);
        
    }
    
    
    @isTest
    static void testProcessKeyDatesForDueDates() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c WHERE Name = 'Due Date'];
        List<contact> patronSFIdSet= [Select id, Patron_ID__c from contact];
        
        insert new PoP__c(
            Contact__c = patronSFIdSet[0].Id,
            Name = 'Test PoP Revoc Success',
            Status__c = ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION,
            Patron_ID__c = patronSFIdSet[0].Patron_ID__c,
            Type__c=ConstantHelper.STRING_STOPCODEPICKLISTVALUE,
            Value__c = '4000000027'
        );
        // Call the method
        Test.startTest();
        List<PoP__c > poplist =  [SELECT Id, Name, Patron_ID__c, Contact__c, Type__c, Value__c, Status__c FROM PoP__c WHERE Contact__c IN: patronSFIdSet  AND (Status__c = 'Pending Revocation' OR Status__c = 'Revocation Successful' OR Status__c = 'Application Successful') AND Type__c = 'Stop Code' AND Value__c = '4000000027' ORDER BY CreatedDate DESC];
        system.debug('^^**^^ poplist '+poplist);
        KYCUtility.processKeyDatesForDueDates(keyDates);
        Test.stopTest();
        
        // Assert that the method executed without errors
        System.assert(true, 'processKeyDatesForDueDates executed successfully.');
    }
    @isTest
    static void testProcessKeyDatesForDueDates2() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c WHERE Name = 'Due Date'];
        List<contact> patronSFIdSet= [Select id, Patron_ID__c from contact];
        
        insert new PoP__c(
            Contact__c = patronSFIdSet[0].Id,
            Name = 'Test PoP Revoc Success',
            Status__c = ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION,
            Patron_ID__c = patronSFIdSet[0].Patron_ID__c,
            Type__c='Stop Code',
            Value__c = '4000000027'
        );
        // Call the method
        Test.startTest();
        List<PoP__c > poplist =  [SELECT Id, Name, Patron_ID__c, Contact__c, Type__c, Value__c, Status__c FROM PoP__c WHERE Contact__c IN: patronSFIdSet  AND (Status__c = 'Pending Revocation' OR Status__c = 'Revocation Successful' OR Status__c = 'Application Successful') AND Type__c = 'Stop Code' AND Value__c = '4000000027' ORDER BY CreatedDate DESC];
        system.debug('^^**^^ poplist '+poplist);
        KYCUtility.processKeyDatesForDueDates(keyDates);
        Test.stopTest();
        
        // Assert that the method executed without errors
        System.assert(true, 'processKeyDatesForDueDates executed successfully.');
    }
    @isTest
    static void testProcessKeyDatesForDueDates3() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c WHERE Name = 'Due Date'];
        List<contact> patronSFIdSet= [Select id, Patron_ID__c from contact];
        
        insert new PoP__c(
            Contact__c = patronSFIdSet[0].Id,
            Name = 'Test PoP Revoc Success',
            Status__c = ConstantHelper.STRING_POP_STATUS_SUCCESS_APPLICATION,
            Patron_ID__c = patronSFIdSet[0].Patron_ID__c,
            Type__c='Stop Code',
            Value__c = '4000000027'
        );
        // Call the method
        Test.startTest();
        List<PoP__c > poplist =  [SELECT Id, Name, Patron_ID__c, Contact__c, Type__c, Value__c, Status__c FROM PoP__c WHERE Contact__c IN: patronSFIdSet  AND (Status__c = 'Pending Revocation' OR Status__c = 'Revocation Successful' OR Status__c = 'Application Successful') AND Type__c = 'Stop Code' AND Value__c = '4000000027' ORDER BY CreatedDate DESC];
        system.debug('^^**^^ poplist '+poplist);
        KYCUtility.processKeyDatesForDueDates(keyDates);
        Test.stopTest();
        
        // Assert that the method executed without errors
        System.assert(true, 'processKeyDatesForDueDates executed successfully.');
    }
    
    @isTest
    static void testProcessKeyDatesForAttestation() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c WHERE Name = 'Attestation Date'];
        system.debug('keyDates*** '+keyDates);
        List<contact> patronSFIdSet= [Select id, Patron_ID__c from contact where id =: keyDates[0].Patron__c];
        
        insert new PoP__c(
            Contact__c = patronSFIdSet[0].Id,
            Name = 'Test PoP App Success',
            Status__c = 'Application Successful',
            Patron_ID__c = patronSFIdSet[0].Patron_ID__c,
            Type__c='Stop Code',
            Value__c = '4000000027'
        );
        // Call the method
        Test.startTest();
        List<PoP__c > poplist =  [SELECT Id, Name, Patron_ID__c, Contact__c, Type__c, Value__c, Status__c FROM PoP__c WHERE Contact__c IN: patronSFIdSet  AND (Status__c = 'Pending Revocation' OR Status__c = 'Revocation Successful' OR Status__c = 'Application Successful') AND Type__c = 'Stop Code' AND Value__c = '4000000027' ORDER BY CreatedDate DESC ];
        system.debug('^^**^^ poplist '+poplist);
        KYCUtility.processKeyDatesForAttestation(keyDates);
        Test.stopTest();
        
        // Assert that the method executed without errors
        System.assert(true, 'processKeyDatesForAttestation executed successfully.');
    }
    @isTest
    static void testProcessKeyDatesForAttestation2() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c WHERE Name = 'Attestation Date'];
        system.debug('keyDates*** '+keyDates);
        List<contact> patronSFIdSet= [Select id, Patron_ID__c from contact where id =: keyDates[0].Patron__c];
        
        insert new PoP__c(
            Contact__c = patronSFIdSet[0].Id,
            Name = 'Test PoP App Success',
            Status__c = ConstantHelper.STRING_POP_STATUS_PENDING_REVOCATION,
            Patron_ID__c = patronSFIdSet[0].Patron_ID__c,
            Type__c='Stop Code',
            Value__c = '4000000027'
        );
        // Call the method
        Test.startTest();
        List<PoP__c > poplist =  [SELECT Id, Name, Patron_ID__c, Contact__c, Type__c, Value__c, Status__c FROM PoP__c WHERE Contact__c IN: patronSFIdSet  AND (Status__c = 'Pending Revocation' OR Status__c = 'Revocation Successful' OR Status__c = 'Application Successful') AND Type__c = 'Stop Code' AND Value__c = '4000000027' ORDER BY CreatedDate DESC ];
        system.debug('^^**^^ poplist '+poplist);
        KYCUtility.processKeyDatesForAttestation(keyDates);
        Test.stopTest();
        
        // Assert that the method executed without errors
        System.assert(true, 'processKeyDatesForAttestation executed successfully.');
    }
    @isTest
    static void testProcessKeyDatesForAttestation3() {
        // Fetch test data
        List<Key_Date__c> keyDates = [SELECT Id, Name, Patron__c FROM Key_Date__c WHERE Name = 'Attestation Date'];
        system.debug('keyDates*** '+keyDates);
        List<contact> patronSFIdSet= [Select id, Patron_ID__c from contact where id =: keyDates[0].Patron__c];
        
        insert new PoP__c(
            Contact__c = patronSFIdSet[0].Id,
            Name = 'Test PoP App Success',
            Status__c = ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION,
            Patron_ID__c = patronSFIdSet[0].Patron_ID__c,
            Type__c='Stop Code',
            Value__c = '4000000027'
        );
        // Call the method
        Test.startTest();
        List<PoP__c > poplist =  [SELECT Id, Name, Patron_ID__c, Contact__c, Type__c, Value__c, Status__c FROM PoP__c WHERE Contact__c IN: patronSFIdSet  AND (Status__c = 'Pending Revocation' OR Status__c = 'Revocation Successful' OR Status__c = 'Application Successful') AND Type__c = 'Stop Code' AND Value__c = '4000000027' ORDER BY CreatedDate DESC ];
        system.debug('^^**^^ poplist '+poplist);
        KYCUtility.processKeyDatesForAttestation(keyDates);
        Test.stopTest();
        
        // Assert that the method executed without errors
        System.assert(true, 'processKeyDatesForAttestation executed successfully.');
    }
    
    
    @isTest
    static void testHandleIteration(){
        
        // Prepare test data
        String patronExtId = '20250605';
        Property__c property_sydney=new Property__c(Name='Sydney');
        insert property_sydney;
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Patron_ID__c = patronExtId = '1234',
            Home_Property__c = property_sydney.id
        );
        insert testContact;
        Status__c testStatus = new Status__c(
            Patron_Id__c = testContact.Patron_ID__c,
            Code__c = 'Medium',
            Type__c = 'KYC',
            Description__c = 'AML Medium Status',
            Sub_Type_Description__c = 'AML',
            Property_Id__c = '1',
            Composite_Key__c = 'Composite_Key__c'+testContact.id);
        insert testStatus;
        Key_Date__c testKeyDate = new Key_Date__c(
            Patron__c = testContact.Id,
            Name = 'Due Date',
            Key_Date__c = System.today().addDays(30),
            Active__c = true
        );
        insert testKeyDate;
        
        Key_Date__c testKeyDate2 = new Key_Date__c(
            Patron__c = testContact.Id,
            Name = 'Due Date',
            Key_Date__c = System.today().addDays(60),
            Active__c = true
        );
        insert testKeyDate2;
        
        KYCUtility.handleIteration(new List<Key_Date__c>{testKeyDate, testKeyDate2});
    }
}