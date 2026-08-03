@isTest
public class Exl_GetHandOverTypeTest {
    
    @isTest
    static void testGetChoicesWithValidInput() {
        Exl_GetHandOverType.Input input = new Exl_GetHandOverType.Input();
        input.caseRecord = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Exl_Apply_Exclusion').getRecordTypeId(),
            Type = 'TP7DAY'
        );
        
        List<Exl_GetHandOverType.Input> inputs = new List<Exl_GetHandOverType.Input>{input};
        
        Test.startTest();
        List<Exl_GetHandOverType.Output> results = Exl_GetHandOverType.getChoices(inputs);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result for valid input');
        System.assert(results[0].entries.size() > 0, 'Entries should not be empty for valid input');
    }
    
    @isTest
    static void testGetChoicesWithEmptyInput() {
        List<Exl_GetHandOverType.Input> inputs = new List<Exl_GetHandOverType.Input>();
        
        Test.startTest();
        List<Exl_GetHandOverType.Output> results = Exl_GetHandOverType.getChoices(inputs);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty for empty input');
    }
    
    @isTest
    static void testGetChoicesWithInactivePicklistValues() {
        Exl_GetHandOverType.Input input = new Exl_GetHandOverType.Input();
        input.caseRecord = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Exl_Revoke_Exclusion').getRecordTypeId(),
            Type = 'Revoke'
        );
        
        List<Exl_GetHandOverType.Input> inputs = new List<Exl_GetHandOverType.Input>{input};
        
        Test.startTest();
        List<Exl_GetHandOverType.Output> results = Exl_GetHandOverType.getChoices(inputs);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results[0].entries.size() > 0, 'Only active picklist values should be included');
    }
}