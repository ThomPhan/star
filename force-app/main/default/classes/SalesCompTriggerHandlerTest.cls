/**
 * @description       : Test class for SalesCompTriggerHandler
 * @author            : Simplus
 * @group             : Simplus
 * @last modified on  : 22-08-2022
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   22-08-2022   Simplus                      Initial Version
 */
@isTest
public class SalesCompTriggerHandlerTest {
    static final String SALES_COMP_RECORD_TYPE_NAME_CD_CP = 'CD_CP';
    static final String SALES_COMP_RECORD_TYPE_NAME_SPV_MPV = 'SPV_MPV';
    static final String SALES_COMP_STATUS_APPROVED = 'Approved';
    static final String SALES_COMP_STATUS_DRAFT = 'Draft';
    static final String SALES_COMP_STATUS_INVALID = 'Invalid';
    static final String SALES_COMP_STATUS_PENDING = 'Pending';
    @testSetup
    static void testDataFactory(){
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
        
        INSERT testAdminUser;
        
        User testPaulUser = new User();
        testPaulUser.FirstName = 'Paul';
        testPaulUser.LastName = 'Monaghan';
        testPaulUser.Email = 'testPaulM@starTest.com';
        testPaulUser.Alias = 'tpam';
        testPaulUser.Username = 'testPaulM@starTest.com';
        testPaulUser.CommunityNickname = 'TestPaul';
        testPaulUser.ProfileId = sysAd.Id;
        testPaulUser.UserRoleId = testRole.Id;
        testPaulUser.TimeZoneSidKey = 'Australia/Sydney';
        testPaulUser.LocaleSidKey = 'en_AU';
        testPaulUser.EmailEncodingKey = 'ISO-8859-1';
        testPaulUser.LanguageLocaleKey = 'en_US';
        
        INSERT testPaulUser;
    }
    
    static testmethod void testgetAllUsersRole(){
        test.startTest();
        List<User> testUserList = SalesCompTriggerHandler.getAllUsers('PGM Syd', TRUE);
        test.stopTest();
        
        System.assert(!testUserList.isEmpty());
    }
    
    static testmethod void testgetAllUsersUser(){
        test.startTest();
        List<User> testUserList = SalesCompTriggerHandler.getAllUsers('Test Admin Star User', FALSE);
        test.stopTest();
        
        System.assert(!testUserList.isEmpty());
    }
    
    static testmethod void testUpdateStatus(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testAdminUser@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.cc',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        test.startTest();
        
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 100,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.stopTest();
        System.assertEquals([SELECT Id, Status__c FROM Sales_Comp__c WHERE Contact__c =: testContact.Id].Status__c, 'Draft');
    }
    
    static testmethod void testValidateApprovers500(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testAdminUser@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 500,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_APPROVED);
    }
    
    static testmethod void testValidateApprovers1000(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testAdminUser@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 1000,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_APPROVED);
    }
    
    static testmethod void testValidateApprovers2000(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testAdminUser@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 2000,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_INVALID);
    }
    
    static testmethod void testValidateApprovers5000(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testAdminUser@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 5000,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_INVALID);
    }
    
    static testmethod void testValidateApprovers50000(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testPaulM@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 50000,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_APPROVED);
    }
    
    static testmethod void testValidateApprovers75000(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testPaulM@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 75000,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_APPROVED);
    }
    
    static testmethod void testPopulateJustification(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testPaulM@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 75000,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_APPROVED
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Rejecting request.');
            req2.setAction('Reject');
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Justification__c FROM Sales_Comp__c WHERE Contact__c =: testContact.Id LIMIT 1];
        System.assertEquals(assertSalesComp.Justification__c, null);
    }
    
    static testmethod void testSecondApproval(){
        List<Sales_Comp__c> scListValidate = new List<Sales_Comp__c>();
        List<Id> approverIdSet = new List<Id>();
        User testAdmin = [SELECT Id, Email FROM User WHERE Email = 'testAdminUser@starTest.com' LIMIT 1];
        approverIdSet.add(testAdmin.Id);
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.com',
            Refused_to_provide_SOW__c = TRUE
        );
        INSERT testContact;
        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Sales_Comp__c scCD = new Sales_Comp__c(
                Amount__c = 500,
                Comp_Type__c = 'Casino Dollar',
                Contact__c = testContact.Id,
                RecordTypeId = cdCPrtId,
                Status__c = SALES_COMP_STATUS_DRAFT
            );
        
        INSERT scCD;
        
        test.startTest();
        System.runAs(testAdmin){
            Approval.ProcessSubmitRequest testApproval = new Approval.ProcessSubmitRequest();
            testApproval.setObjectId(scCD.Id);
            testApproval.setNextApproverIds(approverIdSet);
            Approval.ProcessResult result = Approval.process(testApproval);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(approverIdSet);
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);
        }
        
        SalesCompTriggerHandler.sendForSecondApproval(scCD.Id, approverIdSet[0], 'Sales_Comp_Approval_Process_2');
        test.stopTest();
        
        Sales_Comp__c assertSalesComp = [SELECT Id, Status__c FROM Sales_Comp__c WHERE Id =: scCD.Id];
        System.assertEquals(assertSalesComp.Status__c, SALES_COMP_STATUS_PENDING);
    }
}