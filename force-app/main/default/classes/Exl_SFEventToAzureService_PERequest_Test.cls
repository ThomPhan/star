@isTest
public class Exl_SFEventToAzureService_PERequest_Test {
    
    @isTest
    static void testDeserializeJson_ValidInput() {
        // Arrange
        String validJson = '{"surname":"Doe","firstName":"John","dob":"1990-01-01","exclusionNumber":"EX12345","exclusionReason":"Test Reason","poeType":"Type1","poeTypeID":"ID123","poeLength":"6 months","excBySourceName":"SC","sourceName":"SC","issuedDate":"2025-01-01","revocationDate":"2025-06-01","accountIssuedDate":"2025-01-01","accountRevocationDate":"2025-06-01"}';
        List<String> jsonStrings = new List<String>{validJson};
        
        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PERequest.FlowOutputWrapper> results = Exl_SFEventToAzureService_PERequest.deserializeJson(jsonStrings);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'There should be one result.');
        System.assertEquals('Doe', results[0].Exl_PlatformEvent_JSONBody.surname, 'Surname should match the input JSON.');
        System.assertEquals('John', results[0].Exl_PlatformEvent_JSONBody.firstName, 'First name should match the input JSON.');
    }
    
    @isTest
    static void testDeserializeJson_InvalidInput() {
        // Arrange
        String invalidJson = '{"invalidField":"value"}';
        List<String> jsonStrings = new List<String>{invalidJson};
        
        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PERequest.FlowOutputWrapper> results = Exl_SFEventToAzureService_PERequest.deserializeJson(jsonStrings);
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