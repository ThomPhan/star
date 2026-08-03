/**
 * @description       : Test class for SalesCompPrintableViewExtension
 * @author            : Simplus
 * @group             : Simplus
 * @last modified on  : 22-08-2022
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   22-08-2022   Simplus                      Initial Version
 */
@isTest
public class SalesCompPrintableViewExtensionTest {

    @testSetup
    static void testDataFactory() {
        Profile sysAd = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'PGM Syd'];
        User testAdminUser = new User();
        testAdminUser.FirstName = 'Test Admin';
        testAdminUser.LastName = 'Star User';
        testAdminUser.Email = 'testAdminUser@starTest.com';
        testAdminUser.Alias = 'tasu';
        testAdminUser.Username = 'testAdminUser@starTest.com';
        testAdminUser.CommunityNickname = 'TestUser';
        testAdminUser.ProfileId = sysAd.Id;
        testAdminUser.UserRoleId = testRole.Id;
        testAdminUser.TimeZoneSidKey = 'Australia/Sydney';
        testAdminUser.LocaleSidKey = 'en_AU';
        testAdminUser.EmailEncodingKey = 'ISO-8859-1';
        testAdminUser.LanguageLocaleKey = 'en_US';
        insert testAdminUser;        
    }

    @isTest static void extensionApprovedTest() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.cc'
        );
        insert testContact;

        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get('CD_CP').getRecordTypeId();

        Sales_Comp__c scCD = new Sales_Comp__c(
            Amount__c = 100,
            Comp_Type__c = 'Casino Dollar',
            Contact__c = testContact.Id,
            RecordTypeId = cdCPrtId
        );
        insert scCD;

        User adminUser = [SELECT Id FROM User WHERE Username = 'testAdminUser@starTest.com' LIMIT 1];

        // Submit for Approval
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(scCD.Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new List<Id>{ adminUser.Id });
        req1.setProcessDefinitionNameOrId('Sales_Comp_Approval_Process_1');
        Approval.ProcessResult result1 = Approval.process(req1);

        // Approve
        Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
        pwr.setAction('Approve');
        ProcessInstanceWorkitem piwItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :scCD.Id];
        pwr.setWorkitemId(piwItem.Id);
        Approval.ProcessResult pwrResult = Approval.process(pwr);

        Boolean isCDCP = false;
        Boolean isApproved = false;
        Test.startTest();
            PageReference testPage = Page.SalesCompPrintableView;
            Test.setCurrentPage(testPage);
            testPage.getParameters().put('id', String.valueOf(scCD.Id));

            ApexPages.StandardController sc = new ApexPages.StandardController(scCD);
            SalesCompPrintableViewExtension ext = new SalesCompPrintableViewExtension(sc);

            isCDCP = ext.getRecordType();
            isApproved = ext.getRecordStatus();
            String deviceRenderedAs = ext.getDevice();

            Boolean withSubmitter = ext.getSubmitterName();
            Boolean withAuthoriser = ext.getAuthoriserName();
        Test.stopTest();
    }

    @isTest static void extensionRejectedTest() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.cc'
        );
        insert testContact;

        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get('CD_CP').getRecordTypeId();

        Sales_Comp__c scCD = new Sales_Comp__c(
            Amount__c = 100,
            Comp_Type__c = 'Casino Dollar',
            Contact__c = testContact.Id,
            RecordTypeId = cdCPrtId
        );
        insert scCD;

        User adminUser = [SELECT Id FROM User WHERE Username = 'testAdminUser@starTest.com' LIMIT 1];

        // Submit for Approval
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(scCD.Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new List<Id>{ adminUser.Id });
        req1.setProcessDefinitionNameOrId('Sales_Comp_Approval_Process_1');
        Approval.ProcessResult result1 = Approval.process(req1);

        // Reject
        Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
        pwr.setAction('Reject');
        ProcessInstanceWorkitem piwItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :scCD.Id];
        pwr.setWorkitemId(piwItem.Id);
        Approval.ProcessResult pwrResult = Approval.process(pwr);

        Boolean isCDCP = false;
        Boolean isApproved = false;
        Test.startTest();
            PageReference testPage = Page.SalesCompPrintableView;
            Test.setCurrentPage(testPage);
            testPage.getParameters().put('id', String.valueOf(scCD.Id));

            ApexPages.StandardController sc = new ApexPages.StandardController(scCD);
            SalesCompPrintableViewExtension ext = new SalesCompPrintableViewExtension(sc);

            isCDCP = ext.getRecordType();
            isApproved = ext.getRecordStatus();
            String deviceRenderedAs = ext.getDevice();

            Boolean withSubmitter = ext.getSubmitterName();
            Boolean withAuthoriser = ext.getAuthoriserName();
        Test.stopTest();
    }
}