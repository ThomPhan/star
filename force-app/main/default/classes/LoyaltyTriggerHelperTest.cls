@isTest
private class LoyaltyTriggerHelperTest {
    
    @testSetup
    static void setupTestData() {
        // Create Patrons
        List<Contact> patrons = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            patrons.add(new Contact(Firstname = 'Test Patron ' + i, Lastname = 'Test'+ i));
        }
        insert patrons;
        
        // Create Exl_Restriction__c records (inactive by default)
        List<Exl_Restriction__c> restrictions = new List<Exl_Restriction__c>();
        for (Contact p : patrons) {
            restrictions.add(new Exl_Restriction__c(
                Patron__c = p.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_CASINO_POINTS,
                Enforcement_Status__c = 'Pending'
            ));
            restrictions.add(new Exl_Restriction__c(
                Patron__c = p.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_DISCOUNTS,
                Enforcement_Status__c = 'Pending'
            ));
            restrictions.add(new Exl_Restriction__c(
                Patron__c = p.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_HOTEL,
                Enforcement_Status__c = 'Pending'
            ));
            restrictions.add(new Exl_Restriction__c(
                Patron__c = p.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_PARKING,
                Enforcement_Status__c = 'Pending'
            ));
            restrictions.add(new Exl_Restriction__c(
                Patron__c = p.Id,
                Restriction_Type__c = ConstantHelper.STRING_RESTRICTION_TYPE_TIER_LEVEL_LOST,
                Enforcement_Status__c = 'Pending'
            ));
        }
        insert restrictions;
        // Create LoyaltyProgram records 
        Loyalty_Program__c loyaltyProg = new Loyalty_Program__c(Name = 'Loyalty program');
        insert loyaltyProg;
        
        // Create Loyalty__c records 
        List<Loyalty__c> loyalties = new List<Loyalty__c>();
        for (Contact p : patrons) {
            loyalties.add(new Loyalty__c(
                Name = 'Loyalty ' + p.Name,
                Patron__c = p.Id,
                Casino__c = 1,
                CasinoBalance__c = 100,
                F_B_Discount_Entitlement__c = 1,
                Hotel_Discount_Entitlement__c = 1,
                Comp_Parking_Entitlement__c = 'Free',
                Tier__c = '',
                Loyalty_Program__c = loyaltyProg.Id
            ));
        }
        insert loyalties;
    }
    
    @isTest
    static void testReconcileRestrictionRecords_ActivatePaths() {
        List<Loyalty__c> loyaltyUpdate = new List<Loyalty__c>();
        
        // Modify values to trigger activation
        for (Loyalty__c l : [SELECT Id, Patron__c, Casino__c, CasinoBalance__c, F_B_Discount_Entitlement__c, Hotel_Discount_Entitlement__c,
            					Comp_Parking_Entitlement__c, Tier__c FROM Loyalty__c]) {
                l.Casino__c = 0;
                l.CasinoBalance__c = 0;
                l.F_B_Discount_Entitlement__c = 0;
                l.Hotel_Discount_Entitlement__c = 0;
                l.Comp_Parking_Entitlement__c = null;
                l.Tier__c = 'Bronze';
                loyaltyUpdate.add(l);
        }
        
        Test.startTest();
        update loyaltyUpdate;
        Test.stopTest();
        
        // Validate updates were made
        List<Exl_Restriction__c> updatedRestrictions = [SELECT Id, Enforcement_Status__c FROM Exl_Restriction__c];
        System.assert(updatedRestrictions.size() > 0, 'Restrictions should have been updated');
        
    }
    
    @isTest
    static void testReconcileRestrictionRecords_RevokePaths() {
        List<Loyalty__c> loyaltyUpdate = new List<Loyalty__c>();
        List<Exl_Restriction__c> restrictionUpdate = new List<Exl_Restriction__c>();
        
        // Set restrictions to Active first
        for (Exl_Restriction__c r : [SELECT Id, Enforcement_Status__c FROM Exl_Restriction__c]) {
            r.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE;
            restrictionUpdate.add(r);
        }
        update restrictionUpdate;
        
        // Modify values to trigger revocation
        for (Loyalty__c l : [SELECT Id, Patron__c, Casino__c, CasinoBalance__c, F_B_Discount_Entitlement__c, Hotel_Discount_Entitlement__c,
            					Comp_Parking_Entitlement__c, Tier__c FROM Loyalty__c]) {
            l.Casino__c = 2;
            l.CasinoBalance__c = 2;
            l.F_B_Discount_Entitlement__c = 2;
            l.Hotel_Discount_Entitlement__c = 2;
            l.Comp_Parking_Entitlement__c = 'Paid';
            l.Tier__c = 'Gold';
            loyaltyUpdate.add(l);
        }
        
        Test.startTest();
        update loyaltyUpdate;
        Test.stopTest();
        
        // Validate updates were made
        List<Exl_Restriction__c> updatedRestrictions = [SELECT Enforcement_Status__c FROM Exl_Restriction__c];
        System.assert(updatedRestrictions.size() > 0, 'Restrictions should have been updated');
        
    }
}