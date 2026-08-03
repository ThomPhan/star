@IsTest
private class ExclusionTriggerService_Tests {
    // Utility: create a Contact and return Id
    private static Id createContact() {
        Contact c = new Contact(LastName = 'Test Contact');
        insert c;
        return c.Id;
    }

    // Utility: create an Exl_Exclusion__c record with a given status and contact
    private static Exl_Exclusion__c createExclusion(Id contactId, String statusVal) {
        Exl_Exclusion__c ex = new Exl_Exclusion__c(
            Contact__c = contactId,
            Status__c = statusVal
        );
        insert ex;
        return ex;
    }

    // Build a map<Id, SObject> for convenience
    private static Map<Id, SObject> toMap(List<SObject> records) {
        Map<Id, SObject> m = new Map<Id, SObject>();
        for (SObject s : records) {
            m.put((Id) s.get('Id'), s);
        }
        return m;
    }
/*
    @IsTest
    static void testAfterUndelete_Publishes_WhenStatusRevoked() {
        Id contactId = createContact();
        Exl_Exclusion__c ex = createExclusion(contactId, 'Revoked');

        delete ex;
        
        Test.startTest();
		undelete ex;
        Test.stopTest();
        
    }*/
    
    @IsTest
    static void testAfterUndelete_HandlerOnly_NoDeleteDml() {
        Contact c = new Contact(LastName='Test', Email='contact.recipient@example.com');
        insert c;
        
        Exl_Exclusion__c ex = new Exl_Exclusion__c(Contact__c=c.Id, Status__c='Revoked');
        insert ex;
        
        ExclusionTriggerService svc = new ExclusionTriggerService('Exl_Exclusion__c');
        
        Map<Id, SObject> m = new Map<Id, SObject>{ ex.Id => ex };
            
            Test.startTest();
        svc.afterUndelete(new List<SObject>{ ex }, m);
        Test.stopTest();
    }
    @IsTest
    static void testAfterDelete_HandlerOnly_NoDeleteDml() {
        Contact c = new Contact(LastName='Test', Email='contact.recipient@example.com');
        insert c;
        
        Exl_Exclusion__c ex = new Exl_Exclusion__c(Contact__c=c.Id, Status__c='Revoked');
        insert ex;
        
        ExclusionTriggerService svc = new ExclusionTriggerService('Exl_Exclusion__c');
        
        Map<Id, SObject> m = new Map<Id, SObject>{ ex.Id => ex };
            
            Test.startTest();
        svc.afterDelete(new List<SObject>{ ex }, m);
        Test.stopTest();
    }
}