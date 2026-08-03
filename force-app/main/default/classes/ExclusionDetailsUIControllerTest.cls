/**
 * @description       : 
 * @author            : Simplus
 * @group             : 
 * @last modified on  : 08-28-2023
 * @last modified by  : Simplius
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-28-2023   Simplus   Initial Version
**/
@isTest
public class ExclusionDetailsUIControllerTest {
    public static Contact ct;
    public static Boolean testException = false;
    @isTest
    public static void getIdentificationDataTest(){
        ct = new Contact(FirstName='John',LastName='smith', Email='test@test.com');
        insert ct;
        Test.startTest();
            List<ExclusionsDetailsUIDataProvider.ExclusionsDetailsWrapper> json = ExclusionsDetailsUIController.getIDDetailsByContactId(ct.Id);
        Test.stopTest();
    }
    @isTest
    public static void getIdentificationDataTestException(){
        ct = new Contact(FirstName='John',LastName='smith', Email='test@test.com');
        insert ct;
        Test.startTest();
        	testException = true;
            List<ExclusionsDetailsUIDataProvider.ExclusionsDetailsWrapper> json = ExclusionsDetailsUIController.getIDDetailsByContactId(ct.Id);
        Test.stopTest();
    }
}