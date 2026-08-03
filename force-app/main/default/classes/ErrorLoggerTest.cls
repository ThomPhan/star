/**
 * Class Name  : ErrorLoggerTest
 * Summary     : Test Class for validating the test coverage of the Error Logger Class 
 * Method     :  testSingleValueEvent     
 * @author       Simplus
   @Description: This class contains the logic for the insertion of record for Error_Event__e Platform Event
 * @version      $Revision: 1.0 $, $Date: 21/July/2020 
 */
@isTest
public class ErrorLoggerTest {
    @isTest static void testValidEvent(){
        //Ensure that the Enable Error Logging Custom Setting is checked
  		ErrorLoggingSettings__c getCustSetting = ErrorLoggingSettings__c.getOrgDefaults();
        getCustSetting.Enable_Error_Logging__c = true;
        insert getCustSetting;
        
        List<Error_Event__e> errs = new List<Error_Event__e>();
        System.assertEquals(true, getCustSetting.Enable_Error_Logging__c);
        
        Test.startTest();
        	//Failed account which leads to the catch method
            try{
                List<Account> testAcc = new List<Account>();
                testAcc.add(new Account(Id = '09123456789',
                                        Name = 'Test Account'));
                insert testAcc;
            } catch (Exception e){
                //execute the Error Logger object
                ErrorLogger.createLog('Test Apex Class', 'Test Method Name', e, '', 'Apex Class');
            }
        Test.stopTest();
        //Check if an error log record is created
        List<ErrorLog__c> errLogs = [SELECT Id FROM ErrorLog__c];
        System.assertEquals(1, errLogs.size());
    }
    @isTest static void testValidEventWithNullException(){
        //Ensure that the Enable Error Logging Custom Setting is checked
  		ErrorLoggingSettings__c getCustSetting = ErrorLoggingSettings__c.getOrgDefaults();
        getCustSetting.Enable_Error_Logging__c = true;
        insert getCustSetting;
        
        List<Error_Event__e> errs = new List<Error_Event__e>();
        System.assertEquals(true, getCustSetting.Enable_Error_Logging__c);
        
        Test.startTest();
        	//Failed account which leads to the catch method
            try{
                List<Account> testAcc = new List<Account>();
                testAcc.add(new Account(Id = '09123456789',
                                        Name = 'Test Account'));
                insert testAcc;
            } catch (Exception e){
                //execute the Error Logger object
                ErrorLogger.createLog('Test Apex Class', 'Test Method Name', null, '', 'Apex Class');
            }
        Test.stopTest();
        //Check if an error log record is created
        List<ErrorLog__c> errLogs = [SELECT Id FROM ErrorLog__c];
        //System.assertEquals(1, errLogs.size());
    }
}