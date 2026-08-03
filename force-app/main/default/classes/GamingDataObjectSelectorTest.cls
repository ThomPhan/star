/**
 * @description       : 
 * @author            : dominicjasper.caberoy@simplus.com
 * @group             : 
 * @last modified on  : 08-17-2020
 * @last modified by  : dominicjasper.caberoy@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-17-2020   dominicjasper.caberoy@simplus.com   Initial Version
**/
@isTest
public class GamingDataObjectSelectorTest {
    @isTest
    public static void getExternalFieldsTest(){
        GamingDataObjectSelector extObj = new GamingDataObjectSelector();
        Test.startTest();
            String fields = String.valueOf(extObj.getExternalObjectFieldsList());
        Test.stopTest();
    }

    @isTest
    public static void getExternalObjectNameTest(){
        GamingDataObjectSelector extObj = new GamingDataObjectSelector();
        Test.startTest();
            String objName = String.valueOf(extObj.getExternalObjectType());
        Test.stopTest();
    }
}