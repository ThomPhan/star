@isTest
private class AutoCreatedRegHandlerTest {
    static testMethod void testCreateAndUpdateUser() {
        AutocreatedRegHandler1714102117099 handler = new AutocreatedRegHandler1714102117099();
        Account acc = new Account();
        acc.Name = 'Test acc';
        insert acc;
        acc = [Select Id,OwnerId from Account LIMIT 1];
        Contact con = new Contact();
        con.FirstName = 'Test First';
        con.LastName = 'Test Last';
        con.Email = 'test@test.com';
        con.Patron_ID__c = 'testId';
        con.AccountId = acc.Id;
        con.Loyalty_Program__c = 'Social';
        con.Tier__c = 'Social';
        insert con;
        Contact con1 = new Contact();
        con1.FirstName = 'Test First';
        con1.LastName = 'Test Last';
        con1.Email = 'test@test.com';
        con1.Patron_ID__c = 'testId1';
        con1.AccountId = acc.Id;
        con1.Loyalty_Program__c = 'Social';
        con1.Tier__c = 'Social';
        insert con1;
        Contact con2 = new Contact();
        con2.FirstName = 'Test First';
        con2.LastName = 'Test Last';
        con2.Email = '';
        con2.Patron_ID__c = 'testId2';
        con2.AccountId = acc.Id;
        con2.Loyalty_Program__c = 'Social';
        con2.Tier__c = 'Social';
        insert con2;
    	
        // Create sample Auth.UserData with additional attributes in the attributeMap
        Auth.UserData sampleData = new Auth.UserData(
            'testId', 
            'testFirst', 
            'testLast', 
            'testFirst testLast', 
            'testuser@example.org', 
            null, 
            'testuserlong', 
            'en_US', 
            'Ping One IDP',
            null, 
            new Map<String, String>{
                'language' => 'en_US',
                    'site' => 'test',
                    'access_Token' => 'sampleAccessToken',
                    'id_Token' => 'sampleIdToken',
                    'email_verified' => 'true',
                    'phone_number_verified' => 'false'
                    }
        );

        Id portalId = null;
    
        User u = handler.createUser(portalId, sampleData);
    
        System.assertEquals('testuser@example.org', u.email);
    
        System.assertEquals('testLast', u.lastName);
    
        System.assertEquals('testFirst', u.firstName);
    
        System.assertEquals('ttes', u.alias);
    
        //insert(u);
    
        String uid = u.id;
    
        sampleData = new Auth.UserData('testNewId', 'testNewFirst', 'testNewLast',
    
            'testNewFirst testNewLast', 'testnewuser@example.org', null, 'testnewuserlong', 'en_US', 'facebook',
    
            null, new Map<String, String>{'language' => 'en_US'});
    
        handler.updateUser(uid, null, sampleData);
    
        User updatedUser = [SELECT userName, email, firstName, lastName, alias FROM user WHERE id=:uid];
    
        //System.assertEquals('testnewuserlong@acmecorp.com', updatedUser.userName);
    
        System.assertEquals('testuser@example.org', updatedUser.email);
    
        System.assertEquals('testLast', updatedUser.lastName);
    
        System.assertEquals('testFirst', updatedUser.firstName);
    
        //System.assertEquals('testnewu', updatedUser.alias);
        
        Auth.UserData sampleData1 = new Auth.UserData(
            'testId1', 
            '1testFirst', 
            '1testLast', 
            '1testFirst testLast', 
            '',  // No email provided in this case
            null, 
            '1testuserlong', 
            'en_US', 
            'Ping One IDP',
            null, 
            new Map<String, String>{
                'language' => 'en_US',
                    'site' => 'test',
                    'access_Token' => 'sampleAccessToken1',
                    'id_Token' => 'sampleIdToken1',
                    'email_verified' => 'false', // Assuming email is not verified
                    'phone_number_verified' => 'true' // Assuming phone number is verified
                    }
        );

        
        Id portalId1 = null;
    
        User u1 = handler.createUser(portalId1, sampleData1);
        
        // Create another sample Auth.UserData with required attributes in the attributeMap
        Auth.UserData sampleData2 = new Auth.UserData(
            'testId2', 
            '2testFirst', 
            '2testLast', 
            '2testFirst testLast', 
            '',  // No email provided in this case
            null, 
            '2testuserlong', 
            'en_US', 
            'Ping One IDP',
            null, 
            new Map<String, String>{
                'language' => 'en_US',
                    'site' => 'test',
                    'access_Token' => 'sampleAccessToken2',
                    'id_Token' => 'sampleIdToken2',
                    'email_verified' => 'true', // Assuming email is verified
                    'phone_number_verified' => 'false' // Assuming phone number is not verified
                    }
        );
    
        Id portalId2 = null;
    
        User u2 = handler.createUser(portalId2, sampleData2);
    }

}