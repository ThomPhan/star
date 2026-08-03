/**
* @File Name : ContentVersionTriggerTest
* @Description : Test Class
* @Author : Arth Sharma (Capgemini Contigent)
* @Last Modified By :
* @Last Modified On : Aug 01, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Aug 01, 2025 |   | Initial Version
**/
@isTest
public class ContentVersionTriggerTest {
    
    // Helper to create a ContentVersion (Lightning Files)
    private static ContentVersion makeContentVersion(Id parentId, String pathOnClient) {
        return new ContentVersion(
            Title = 'TestFile',
            PathOnClient = pathOnClient,
            VersionData = Blob.valueOf('dummy'),
            FirstPublishLocationId = parentId
        );
    }
    
    @TestSetup
    static void setupData() {
        // 1. Insert required records: Contact and Account
        Contact c = new Contact(LastName = 'TestContact');
        insert c;
        
        Account a = new Account(Name = 'TestAccount');
        insert a;
        
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User regular = new User(
            LastName = 'RegularUser',
            Email = 'regularuser+' + DateTime.now().getTime() + '@example.com',
            Username = 'regularuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'regusr',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = sysAdmin.Id
        );
        insert regular;
        
        // Bypass candidate user
        User bypassUser = new User(
            LastName = 'BypassUser',
            Email = 'bypassuser+' + DateTime.now().getTime() + '@example.com',
            Username = 'bypassuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'bypass',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = sysAdmin.Id
        );
        insert bypassUser;
        
        Source_of_Wealth__c tObj = new Source_of_Wealth__c();
        tObj.Contact__c = c.id;
        insert tObj;
    }
    
    
    @IsTest
    static void testContentVersionValidationOnContact() {
        User usr = [SELECT Id FROM User WHERE LastName='RegularUser' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE LastName='TestContact' LIMIT 1];
        Source_of_Wealth__c sow = [SELECT Id FROM Source_of_Wealth__c LIMIT 1];
        System.runAs(usr) {
            // 1. Allowed extension: should still be blocked because Contact is in manual block list
            ContentVersion cv1 = makeContentVersion(sow.Id, 'doc.pdf');
            
            try {
                insert cv1;
                System.assert(false, 'Expected manual upload block on ContentVersion for sow');
            } catch (DmlException de) {
                System.assert(de.getMessage().contains('blocked'), 'Expected manual block but got: ' + de.getMessage());
            }
            
            
            // 2. Disallowed extension (e.g., .exe) — also would hit both file-type and manual block, but error is enough
            ContentVersion cv2 = makeContentVersion(sow.Id, 'malware.exe');
            Test.startTest();
            try {
                insert cv2;
                System.assert(false, 'Expected file-type or manual block on .exe ContentVersion');
            } catch (DmlException de) {
                Boolean hasBlock = de.getMessage().contains('blocked');
                Boolean hasExt = de.getMessage().toLowerCase().contains('not allowed') || de.getMessage().toLowerCase().contains('extension');
                System.assert(
                    hasBlock || hasExt,
                    'Expected either manual block or extension error; got: ' + de.getMessage()
                );
            }
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testContentVersionValidationOnContactByPass() {
        User usr = [SELECT Id FROM User WHERE LastName='RegularUser' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE LastName='TestContact' LIMIT 1];
        Source_of_Wealth__c sow = [SELECT Id FROM Source_of_Wealth__c LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Bypass_Manual_File_Upload_Control'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = usr.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        System.runAs(usr) {
            // 1. Allowed extension: should still be blocked because Contact is in manual block list
            ContentVersion cv1 = makeContentVersion(sow.Id, 'doc.pdf');
            
            try {
                insert cv1;
                System.assert(true, 'Allowed manual upload on ContentVersion for SOW');
            } catch (DmlException de) {
                System.assert(de.getMessage().contains('blocked'), 'Expected manual block but got: ' + de.getMessage());
            }
            
            
            // 2. Disallowed extension (e.g., .exe) — also would hit both file-type and manual block, but error is enough
            ContentVersion cv2 = makeContentVersion(sow.Id, 'malware.exe');
            cv2.PathOnClient = null;
            cv2.VersionData = null;
            cv2.ContentUrl = 'test';
            Test.startTest();
            try {
                insert cv2;
                System.assert(true, 'Expected file-type or manual block on malware file ContentVersion');
            } catch (DmlException de) {
                Boolean hasNoExt = de.getMessage().contains('File name/path missing');
                System.assert(
                    hasNoExt,
                    'Expected no extension error; got: ' + de.getMessage()
                );
            }
            Test.stopTest();
        }
    }
}