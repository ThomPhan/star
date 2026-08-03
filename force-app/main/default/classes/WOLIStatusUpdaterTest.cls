@isTest
private class WOLIStatusUpdaterTest {

    @isTest
    static void testUpdateWOLIStatusBasedOnDocuments() {
        // Create test data
        Contact con = new Contact(LastName = 'Test Contact');
        insert con;

        Case testCase = new Case(ContactId = con.Id, Subject = 'Test Case');
        insert testCase;

        Exl_Exclusion__c exclusion = new Exl_Exclusion__c(
            ApplyCase__c = testCase.Id,
            Jurisdiction__c = 'NSW'
        );
        insert exclusion;

        WorkOrder wo = new WorkOrder(
            CaseId = testCase.Id,
            Jurisdiction__c = 'NSW',
            Status = 'New'
        );
        insert wo;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Line_Item_Type__c = 'Generate Document',
            Status = 'New',
            Documents_to_be_generated__c = 'Doc A;Doc B'
        );
        insert woli;

        // Create ContentDocument and ContentDocumentLink
        ContentVersion cv1 = new ContentVersion(
            Title = 'Doc A',
            PathOnClient = 'DocA.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv1;

        ContentVersion cv2 = new ContentVersion(
            Title = 'Doc B',
            PathOnClient = 'DocB.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv2;

        ContentDocument cd1 = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv1.Id];
        ContentDocument cd2 = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv2.Id];

        ContentDocumentLink link1 = new ContentDocumentLink(
            ContentDocumentId = cd1.Id,
            LinkedEntityId = exclusion.Id,
            ShareType = 'V'
        );
        ContentDocumentLink link2 = new ContentDocumentLink(
            ContentDocumentId = cd2.Id,
            LinkedEntityId = exclusion.Id,
            ShareType = 'V'
        );
        insert new List<ContentDocumentLink>{link1, link2};

        Test.startTest();
        WOLIStatusUpdater.updateWOLIStatusBasedOnDocuments(new Set<Id>{exclusion.Id});
        Test.stopTest();

        // Verify the status update
        WorkOrderLineItem updatedWOLI = [SELECT Status FROM WorkOrderLineItem WHERE Id = :woli.Id];
        System.assertEquals('Completed', updatedWOLI.Status, 'WOLI status should be updated to Completed');
    }
}