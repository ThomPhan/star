@IsTest
private class Exl_SFEventToAzureService_PEBody_test {

    // Helper method to create a mock Exl_Exclusion__c record
    private static Exl_Exclusion__c createExclusionRecord(String status, String contactId) {
        Exl_Exclusion__c exclusion = new Exl_Exclusion__c(
            Status__c = status,
            Contact__c = contactId,
            Behaviour__c = 'Problem-Responsible Gaming',
            POE_Type__c = 'Problem Gambling - Group Wide',
            POE_Length__c = '3m',
            Start_Date__c = Date.today(),
            Revocation_Date__c = Date.today().addDays(30),
            Jurisdiction__c = 'NSW'
        );
        insert exclusion;
        return exclusion;
    }

    // Helper method to create a mock Contact record
    private static Contact createContact() {
        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Patron_ID__c = '9896',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert contact;
        return contact;
    }

    @IsTest
    static void testValidInput() {
        // Arrange
        Contact contact = createContact();
        Exl_Exclusion__c exclusion = createExclusionRecord('Exclusion Pending', contact.Id);

        Exl_SFEventToAzureService_PEBody.FlowInputWrapper input = new Exl_SFEventToAzureService_PEBody.FlowInputWrapper();
        input.exclusionRecord = exclusion;

        List<Exl_SFEventToAzureService_PEBody.FlowInputWrapper> inputs = new List<Exl_SFEventToAzureService_PEBody.FlowInputWrapper>{input};

        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PEBody.FlowOutputWrapper> outputs = Exl_SFEventToAzureService_PEBody.returnPlatformEventBody(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Expected one output');

    }

    @IsTest
    static void testInvalidInput() {
        // Arrange
        Exl_SFEventToAzureService_PEBody.FlowInputWrapper input = new Exl_SFEventToAzureService_PEBody.FlowInputWrapper();
        input.exclusionRecord = null; // Invalid input

        List<Exl_SFEventToAzureService_PEBody.FlowInputWrapper> inputs = new List<Exl_SFEventToAzureService_PEBody.FlowInputWrapper>{input};

        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PEBody.FlowOutputWrapper> outputs = Exl_SFEventToAzureService_PEBody.returnPlatformEventBody(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Expected one output');
        
    }

    @IsTest
    static void testEdgeCase_MissingFields() {
        // Arrange
        Contact contact = createContact();
        Exl_Exclusion__c exclusion = new Exl_Exclusion__c(
            Contact__c = contact.Id,
            Status__c = null // Missing status field
        );
        insert exclusion;

        Exl_SFEventToAzureService_PEBody.FlowInputWrapper input = new Exl_SFEventToAzureService_PEBody.FlowInputWrapper();
        input.exclusionRecord = exclusion;

        List<Exl_SFEventToAzureService_PEBody.FlowInputWrapper> inputs = new List<Exl_SFEventToAzureService_PEBody.FlowInputWrapper>{input};

        // Act
        Test.startTest();
        List<Exl_SFEventToAzureService_PEBody.FlowOutputWrapper> outputs = Exl_SFEventToAzureService_PEBody.returnPlatformEventBody(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Expected one output');
    }
}