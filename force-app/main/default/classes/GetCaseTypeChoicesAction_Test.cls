@IsTest
private class GetCaseTypeChoicesAction_Test {

    @testSetup
    static void setupUsers() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        insert new User(
            FirstName = 'CaseType', LastName = 'HasPerms',
            Alias = 'cthp',
            Email = 'cthp+' + System.currentTimeMillis() + '@example.com',
            Username = 'cthp+' + System.currentTimeMillis() + '@example.com',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );

        insert new User(
            FirstName = 'CaseType', LastName = 'NoPerms',
            Alias = 'ctnp',
            Email = 'ctnp+' + System.currentTimeMillis() + '@example.com',
            Username = 'ctnp+' + System.currentTimeMillis() + '@example.com',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    }

    private static Id userIdByAlias(String alias) {
        return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1].Id;
    }

    @IsTest
    static void test_NullAndEmptyInputs() {
        
        List<GetCaseTypeChoicesAction.Output> res1 = GetCaseTypeChoicesAction.getChoices(null);
        System.assertEquals(0, res1.size(), 'Null input => empty result.');

        List<GetCaseTypeChoicesAction.Output> res2 =
            GetCaseTypeChoicesAction.getChoices(new List<GetCaseTypeChoicesAction.Input>());
        System.assertEquals(0, res2.size(), 'Empty input => empty result.');
    }

    @IsTest
    static void test_NullElementsAndNullUserIds() {
        
        List<GetCaseTypeChoicesAction.Input> inputs = new List<GetCaseTypeChoicesAction.Input>{
            null, new GetCaseTypeChoicesAction.Input() // userId remains null
        };

        List<GetCaseTypeChoicesAction.Output> res = GetCaseTypeChoicesAction.getChoices(inputs);

        System.assertEquals(2, res.size(), 'Output per input element.');
        System.assertEquals(0, res[0].entries.size(), 'Null element => empty entries.');
        System.assertEquals(0, res[1].entries.size(), 'Null userId => empty entries.');
    }

    @IsTest
    static void test_MappingsSeam_CoversParsing_AndRemoveOutcome() {
        // Arrange
        Id userId = userIdByAlias('cthp');

        String suffix = String.valueOf(Datetime.now().getTime());
        String cpA = 'CP_A_' + suffix;
        String cpB = 'CP_B_' + suffix;

        // In-memory Custom Metadata (NO DML)
        Custom_Permissions_Case_Type_Mapping__mdt m1 =
            new Custom_Permissions_Case_Type_Mapping__mdt(
                DeveloperName = 'MapA_' + suffix,
                MasterLabel   = 'MapA ' + suffix,
                Custom_Permission_Name__c = cpA,
                Case_Types__c = ' Billing, Support , ,Technical, Billing '
            );

        Custom_Permissions_Case_Type_Mapping__mdt m2 =
            new Custom_Permissions_Case_Type_Mapping__mdt(
                DeveloperName = 'MapB_' + suffix,
                MasterLabel   = 'MapB ' + suffix,
                Custom_Permission_Name__c = cpB,
                Case_Types__c = 'Accounts, Support '
            );

        // Activate seam
        GetCaseTypeChoicesAction.TEST_MODE = true;
        GetCaseTypeChoicesAction.TEST_CUSTOM_PERMS = new List<String>{ cpA, cpB };
        GetCaseTypeChoicesAction.TEST_MAPPINGS = new List<Custom_Permissions_Case_Type_Mapping__mdt>{ m1, m2 };

        GetCaseTypeChoicesAction.Input input = new GetCaseTypeChoicesAction.Input();
        input.userId = userId;

        
        input.flowName = ConstantHelper.STRING_APPLY_EXCLUSION_FLOW;

        // Optional: verify removeOutcome behavior too
        input.removeOutcome = 'Support';

        // Act
        Test.startTest();
        List<GetCaseTypeChoicesAction.Output> outputs =
            GetCaseTypeChoicesAction.getChoices(new List<GetCaseTypeChoicesAction.Input>{ input });
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'One output for one input.');

        List<String> actual = new List<String>();
        for (PicklistEntryValue pev : outputs[0].entries) actual.add(pev.value);

        // After removeOutcome='Support', Support should be excluded
        System.assertEquals(
            new List<String>{ 'Accounts', 'Billing', 'Technical' },
            actual,
            'Should parse, trim, de-dup, sort, and remove the requested outcome.'
        );
    }

    @IsTest
    static void test_CustomPermissionUtils_EmptyPath() {
        // This is fine as-is; it asserts the util returns empty list in tests
        Id userId = userIdByAlias('cthp');

        Test.startTest();
        List<String> perms = CustomPermissionUtils.getCustomPermissionsForUser(userId);
        Test.stopTest();

        System.assertNotEquals(null, perms, 'Should return a list, not null.');
        System.assertEquals(0, perms.size(), 'No permissions expected in test context.');
    }
    
// Utility to create a minimal, active User for testing
    private static User createTestUser() {
        Profile p = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'Standard User' 
            LIMIT 1
        ];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser+' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    @IsTest
    static void getChoices_singleInput_returnsOutput() {
        User u = createTestUser();

        CustomPermissionUtils.Input inRec = new CustomPermissionUtils.Input();
        inRec.userId = u.Id;
        List<CustomPermissionUtils.Input> inputs = new List<CustomPermissionUtils.Input>{ inRec };

        Test.startTest();
        List<CustomPermissionUtils.Output> results =
            CustomPermissionUtils.getChoices(inputs);
        Test.stopTest();
    }

}