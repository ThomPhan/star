/**
 * @description       : Test class for SalesCompController
 * @author            : Simplus
 * @group             : Simplus
 * @last modified on  : 22-08-2022
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   22-08-2022   Simplus                      Initial Version
 */
@isTest
public class SalesCompControllerTest {
    static final String SALES_COMP_RECORD_TYPE_NAME_CD_CP = 'CD_CP';
    static final String SALES_COMP_RECORD_TYPE_NAME_SPV_MPV = 'SPV_MPV';
    static final String SALES_COMP_STATUS_APPROVED = 'Approved';

    @isTest static void getLoyaltyRecordTest() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.cc'
        );
        insert testContact;
        String contactId = testContact.Id;

        Loyalty_Program__c prog = new Loyalty_Program__c(Name = 'Gold Membership');
        insert prog;

        Decimal casinoBalance = 1000;
        Decimal compBalance = 2000;
        Loyalty__c loyalty = new Loyalty__c(
            Patron__c = contactId,
            Loyalty_Program__c = prog.Id,
            CasinoBalance__c = casinoBalance,
            CompBalance__c = compBalance
        );
        insert loyalty;

        Loyalty__c loyaltyRecord = new Loyalty__c();
        Test.startTest();
            loyaltyRecord = SalesCompController.getLoyaltyRecord(contactId);
        Test.stopTest();

        System.assertEquals(casinoBalance, loyaltyRecord.CasinoBalance__c);
        System.assertEquals(compBalance, loyaltyRecord.CompBalance__c);
    }

    @isTest static void getSalesCompsTotalTest() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@maildrop.cc'
        );
        insert testContact;
        String contactId = testContact.Id;

        Id cdCPrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_CD_CP).getRecordTypeId();
        Id spvMPVrtId = Schema.SObjectType.Sales_Comp__c.getRecordTypeInfosByDeveloperName().get(SALES_COMP_RECORD_TYPE_NAME_SPV_MPV).getRecordTypeId();

        List<Sales_Comp__c> salesComps = new List<Sales_Comp__c>();
        Decimal cdAmount = 100;
        Sales_Comp__c scCD = new Sales_Comp__c(
            Amount__c = cdAmount,
            Comp_Type__c = 'Casino Dollar',
            Contact__c = contactId,
            RecordTypeId = cdCPrtId
        );
        salesComps.add(scCD);

        Decimal spvAmount = 200;
        Sales_Comp__c scSPV = new Sales_Comp__c(
            Amount__c = spvAmount,
            Comp_Type__c = 'SPV',
            Contact__c = contactId,
            RecordTypeId = spvMPVrtId
        );
        salesComps.add(scSPV);
        insert salesComps;

        for (Sales_Comp__c sc: salesComps) {
            sc.Status__c = SALES_COMP_STATUS_APPROVED;
        }
        update salesComps;

        SalesCompController.ContactRecordWrapper wrapper = new SalesCompController.ContactRecordWrapper();
        Test.startTest();
            wrapper = SalesCompController.getSalesCompsTotal(contactId);
        Test.stopTest();

        System.assertEquals(cdAmount, wrapper.cdCPtotal);
        System.assertEquals(spvAmount, wrapper.spvMPVtotal);
    }
}