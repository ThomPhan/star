@IsTest
public class PortalAccountDetailsPageHandlerTest {
    @IsTest
    static void testSowUpdate(){
        
        
        Id roleId = [SELECT Id FROM UserRole WHERE Name='Management'].Id;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'carded',Email = 'cardeduser@testorg.com',
                          EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                          LocaleSidKey = 'en_US', ProfileId = p.Id,UserRoleId = roleId,
                          TimeZoneSidKey = 'America/Los_Angeles', UserName = 'cardeduser@rmit.edu.au');
        insert u;
        PortalAccountDetailsPageHandler.getContactDetails();
        PortalAccountDetailsPageHandler.getContactAndUserDetails();
        PortalAccountDetailsPageHandler.updatePortalReLoginRequired();
        PortalAccountDetailsPageHandler.contactSyncUpdate('Email Update');
        PortalAccountDetailsPageHandler.contactSyncUpdate('Mobile Update');
        System.runAs(u) {
            Contact c = new Contact();
            c.FirstName = 'Test FName';
            c.LastName = 'Test LName';
            insert c;
            PortalAccountDetailsPageHandler.updateContactDetails(true,true,'Mailing Address');
            contact con = [select id,Preferred_Address__c from Contact where id=:c.Id];
            System.assertEquals(null, con.Preferred_Address__c, 'Contact Update Failed');
            PortalAccountDetailsPageHandler.getPingOneURLS();
        }
    }
}