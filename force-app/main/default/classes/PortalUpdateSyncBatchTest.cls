@isTest
private class PortalUpdateSyncBatchTest {
    static testMethod void testme(){
        Contact con = new Contact();
        con.FirstName = 'Test First';
        con.LastName = 'Test last';
        con.Portal_Email_Updated_Time__c = System.now().addHours(-2);
        con.Portal_Mobile_Updated_Time__c = System.now().addHours(-2);
        insert con;
        Test.startTest();
        PortalUpdateSyncBatch ba= new PortalUpdateSyncBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
        Contact con1 = [select Id,Portal_Email_Update_Sync_Wait__c, Portal_Email_Updated_Time__c, Portal_Mobile_Update_Sync_Wait__c, Portal_Mobile_Updated_Time__c from Contact where id=:con.Id];
        system.assertEquals(null, con1.Portal_Email_Updated_Time__c);
        
        SchedulableContext sc = null;
        PortalUpdateSyncBatchSchedule tsc = new PortalUpdateSyncBatchSchedule();
        tsc.execute(sc);
    }
}