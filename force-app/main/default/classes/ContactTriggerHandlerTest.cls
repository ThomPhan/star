/**
* @description       : Test class for ContactTriggerHandler
* @author            : Simplus
* @group             : Simplus
* @last modified by  : Simplus
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   11-09-2023   Simplus                      Initial Version
*/
@isTest
public class ContactTriggerHandlerTest {
    
    @isTest
    static void testSowUpdate(){
        
        Contact c = new Contact();
        c.FirstName = 'Test FName';
        c.LastName = 'Test LName';
        insert c;
        
        c.Their_role_in_that_business__c = '123';
        update c;
        
    }
    @isTest
    static void testSowUpdate2(){
        Contact c = new Contact();
        c.FirstName = 'Test FName';
        c.LastName = 'Test LName';
        c.Email = 'Test@test.com';
        c.MobilePhone = '61-457154770';
        c.SoW_Update_DateTime__c = DateTime.now();
        insert c;
        
        Contact con = [select id,MobilePhone,Email,SoW_Update_DateTime__c,Portal_Mobile_Update_Sync_Wait__c,Portal_Email_Update_Sync_Wait__c from contact where FirstName ='Test FName'];
        c.Email = 'Test1@test.com';
        con.MobilePhone = '61-457154771';
        con.SoW_Update_DateTime__c = DateTime.now() +1;
        update c;
        
    }
    @isTest
    static void testSowUpdate3(){
        Contact c = new Contact();
        c.FirstName = 'Test FName';
        c.LastName = 'Test LName';
        c.Email = 'Test@test.com';
        c.MobilePhone = '61-457154770';
        c.SoW_Update_DateTime__c = DateTime.now();
        insert c;
        
        Contact con = [select id,MobilePhone,Email,SoW_Update_DateTime__c,Portal_Mobile_Update_Sync_Wait__c,Portal_Email_Update_Sync_Wait__c from contact where FirstName ='Test FName'];
        c.MobilePhone = '61-457154771';
        con.SoW_Update_DateTime__c = DateTime.now() +1;
        update c;
        
    }
}