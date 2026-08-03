@isTest
private class Exl_RestrictionCreation_Test {

    // Utility: create a Contact and return Id
    private static Id createContact() {
        Contact c = new Contact(LastName = 'Test Contact', Patron_ID__c = '4565608');
        insert c;
        return c.Id;
    }    
    
    @IsTest
    static void testInsertExclusion() {
        Id conId = createContact();
        Exl_Exclusion__c ex = new Exl_Exclusion__c(
            Contact__c = conId,
            POE_Type__c = 'Interstate - CCA',
            Status__c = 'Exclusion Pending'
        );
        Test.startTest();
        insert ex;
        //insert another Exclusion
        Exl_Exclusion__c ex1 = new Exl_Exclusion__c(
            Contact__c = conId,
            POE_Type__c = 'Interstate - CCA',
            Status__c = 'Exclusion Pending'
        );        
        insert ex1;
        Test.stopTest();
        // assert
        List<Exl_Restriction__c> res = new List<Exl_Restriction__c>([SELECT Id FROM Exl_Restriction__c WHERE Patron__c = :conId]);
		System.assert(res != null, 'Restriction records are created');
        
    }
    
    @IsTest
    static void testInsertExclusion_blankPOE() {
        Id conId = createContact();
        Exl_Exclusion__c ex = new Exl_Exclusion__c(
            Contact__c = conId,
            POE_Type__c = '',
            Status__c = 'Exclusion Pending'
        );
        Test.startTest();
        insert ex;
        Test.stopTest();
        // assert
        List<Exl_Restriction__c> res = new List<Exl_Restriction__c>([SELECT Id FROM Exl_Restriction__c WHERE Patron__c = :conId]);
		System.assert(res != null, 'Restriction records are created');
    }
}