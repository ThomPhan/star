@isTest
public class SendApprovalTest {
    static testmethod void testGroup(){
        test.startTest();
        List<Group> testGroup = SendApproval.getAllPublicGroups();
        System.assert(testGroup != NULL);
        test.stopTest();
    }
    
    static testmethod void testGroupMembers(){
        List<Group> testGroup = SendApproval.getAllPublicGroups();
        test.startTest();
        List<User> testUsers = SendApproval.getAllGroupMembers(testGroup[0].Id);
		System.assert(testUsers != NULL);
        test.stopTest();
    }
    
    static testmethod void testSendApproval(){
        Contact testContact = TestDataFactory.createSingleContact('TestClass');
        Id testUser = UserInfo.getUserId();
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
        
        INSERT firstTrip;
        
        Property__c testProperty = new Property__c();
        testProperty.Name = 'Test Property';
        
        INSERT testProperty;
        
        Program__c testProgram = new Program__c();
        testProgram.Property__c = testProperty.Id;
        testProgram.Name = 'Test Program';
        
        INSERT testProgram;
        
        Residency_Checklist__c testRC = new Residency_Checklist__c();
        testRC.Trip__c = firstTrip.Id;
        testRC.Program__c = testProgram.Id;
        
        INSERT testRC;
        
        SendApproval.submitAndProcessApprovalRequest(testRC.Id, testUser, 'Residency_Checklist_Approval');
        test.stopTest();
    }
}