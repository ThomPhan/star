/**
 * @description       : Test class for SOWTrigger 
 * @author            : CapGemini
 * @group             : CapGemini
 * @last modified by  : CapGemini
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   21-01-2025   CapGemini                      Initial Version
 * 2.0   10-07-2025   Arth                           Initial Version
 */
@isTest
public class SOWTriggerTest{
    
    @isTest
    static void testSOWExternalUpdate(){

        Contact c = new Contact();
        c.FirstName = 'Test FName';
        c.LastName = 'Test LName';
        insert c;
        Source_of_Wealth__c tObj = new Source_of_Wealth__c();
        tObj.Contact__c = c.id;
        insert tObj;
         
        Test.startTest();
        try{
        
        //Simulating the first update from external system
          tObj.isSubmitted__c = true;
          update tObj;
          
          
        //Simulating the Second update from external system
          tObj.isSubmitted__c = true;
          update tObj;
          
          tObj.fileuploaded_to_trackvia__c = false;
          update tObj;
          
          tObj.fileuploaded_to_trackvia__c = true;
          update tObj;
          
          

          
        }
        Catch(Exception ex)
        {
        
        Boolean expectedExceptionThrown =  (ex.getMessage().contains('error msg')) ? true : false; 
        System.AssertEquals(false, expectedExceptionThrown, ex.getMessage()); 
        }
        Test.stopTest();
        
    }
}