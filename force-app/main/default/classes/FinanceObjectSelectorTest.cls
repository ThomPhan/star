/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 08-19-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-19-2020   sakshi.chauhan@simplus.com   Initial Version
**/
@isTest
public class FinanceObjectSelectorTest {
    
    
    @isTest
    public static void testGetFields(){
        FinanceObjectSelector selector = new FinanceObjectSelector();
        Test.startTest();
            String fields = String.valueOf(selector.getExternalObjectFieldsList());
        Test.stopTest();
    }

    @isTest
    public static void testGetObjectName(){
        FinanceObjectSelector selector = new FinanceObjectSelector();
        Test.startTest();
            String objName = String.valueOf(selector.getExternalObjectType());
        Test.stopTest();
    }
}