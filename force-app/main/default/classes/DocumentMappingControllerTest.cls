@isTest
private class DocumentMappingControllerTest {

    @TestSetup
    static void setupData() {
        // Create a Contact
        Contact contact = new Contact(LastName = 'Test Contact');
        insert contact;

        // Create a Case
        Case testCase = new Case(Status = 'New', Origin = 'Phone');
        insert testCase;

        // Create an Exclusion linked to the Case and Contact
        Exl_Exclusion__c exclusion = new Exl_Exclusion__c(
            ApplyCase__c = testCase.Id,
            Contact__c = contact.Id,
            Jurisdiction__c = 'NSW'
        );
        insert exclusion;
        
        // Create content
        ContentVersion cv = new ContentVersion();
        cv.Title = 'DocumentA';
        cv.PathOnClient = 'DocumentA.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.FirstPublishLocationId = exclusion.Id;
        insert cv;        
    }

    @isTest
    static void testValidInput() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<String> documentNames = new List<String>{'DocumentA'};
        String deletedDocu = 'DocumentB';
        String WOState = 'NSW';

        Test.startTest();
        Map<String, String> result = DocumentMappingController.getDocumentUrlMap(testCase.Id, documentNames, WOState, deletedDocu);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected non-null result map');
    }

    @isTest
    static void testMissingInputs() {
        Boolean exceptionThrown = false;

        try {
            DocumentMappingController.getDocumentUrlMap(null, null, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException for missing inputs');
    }

    @isTest
    static void testNoExclusionRecord() {
        Case newCase = new Case(Status = 'New', Origin = 'Email');
        insert newCase;

        Boolean exceptionThrown = false;
        String deletedDocu = 'DocumentB';

        try {
            DocumentMappingController.getDocumentUrlMap(newCase.Id, new List<String>{'DocX'}, 'NSW', deletedDocu);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException for missing exclusion');
    }

    @isTest
    static void testExclusionWithoutContact() {
        Case testCase = new Case(Status = 'New', Origin = 'Web');
        insert testCase;

        Exl_Exclusion__c exclusion = new Exl_Exclusion__c(
            ApplyCase__c = testCase.Id,
            Jurisdiction__c = 'NSW'
        );
        insert exclusion;

        Boolean exceptionThrown = false;
        String deletedDocu = 'DocumentB';

        try {
            DocumentMappingController.getDocumentUrlMap(testCase.Id, new List<String>{'DocY'}, 'NSW', deletedDocu);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException for missing contact');
    }

    @isTest
    static void testUpdateWorkOrderLineItemStatus() {
        Case testCase = new Case(Status = 'In Progress', Origin = 'Phone');
        insert testCase;
        String WOState = 'NSW';

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'In Progress',
            CaseId = testCase.Id,
            Jurisdiction__c = WOState
        );
        insert wo;

        WorkOrderLineItem item1 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Generate Document',
            Status = 'New'
        );
        WorkOrderLineItem item2 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Generate Document',
            Status = 'In Progress'
        );
        insert new List<WorkOrderLineItem>{item1, item2};

        Test.startTest();
        DocumentMappingController.updateWorkOrderLineItemStatus(testCase.Id, WOState);
        Test.stopTest();

        List<WorkOrderLineItem> updatedItems = [
            SELECT Status FROM WorkOrderLineItem WHERE Id IN :new List<Id>{item1.Id, item2.Id}
        ];

        for (WorkOrderLineItem item : updatedItems) {
            System.assertEquals('In Progress', item.Status);
        }
    }

    @isTest
    static void testCompleteWorkOrderLineItems() {
        Case testCase = new Case(Status = 'In Progress', Origin = 'Phone');
        insert testCase;
        String WOState = 'NSW';

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'In Progress',
            CaseId = testCase.Id,
            Jurisdiction__c = WOState
        );
        insert wo;

        WorkOrderLineItem item = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Generate Document',
            Status = 'New'
        );
        insert item;

        Test.startTest();
        DocumentMappingController.completeWorkOrderLineItems(testCase.Id, WOState);
        Test.stopTest();

        WorkOrderLineItem updatedItem = [SELECT Status FROM WorkOrderLineItem WHERE Id = :item.Id];
        System.assertEquals('Completed', updatedItem.Status);
    }

    @isTest
    static void testUpdateWorkOrderLineItemStatus_NoWorkOrder() {
        Case testCase = new Case(Status = 'New', Origin = 'Phone');
        insert testCase;

        Boolean exceptionThrown = false;

        try {
            DocumentMappingController.updateWorkOrderLineItemStatus(testCase.Id, 'NSW');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected exception when no WorkOrder found');
    }   

    @isTest
    static void testvalidateDocument() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String documentNames = 'DocumentA';
        String WOState = 'NSW';

        Test.startTest();
        String result1 = DocumentMappingController.validateDuplicateDocument(testCase.Id, WOState, documentNames);
        Test.stopTest();

        System.assertNotEquals(null, result1, 'Expected non-null result map');        
    }

    @isTest
    static void testvalidateDocumentNULL() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String result1;
        Boolean exceptionThrown = false;

        Test.startTest();
        
        try {
        	result1 = DocumentMappingController.validateDuplicateDocument(testCase.Id, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
		System.assert(exceptionThrown, 'Error validateDuplicateDocument.');
    }

    @isTest
    static void testvalidateDocumentNULLCase() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String result1;
        Boolean exceptionThrown = false;

        Test.startTest();
        
        try {
        	result1 = DocumentMappingController.validateDuplicateDocument(null, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        try {
        	DocumentMappingController.completeWorkOrderLineItems(null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        try {
        	DocumentMappingController.completeWorkOrderLineItems(testCase.Id, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
		System.assert(exceptionThrown, 'Missing Case Id.');
    }
}