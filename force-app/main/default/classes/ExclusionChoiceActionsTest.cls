@IsTest
public class ExclusionChoiceActionsTest {

    
    @TestSetup
    static void setupData() {
        // Create Contact
        Contact c = new Contact(LastName = 'Test Contact');
        insert c;
    
        // Create Case
        Case ca = new Case(ContactId = c.Id, Subject = 'Test Case', Origin = 'Phone', Status = 'New');
        insert ca;
    
        // Create Exclusions for both ApplyCase__c and RevokeCase__c
        List<Exl_Exclusion__c> exclusions = new List<Exl_Exclusion__c>{
            // For GetExclusionGroupChoicesAction
            new Exl_Exclusion__c(ApplyCase__c = ca.Id, POE_Type__c = 'Self Exclusion - NSW', Origin__c = 'Crown'),
    
            // For GetExclusionChoicesAction
            new Exl_Exclusion__c(RevokeCase__c = ca.Id, POE_Type__c = 'Self Exclusion - QLD', Origin__c = 'Crown')
        };
        insert exclusions;
    }


	@IsTest
    static void testGetExclusionGroupChoicesAction() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
    
        GetExclusionGroupChoicesAction.Input input = new GetExclusionGroupChoicesAction.Input();
        input.contactId = c.Id;
        input.maxItemsInLabel = 5;
    
        List<GetExclusionGroupChoicesAction.Output> result =
            GetExclusionGroupChoicesAction.getChoices(new List<GetExclusionGroupChoicesAction.Input>{ input });
    
        System.assertEquals(1, result.size(), 'Should return one Output');
        System.assert(result[0].entries.size() > 0, 'Should return at least one group entry');
    
        for (ExlExclusionChoiceItem item : result[0].entries) {
            System.debug('Group Label: ' + item.label);
            System.debug('Group Value (CaseId): ' + item.value);
            System.assertNotEquals(null, item.label, 'Label should not be null');
            System.assertNotEquals(null, item.value, 'Value should not be null');
        }
    }


    @IsTest
    static void testGetExclusionChoicesAction() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
    
        GetExclusionChoicesAction.Input input = new GetExclusionChoicesAction.Input();
        input.contactId = c.Id;
    
        List<GetExclusionChoicesAction.Output> result =
            GetExclusionChoicesAction.getChoices(new List<GetExclusionChoicesAction.Input>{ input });
    
        System.assertEquals(1, result.size(), 'Should return one Output');
        System.assert(result[0].entries.size() > 0, 'Should return individual exclusions');
    
        for (ExlExclusionChoiceItem item : result[0].entries) {
            System.debug('Exclusion Label: ' + item.label);
            System.debug('Exclusion Value (Exclusion Id): ' + item.value);
            System.assertNotEquals(null, item.label, 'Label should not be null');
            System.assertNotEquals(null, item.value, 'Value should not be null');
        }
    }

}