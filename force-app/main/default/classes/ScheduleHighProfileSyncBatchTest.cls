@IsTest
public class ScheduleHighProfileSyncBatchTest {

    @isTest
    static void executeBatchTest() {

        Test.startTest();
            
        List<LightningUriEvent> lightningUriEventList = new List<LightningUriEvent>(); 

        LightningUriEvent testEvent = new LightningUriEvent();
        testEvent.EventDate = Date.today();
        testEvent.QueriedEntities = 'Contact';

        lightningUriEventList.add(testEvent);
        
        Contact testContact = new Contact();
        testContact.LastName = 'TestClass';
        INSERT testContact;

        BigObjectCriteria__c testCS = new BigObjectCriteria__c();
        testCS.Event_Date__c = 365;
        UPSERT testCS;
        
        List<ContactLightningURIEvent__b> conURIEventList = new List<ContactLightningURIEvent__b>();

        ContactLightningURIEvent__b conURIEvent = new ContactLightningURIEvent__b();
        conURIEvent.EventDate__c = System.now();
        conURIEvent.Operation__c = 'Read';
        conURIEvent.EventIdentifier__c = '6b3b1419-7c19-4fb5-89d5-521cace58595';
        conURIEvent.QueriedEntities__c = 'Contact';
        conURIEvent.RecordId__c = testContact.Id;
        conURIEvent.IPAddress__c = '192.168.1.1';
        conURIEvent.User__c = 'testuser@star.com.au.dev';
        conURIEvent.Platform__c = 'SFX:BROWSER:DESKTOP';
        conURIEvent.OperatingSystem__c = 'WINDOWS';
        conURIEvent.UserType__c = 'Standard';
        conURIEventList.add(conURIEvent);

        ScheduleHighProfileSyncBatch.runOriginalConstructor = false;
        Id jobId = Database.executeBatch(new ScheduleHighProfileSyncBatch(lightningUriEventList));
        Test.stopTest();
    }

    @isTest
    static void executeBatchTest2() {

        Contact testContact = new Contact();
        testContact.LastName = 'TestClass';
        INSERT testContact;

        BigObjectCriteria__c testCS = new BigObjectCriteria__c();
        testCS.Event_Date__c = 365;
        UPSERT testCS;
        
        List<ContactLightningURIEvent__b> conURIEventList = new List<ContactLightningURIEvent__b>();

        ContactLightningURIEvent__b conURIEvent = new ContactLightningURIEvent__b();
        conURIEvent.EventDate__c = System.now();
        conURIEvent.Operation__c = 'Read';
        conURIEvent.EventIdentifier__c = '6b3b1419-7c19-4fb5-89d5-521cace58595';
        conURIEvent.QueriedEntities__c = 'Contact';
        conURIEvent.RecordId__c = testContact.Id;
        conURIEvent.IPAddress__c = '192.168.1.1';
        conURIEvent.User__c = 'testuser@star.com.au.dev';
        conURIEvent.Platform__c = 'SFX:BROWSER:DESKTOP';
        conURIEvent.OperatingSystem__c = 'WINDOWS';
        conURIEvent.UserType__c = 'Standard';
        conURIEventList.add(conURIEvent);
        
        Test.startTest();
        ScheduleHighProfileSyncBatch.runOriginalConstructor = true;
        Id jobId = Database.executeBatch(new ScheduleHighProfileSyncBatch());
        Test.stopTest();
    }
}