@isTest
public class Exl_WO_NextButtonUtil_Test {

    @testSetup
    static void setupTestData() {
        WorkOrder wo = new WorkOrder( Subject = 'Test WO', Status = 'Open');
        insert wo;

        // Create Work Order Line Items, One incomplete button item
        WorkOrderLineItem woli1 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Button A',
            IsButton__c = true,
            Status = 'Open'
        );

        // Another incomplete, but not button (should be counted for woCompleted)
        WorkOrderLineItem woli2 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Step X',
            IsButton__c = false,
            Status = 'Open'
        );

        // A completed button item (should not be selected)
        WorkOrderLineItem woli3 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Button B',
            IsButton__c = true,
            Status = 'Completed'
        );
		insert new List<WorkOrderLineItem>{woli1, woli2, woli3};
    }

    @isTest
    static void testNextButtonLogic() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Build Flow input
        Exl_WO_NextButtonUtil.FlowInputWrapper input =
            new Exl_WO_NextButtonUtil.FlowInputWrapper();
        input.woID = wo.Id;

        List<Exl_WO_NextButtonUtil.FlowInputWrapper> inputs =
            new List<Exl_WO_NextButtonUtil.FlowInputWrapper>{ input };

        Test.startTest();
        List<Exl_WO_NextButtonUtil.FlowOutputWrapper> results =
            Exl_WO_NextButtonUtil.getWOForUpdate(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 wrapper');

        Exl_WO_NextButtonUtil.FlowOutputWrapper out = results[0];

        // Assert no error
        System.assertEquals(null, out.error, 'No error expected');

        // Expected next button = "Button A"
        System.assertEquals('Button A', out.nextButton, 'Next button mismatch');

        // woCompleted should be false because "Step X" is still incomplete
        System.assertEquals(false, out.woCompleted, 'WO should NOT be completed');
    }

    @isTest
    static void testAllCompletedScenario() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Mark all WOLIs as completed
        List<WorkOrderLineItem> wolis = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        for (WorkOrderLineItem w : wolis) {
            w.Status = 'Completed';
        }
        update wolis;

        // Build Flow input
        Exl_WO_NextButtonUtil.FlowInputWrapper input =
            new Exl_WO_NextButtonUtil.FlowInputWrapper();
        input.woID = wo.Id;

        List<Exl_WO_NextButtonUtil.FlowInputWrapper> inputs =
            new List<Exl_WO_NextButtonUtil.FlowInputWrapper>{ input };

        Test.startTest();
        List<Exl_WO_NextButtonUtil.FlowOutputWrapper> results =
            Exl_WO_NextButtonUtil.getWOForUpdate(inputs);
        Test.stopTest();

        Exl_WO_NextButtonUtil.FlowOutputWrapper out = results[0];

        System.assertEquals(null, out.error, 'No error expected');
        // No next button available
        System.assertEquals(null, out.nextButton, 'Should be no next button');
        // WO is completed
        System.assertEquals(true, out.woCompleted, 'WO should be completed');
    }

    @isTest
    static void testErrorScenario() {
        // Input an invalid ID to force exception
        Exl_WO_NextButtonUtil.FlowInputWrapper input =
            new Exl_WO_NextButtonUtil.FlowInputWrapper();
        input.woID = 'NotARealId'; // causes cast exception

        List<Exl_WO_NextButtonUtil.FlowInputWrapper> inputs =
            new List<Exl_WO_NextButtonUtil.FlowInputWrapper>{ input };

        Test.startTest();
        List<Exl_WO_NextButtonUtil.FlowOutputWrapper> results =
            Exl_WO_NextButtonUtil.getWOForUpdate(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size());
        Exl_WO_NextButtonUtil.FlowOutputWrapper out = results[0];
        System.assertNotEquals(null, out.error, 'Error expected');
        System.assert(
            out.error.contains('Error encountered'),
            'Error message should begin with expected prefix'
        );
    }
}