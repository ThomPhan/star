/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 08-26-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-26-2020   sakshi.chauhan@simplus.com   Initial Version
**/
@isTest
public class IdentificationUIControllerTest {
    public static Contact ct;
    public static Boolean testException = false;
    @isTest
    public static void getIdentificationDataTest(){
        ct = new Contact(FirstName='John',LastName='smith', Email='test@test.com');
        insert ct;
        Test.startTest();
            List<IdentificationUIDataProvider.IdentificationUIDataWrapper> json = IdentificationUIController.getIDDetailsByContactId(ct.Id);
        Test.stopTest();
    }
    @isTest
    public static void getIdentificationDataTestException(){
        ct = new Contact(FirstName='John',LastName='smith', Email='test@test.com');
        insert ct;
        Test.startTest();
        	testException = true;
            List<IdentificationUIDataProvider.IdentificationUIDataWrapper> json = IdentificationUIController.getIDDetailsByContactId(ct.Id);
        Test.stopTest();
    }
}