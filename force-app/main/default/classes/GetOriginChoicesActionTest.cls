@IsTest
private class GetOriginChoicesActionTest {

    /**
     * Helper method to insert mock Exl_CaseTypePicklistConfig__mdt data
     */
    private static void insertMockMetadata() {
        // Use test seam instead of DML
        Exl_CaseTypePicklistConfig__mdt mdt1 = new Exl_CaseTypePicklistConfig__mdt(
                DeveloperName = 'Config1',
                MasterLabel = 'Config1',
                Case_Type__c = 'TypeA',
                State__c = 'VIC',
                Origin_Source__c = 'Web, Email');
        Exl_CaseTypePicklistConfig__mdt mdt2 = new Exl_CaseTypePicklistConfig__mdt(
                DeveloperName = 'Config2',
                MasterLabel = 'Config2',
                Case_Type__c = 'TypeB',
                State__c = 'NSW',
                Origin_Source__c = 'Phone, Walk-in');
        Exl_CaseTypePicklistConfig__mdt mdt3 = new Exl_CaseTypePicklistConfig__mdt(
                DeveloperName = 'Config3',
                MasterLabel = 'Config3',
                Case_Type__c = 'TypeA',
                State__c = 'QLD',
                Origin_Source__c = 'Mobile App');
            
        GetOriginChoicesAction.TEST_MODE = true;
        GetOriginChoicesAction.TEST_MAPPINGS = new List<Exl_CaseTypePicklistConfig__mdt>{mdt1, mdt2, mdt3};
        
    }

    /**
     * Test valid input for caseType = TypeA, state = VIC
     */
    @IsTest
    static void testValidInput_VIC() {
        insertMockMetadata();

        GetOriginChoicesAction.Input input = new GetOriginChoicesAction.Input();
        input.caseType = 'TypeA';
        input.state = 'VIC';

        Test.startTest();
        List<GetOriginChoicesAction.Output> results = GetOriginChoicesAction.getChoices(
            new List<GetOriginChoicesAction.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one Output object');
    }

    /**
     * Test valid input for caseType = TypeB, state = NSW
     */
    @IsTest
    static void testValidInput_NSW() {
        insertMockMetadata();

        GetOriginChoicesAction.Input input = new GetOriginChoicesAction.Input();
        input.caseType = 'TypeB';
        input.state = 'NSW';

        Test.startTest();
        List<GetOriginChoicesAction.Output> results = GetOriginChoicesAction.getChoices(
            new List<GetOriginChoicesAction.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one Output object');
        System.assertEquals(5, results[0].entries.size(), 'Should have 2 origin entries');
    }

    /**
     * Test with null or blank inputs — should return empty results
     */
    @IsTest
    static void testEmptyOrInvalidInputs() {
        Test.startTest();
        List<GetOriginChoicesAction.Output> result1 = GetOriginChoicesAction.getChoices(null);
        List<GetOriginChoicesAction.Output> result2 = GetOriginChoicesAction.getChoices(new List<GetOriginChoicesAction.Input>());
        Test.stopTest();

        System.assertEquals(0, result1.size(), 'Null input should return empty list');
        System.assertEquals(0, result2.size(), 'Empty list should return empty list');
    }

    /**
     * Test with non-matching Case Type / State — should return no entries
     */
    @IsTest
    static void testNoMatchingMetadata() {
        insertMockMetadata();

        GetOriginChoicesAction.Input input = new GetOriginChoicesAction.Input();
        input.caseType = 'TypeX';
        input.state = 'WA';

        Test.startTest();
        List<GetOriginChoicesAction.Output> results = GetOriginChoicesAction.getChoices(
            new List<GetOriginChoicesAction.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
    }
}