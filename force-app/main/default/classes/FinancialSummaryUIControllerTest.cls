/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 08-18-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-17-2020   sakshi.chauhan@simplus.com   Initial Version
**/
@isTest
public class FinancialSummaryUIControllerTest {
    public static Contact ct;
    public static Boolean testException = false;
    @isTest
    public static void getFinancialDataTest(){
        ct = new Contact(FirstName='John',LastName='smith', Email='start@yopmail.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555');
        insert ct;
        Test.startTest();
        	system.debug(ct.Id);
            String json = FinancialSummaryUIController.getFinancialData(ct.Id);
        Test.stopTest();
        system.assert ( json != null);
    }

    @isTest
    public static void getFinancialDataTestException(){
        ct = new Contact(FirstName='John',LastName='smith', Email='start@yopmail.com', HomePhone='+61439217734', OtherPhone='+61488886666', MobilePhone='+86130888866665555');
        insert ct;
        Test.startTest();
            testException = true;
        	system.debug(ct.Id);
            String json = FinancialSummaryUIController.getFinancialData(ct.Id);
        Test.stopTest();
        system.assert(json == null);
    }
}