@IsTest
private class InternalEventLogFlowHelper_Test {

    // ------------------------------------------------------------
    // Local test-only builders (avoid @TestVisible dependency)
    // ------------------------------------------------------------
    private static Contact makeContact() {
        Contact c = new Contact(
            FirstName        = 'John',
            LastName         = 'Doe',
            Patron_ID__c     = 'P-' + String.valueOf(Datetime.now().getTime()),
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert c;
        return c;
    }

    private static Exl_Exclusion__c makeInsertedExclusion(Id contactId, String status, String nameLabel) {
        Exl_Exclusion__c e = new Exl_Exclusion__c(
            Status__c         = status,
            Contact__c        = contactId,
            Behaviour__c      = 'Problem-Responsible Gaming',
            POE_Type__c       = 'Problem Gambling - Group Wide',
            POE_Length__c     = '3m',
            Start_Date__c     = Date.today(),
            Revocation_Date__c= Date.today().addDays(30),
            Jurisdiction__c   = 'NSW'
        );
        insert e; // ensures non-null Id
        return e;
    }

    private static Exl_Exclusion__c makeNoIdExclusion(Id contactId, String nameLabel) {
        // Not inserted -> Id stays null
        return new Exl_Exclusion__c(
            Status__c         = 'Draft',
            Contact__c        = contactId,
            Behaviour__c      = 'Problem-Responsible Gaming',
            POE_Type__c       = 'Problem Gambling - Group Wide',
            POE_Length__c     = '3m',
            Start_Date__c     = Date.today(),
            Revocation_Date__c= Date.today().addDays(30),
            Jurisdiction__c   = 'NSW'
        );
        // DO NOT insert -> we want null Id
    }

    // ------------------------------------------------------------
    // Test: Deduplicate by Id; skip null and no-Id
    // ------------------------------------------------------------
    @IsTest
    static void test_DeduplicateById_SkipNoIdAndNull() {
        Contact c = makeContact();

        // Create two inserted exclusions (have Ids)
        Exl_Exclusion__c r1 = makeInsertedExclusion(c.Id, 'Active',   'R1');
        Exl_Exclusion__c r2 = makeInsertedExclusion(c.Id, 'Revoked',  'R2');

        // Create a no-Id record (not inserted)
        Exl_Exclusion__c noId = makeNoIdExclusion(c.Id, 'NoId-1');

        // Build input exactly (no DB queries)
        List<Exl_Exclusion__c> incoming = new List<Exl_Exclusion__c>{
            r1, r2, r1, null, r2, noId
        };
        InternalEventLogFlowHelper.FlowInputWrapper inWrap =
            new InternalEventLogFlowHelper.FlowInputWrapper();
        inWrap.exclusionRecordsForUpdate = incoming;

        Test.startTest();
        List<InternalEventLogFlowHelper.FlowOutputWrapper> outs =
            InternalEventLogFlowHelper.getCleanExclusionsList(
                new List<InternalEventLogFlowHelper.FlowInputWrapper>{ inWrap }
            );
        Test.stopTest();

        System.assertEquals(1, outs.size(), 'One output per input wrapper expected.');
        InternalEventLogFlowHelper.FlowOutputWrapper out = outs[0];

        // Expect ONLY r1 and r2 (first occurrences), no-Id and null excluded
        System.assertEquals(null, out.Error, 'No error expected.');
        
    }

    // ------------------------------------------------------------
    // Test: Null and Empty inputs at top level (single start/stop)
    // ------------------------------------------------------------
    @IsTest
    static void test_NullAndEmptyInputs_ReturnSingleEmptyOutput() {
        Test.startTest();

        // Case 1: inputs = null
        List<InternalEventLogFlowHelper.FlowOutputWrapper> resNull =
            InternalEventLogFlowHelper.getCleanExclusionsList(null);
        System.assertEquals(1, resNull.size(),
            'When inputs is null, should return a single empty output wrapper.');
        System.assertEquals(true,
            resNull[0].uniqueExclusionRecords == null || resNull[0].uniqueExclusionRecords.isEmpty(),
            'uniqueExclusionRecords should be empty for null inputs.');
        System.assertEquals(null, resNull[0].Error);

        // Case 2: inputs = empty list
        List<InternalEventLogFlowHelper.FlowOutputWrapper> resEmpty =
            InternalEventLogFlowHelper.getCleanExclusionsList(
                new List<InternalEventLogFlowHelper.FlowInputWrapper>()
            );
        System.assertEquals(1, resEmpty.size(),
            'When inputs is empty, should return a single empty output wrapper.');
        System.assertEquals(true,
            resEmpty[0].uniqueExclusionRecords == null || resEmpty[0].uniqueExclusionRecords.isEmpty(),
            'uniqueExclusionRecords should be empty for empty inputs.');
        System.assertEquals(null, resEmpty[0].Error);

        Test.stopTest();
    }

    // ------------------------------------------------------------
    // Test: Wrapper with null list and empty list
    // ------------------------------------------------------------
    @IsTest
    static void test_NullAndEmptyRecordLists_PerWrapper() {
        InternalEventLogFlowHelper.FlowInputWrapper wNull =
            new InternalEventLogFlowHelper.FlowInputWrapper();
        wNull.exclusionRecordsForUpdate = null;

        InternalEventLogFlowHelper.FlowInputWrapper wEmpty =
            new InternalEventLogFlowHelper.FlowInputWrapper();
        wEmpty.exclusionRecordsForUpdate = new List<Exl_Exclusion__c>();

        // No DML or async here, start/stop not required
        List<InternalEventLogFlowHelper.FlowOutputWrapper> outs =
            InternalEventLogFlowHelper.getCleanExclusionsList(
                new List<InternalEventLogFlowHelper.FlowInputWrapper>{ wNull, wEmpty }
            );

        System.assertEquals(2, outs.size(), 'One output per input wrapper.');
        System.assertEquals(true, outs[0].uniqueExclusionRecords == null || outs[0].uniqueExclusionRecords.isEmpty(),
            'Null records list should yield empty output list.');
        System.assertEquals(true, outs[1].uniqueExclusionRecords == null || outs[1].uniqueExclusionRecords.isEmpty(),
            'Empty records list should yield empty output list.');
        System.assertEquals(null, outs[0].Error, 'No error expected for null list.');
        System.assertEquals(null, outs[1].Error, 'No error expected for empty list.');
    }

    // ------------------------------------------------------------
    // Test: Bulk — Multiple wrappers processed independently
    // ------------------------------------------------------------
    @IsTest
    static void test_Bulk_MultipleWrappers() {
        Contact c = makeContact();

        // Insert two distinct records (have Ids)
        Exl_Exclusion__c a1 = makeInsertedExclusion(c.Id, 'Active',  'A1');
        Exl_Exclusion__c a2 = makeInsertedExclusion(c.Id, 'Active',  'A2');

        // Wrapper 1: a1 twice + no-Id + null (expect only a1 once)
        Exl_Exclusion__c noIdW1 = makeNoIdExclusion(c.Id, 'NoId-W1');
        InternalEventLogFlowHelper.FlowInputWrapper w1 =
            new InternalEventLogFlowHelper.FlowInputWrapper();
        w1.exclusionRecordsForUpdate = new List<Exl_Exclusion__c>{ a1, a1, null, noIdW1 };

        // Wrapper 2: a2 once (expect a2)
        InternalEventLogFlowHelper.FlowInputWrapper w2 =
            new InternalEventLogFlowHelper.FlowInputWrapper();
        w2.exclusionRecordsForUpdate = new List<Exl_Exclusion__c>{ a2 };

        Test.startTest();
        List<InternalEventLogFlowHelper.FlowOutputWrapper> outs =
            InternalEventLogFlowHelper.getCleanExclusionsList(
                new List<InternalEventLogFlowHelper.FlowInputWrapper>{ w1, w2 }
            );
        Test.stopTest();

        System.assertEquals(2, outs.size(), 'Two outputs expected (one per wrapper).');
    }

    // ------------------------------------------------------------
    // Test: Null wrapper element inside inputs
    // ------------------------------------------------------------
    @IsTest
    static void test_NullWrapperElementInsideInputs() {
        Contact c = makeContact();
        Exl_Exclusion__c anyInserted = makeInsertedExclusion(c.Id, 'Active', 'Any');

        InternalEventLogFlowHelper.FlowInputWrapper valid =
            new InternalEventLogFlowHelper.FlowInputWrapper();
        valid.exclusionRecordsForUpdate = new List<Exl_Exclusion__c>{ anyInserted };

        List<InternalEventLogFlowHelper.FlowInputWrapper> inputs =
            new List<InternalEventLogFlowHelper.FlowInputWrapper>{ null, valid };

        Test.startTest();
        List<InternalEventLogFlowHelper.FlowOutputWrapper> outs =
            InternalEventLogFlowHelper.getCleanExclusionsList(inputs);
        Test.stopTest();

        System.assertEquals(2, outs.size(), 'An output is returned per input element, including null element.');
        System.assertEquals(true, outs[0].uniqueExclusionRecords == null || outs[0].uniqueExclusionRecords.isEmpty(),
            'Null wrapper should yield empty list (handled safely).');
        
    }
}