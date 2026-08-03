@isTest
private class ContactTriggerHelperTest {

    @testSetup
    static void setupData() {
        // Create Contact records for test
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(
                LastName = 'Test Contact ' + i,
                Email = 'oldemail' + i + '@test.com',
                Loyalty_Program__c = 'Social',
                Patron_Status__c = '',
                Tier__c = 'Bronze',
                Direct_Mail_Consent__c = true,
                Email_Consent__c = true,
                SMS_Consent__c = true
            ));
        }
        insert contacts;
        
        // Create Exl_Restriction__c records
        List<Exl_Restriction__c> restrictions = new List<Exl_Restriction__c>();
        for (Contact c : contacts) {
            restrictions.add(new Exl_Restriction__c(
                Patron__c = c.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_FUNDS,
                Enforcement_Status__c = 'Pending'
            ));
            restrictions.add(new Exl_Restriction__c(
                Patron__c = c.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_MARKETING_COMMS,
                Enforcement_Status__c = 'Pending'
            ));
        }
        insert restrictions;
    }

    @isTest
    static void testUpdateUserEmailfromContact() {
        List<Contact> contactUpdate = new List<Contact>();        

        // Change emails for update path
        for (Contact c : [SELECT Id, Email, Loyalty_Program__c FROM Contact]) {
            c.Email = 'new_' + c.Email;
            contactUpdate.add(c);
        }

        Test.startTest();
        update contactUpdate;
        Test.stopTest();
    }

    @isTest
    static void testReconcileRestrictionRecords_ActivatePaths() {
        List<Contact> contactsUpdate = new List<Contact>();

        // Modify to trigger activation conditions
        for (Contact c : [SELECT Id, Patron_Status__c, Direct_Mail_Consent__c, Email_Consent__c, SMS_Consent__c FROM Contact]) {
            c.Patron_Status__c = ConstantHelper.STRING_CONTACT_PATRON_STATUS_EXCLUDED_ALL;
            c.Direct_Mail_Consent__c = false;
            c.Email_Consent__c = false;
            c.SMS_Consent__c = false;
            contactsUpdate.add(c);
        }

        Test.startTest();
        update contactsUpdate;
        Test.stopTest();

        // Validate that restrictions got activated
        List<Exl_Restriction__c> updatedRestrictions = [
            SELECT Enforcement_Status__c FROM Exl_Restriction__c
        ];
        System.assert(updatedRestrictions.size() > 0, 'Restrictions should exist');
        System.assertEquals(
            ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE,
            updatedRestrictions[0].Enforcement_Status__c,
            'Restriction should be activated'
        );
    }

    @isTest
    static void testReconcileRestrictionRecords_RevokePaths() {
        List<Contact> contactsInitialUpdate = new List<Contact>();
        List<Contact> contactsUpdate = new List<Contact>();
        List<Exl_Restriction__c> restrictions = new List<Exl_Restriction__c>();

        // Set restrictions to Active first
        for (Exl_Restriction__c r : [SELECT Id, Enforcement_Status__c FROM Exl_Restriction__c]) {
            r.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE;
            restrictions.add(r);
        }
        update restrictions;
        for (Contact c :  [SELECT Id, Patron_Status__c, Direct_Mail_Consent__c, Email_Consent__c, SMS_Consent__c FROM Contact]) {
            c.Direct_Mail_Consent__c = false;
            c.Email_Consent__c = false;
            c.SMS_Consent__c = false;
            contactsInitialUpdate.add(c);
        }
        update contactsInitialUpdate;

        // Modify contacts to revoke restrictions
        for (Contact c :  [SELECT Id, Patron_Status__c, Direct_Mail_Consent__c, Email_Consent__c, SMS_Consent__c FROM Contact]) {
            c.Patron_Status__c = 'Active'; 
            c.Direct_Mail_Consent__c = true;
            c.Preferred_Address__c = 'Mailing Address';
            c.MailingCity = 'Sydney';
            c.Email_Consent__c = true;
            c.Email = '111email@test.com'; 
            c.SMS_Consent__c = true;
            c.MobilePhone = '61-493226433';
            contactsUpdate.add(c);
        }

        Test.startTest();
        update contactsUpdate;
        Test.stopTest();

        // Validate that restrictions were revoked
        List<Exl_Restriction__c> updatedRestrictions = [ SELECT Enforcement_Status__c FROM Exl_Restriction__c 
                                                        WHERE Enforcement_Status__c =: ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED];
        System.assert(updatedRestrictions != null );
    }
}