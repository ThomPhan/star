/*******************************************************************************************************
 * @description       : Test class for TriggerHandlerBase
 * @author            : Aldrin Rasdas
 * @last modified on  : 28-May-2024
 * @last modified by  : Aldrin Rasdas
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date            Mod ID      Description
 * -----------------------------------------------------------------------------------------------------
 * Aldrin Rasdas		28-May-2024		1000        Initial version
******************************************************************************************************/
@istest
private class TriggerHandlerBaseTest {
    class TestTriggerHandler extends TriggerHandlerBase {
        TestTriggerHandler(String name){
            super(name);
        }
    }
    
    @istest
    private static void testOne() {
        //mainly to cover apex code lines. no assert since there's no logic in the abstract class
        TestTriggerHandler handler = new TestTriggerHandler('TestClassConfig_DO_NOT_DELETE');
        handler.run(TriggerOperation.BEFORE_INSERT);
        handler.run(TriggerOperation.BEFORE_UPDATE);
        handler.run(TriggerOperation.BEFORE_DELETE);
        handler.run(TriggerOperation.AFTER_INSERT);
        handler.run(TriggerOperation.AFTER_UPDATE);
        handler.run(TriggerOperation.AFTER_DELETE);
        handler.run(TriggerOperation.AFTER_UNDELETE);        
    }
    
    @istest
    private static void testTwo() {
        TestTriggerHandler handler = new TestTriggerHandler('TestClassConfig_DO_NOT_DELETE');
        handler.execute();
        System.assertEquals(true, handler.isTriggerEnabled());
    }
    
    @istest
    private static void testThree() {
        TestTriggerHandler handler = new TestTriggerHandler('TestClassConfig_DO_NOT_DELETE');
        handler.allTriggerConfig = new Trigger_Switch__mdt(Before_Insert__c=false);
        handler.execute();
        System.assertEquals(false, handler.isTriggerEnabled());
    }    
}