@IsTest
private class Exl_SFEventToAzureService_PEReqS_TEST {

    @IsTest
    static void test_ValidInput() {
        // Arrange
        ExternalService.ExclusionsExternalEvents_PlatformEventRequest validRequest = new ExternalService.ExclusionsExternalEvents_PlatformEventRequest();
        //validRequest.PERequest = 'TestValue';

        Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper inputWrapper = new Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper();
        inputWrapper.PERequest = validRequest;

        List<Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper> inputList = new List<Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper>{inputWrapper};

        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PEReqSERIAL.FlowOutputWrapper> outputList = Exl_SFEventToAzureService_PEReqSERIAL.deserializeJson(inputList);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputList.size(), 'Expected one output wrapper');
        //System.assertNotNull(outputList[0].serialised_Final_PE_PayLoad, 'Serialized payload should not be null');
        System.assertEquals(null, outputList[0].error, 'Error should be null for valid input');
    }

    @IsTest
    static void test_NullInput() {
        // Arrange
        Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper inputWrapper = new Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper();
        inputWrapper.PERequest = null;

        List<Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper> inputList = new List<Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper>{inputWrapper};

        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PEReqSERIAL.FlowOutputWrapper> outputList = Exl_SFEventToAzureService_PEReqSERIAL.deserializeJson(inputList);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputList.size(), 'Expected one output wrapper');
    }

    @IsTest
    static void test_EmptyInputList() {
        // Arrange
        List<Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper> inputList = new List<Exl_SFEventToAzureService_PEReqSERIAL.FlowInputWrapper>();

        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PEReqSERIAL.FlowOutputWrapper> outputList = Exl_SFEventToAzureService_PEReqSERIAL.deserializeJson(inputList);
        Test.stopTest();

    }
}