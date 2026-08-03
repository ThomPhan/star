/**
 * @description       : GamingDataUIHandler Apex Test Class
 * @author            : dominicjasper.caberoy@simplus.com
 * @group             : 
 * @last modified on  : 08-20-2020
 * @last modified by  : dominicjasper.caberoy@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-20-2020   dominicjasper.caberoy@simplus.com   Initial Version
**/
@isTest
public class GamingDataUIHandlerTest {
    public static Contact ct;
    public static Property__c prop;
    public static Boolean isException = false;
    @isTest static void getPropertiesTest(){
        Map<String, String> propertyList = new Map<String, String>();
        Property__c prop = new Property__c(Name = 'Test Property');
        insert prop;
        Test.startTest();
            propertyList = GamingDataUIHandler.propertyList();
        Test.stopTest();
        system.assertEquals(1, propertyList.size());
    }
    @isTest static void getWithPropertyGamingDataTest(){
        ct = new Contact(FirstName='John',LastName='smith',Email='test@test.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555', Refused_to_provide_SOW__c = true);
        insert ct;
        prop = new Property__c(Name = 'Test Property');
        insert prop;
        Test.startTest();
            String game = GamingDataUIHandler.gamingList(ct.Id, prop.Id);
        Test.stopTest();
    }
    @isTest static void getWithoutPropertyGamingDataTest(){
        ct = new Contact(FirstName='John',LastName='smith',Email='test@test.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555', Refused_to_provide_SOW__c = true);
        insert ct;
        Test.startTest();
            String game = GamingDataUIHandler.gamingList(ct.Id, '');
        Test.stopTest();
    }
    @isTest static void getGamingDataTotal(){
        ct = new Contact(FirstName='John',LastName='smith',Email='test@test.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555', Refused_to_provide_SOW__c = true);
        insert ct;
        Test.startTest();
            String game = GamingDataUIHandler.gamingListTotal(ct.Id, 'SLOT', 'Month To Date');
        Test.stopTest();
    }
    @isTest static void getGamingDataTotalException(){
        ct = new Contact(FirstName='John',LastName='smith',Email='test@test.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555', Refused_to_provide_SOW__c = true);
        insert ct;
        Test.startTest();
            isException = true;
            String game = GamingDataUIHandler.gamingListTotal(ct.Id, 'SLOT', 'Month To Date');
        Test.stopTest();
    }
    @isTest
    public static void getGamingDataExceptionTest(){
        ct = new Contact(FirstName='John',LastName='smith',Email='test@test.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555', Refused_to_provide_SOW__c = true);
        //insert ct;
        Test.startTest();
            isException = true;
            String json = GamingDataUIHandler.gamingList('0035O000003AP3nQBE', '');
        Test.stopTest();
    }
}