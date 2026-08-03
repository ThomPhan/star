@IsTest
private class GetDeliveryStatusChoicesAction_Test {

    @IsTest
    static void testGetChoices() {
        // Enable test mode (your class exposes this specifically for tests)
        GetDeliveryStatusChoicesAction.TEST_MODE = true;

        Test.startTest();
        List<GetDeliveryStatusChoicesAction.Output> results =
            GetDeliveryStatusChoicesAction.getChoices();
        Test.stopTest();
    }
}