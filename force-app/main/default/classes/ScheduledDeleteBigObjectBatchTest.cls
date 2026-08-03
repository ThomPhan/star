@IsTest
public class ScheduledDeleteBigObjectBatchTest {
    
    @testSetup
    static void testDataFactory(){
        
        
        //Database.insertImmediate(conURIEventList);
    }

    static testmethod void executeBatchTest() {

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
        conURIEvent.User__c = 'rhysjohn.delacruz@star.com.au.dev';
        conURIEvent.Platform__c = 'SFX:BROWSER:DESKTOP';
        conURIEvent.OperatingSystem__c = 'WINDOWS';
        conURIEvent.UserType__c = 'Standard';
        conURIEventList.add(conURIEvent);
        
        Test.startTest();
        ScheduledDeleteBigObjectBatch testBatch = new ScheduledDeleteBigObjectBatch(conURIEventList);
        ScheduledDeleteBigObjectBatch.runOriginalConstructor = false;
        Database.executeBatch(testBatch);
        Test.stopTest();
    }
    
    static testmethod void executeTrue(){
        BigObjectCriteria__c testCS = new BigObjectCriteria__c();
        testCS.Event_Date__c = 365;
        UPSERT testCS;
        
        Test.startTest();
        ScheduledDeleteBigObjectBatch.runOriginalConstructor = true;
        Database.executeBatch(new ScheduledDeleteBigObjectBatch());
        Test.stopTest();
    }
}