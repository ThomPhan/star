@isTest
public class Exl_AzureEventToSF_INBOUND_JSON_Test {

    @isTest
    static void testDeserializeJson_ValidInput() {
        // Arrange
        String validJson = '{ "stopCode": "4000000003","action": "APPLY"}';
        List<String> jsonStrings = new List<String>{validJson};
        
        // Act
        Test.startTest();
        List<Exl_AzureEventToSF_INBOUND_JSON.FlowOutputWrapper> results = Exl_AzureEventToSF_INBOUND_JSON.deserializeJson(jsonStrings);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'There should be one result.');
        System.assertEquals('4000000003', results[0].iNBOUND_JSONBody.stopCode, 'Stop code should match the input JSON.');
        System.assertEquals('APPLY', results[0].iNBOUND_JSONBody.action, 'Action should match the input JSON.');
    }
    
    @isTest
    static void testDeserializeJson_InvalidInput() {
        // Arrange
        String invalidJson = '{bad json';
        List<String> jsonStrings = new List<String>{invalidJson};
        
        // Act
        Test.startTest();
        List<Exl_AzureEventToSF_INBOUND_JSON.FlowOutputWrapper> results = Exl_AzureEventToSF_INBOUND_JSON.deserializeJson(jsonStrings);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'There should be one result.');
    }
    
    @isTest
    static void testDeserializeJson_EmptyInput() {
        // Arrange
        List<String> jsonStrings = new List<String>();
        
        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PERequest.FlowOutputWrapper> results = Exl_SFEventToAzureService_PERequest.deserializeJson(jsonStrings);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'There should be no results for empty input.');
    }
    

}