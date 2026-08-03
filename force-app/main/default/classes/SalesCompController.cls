/**
 * @description       : Controller class for salesCompLWC
 * @author            : Simplus
 * @group             : Simplus
 * @last modified on  : 22-08-2022
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   22-08-2022   Simplus                      Initial Version
 */
public with sharing class SalesCompController {
    static final String SALES_COMP_RECORD_TYPE_NAME_CD_CP = 'CD_CP';
    static final String SALES_COMP_RECORD_TYPE_NAME_SPV_MPV = 'SPV_MPV';
    static final String SALES_COMP_RECORD_TYPE_NAME_GIFT = 'Gift';    
    static final String SALES_COMP_STATUS_APPROVED = 'Approved';

    public class ContactRecordWrapper {
        @AuraEnabled public Decimal cdCPtotal { get; set; }
        @AuraEnabled public Decimal spvMPVtotal { get; set; }
        @AuraEnabled public Decimal giftTotal { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static Loyalty__c getLoyaltyRecord(String contactId) {
        Loyalty__c loyalty = new Loyalty__c();
        loyalty = [SELECT CasinoBalance__c, CompBalance__c
                   FROM Loyalty__c
                   WHERE Patron__c = :contactId
                   LIMIT 1];
        return loyalty;
    }

    @AuraEnabled(cacheable=true)
    public static ContactRecordWrapper getSalesCompsTotal(String contactId) {
        ContactRecordWrapper wrapper = new ContactRecordWrapper();
        for (AggregateResult ar: [SELECT Contact__c, RecordType.DeveloperName, SUM(Amount__c)
                                  FROM Sales_Comp__c
                                  WHERE (Status__c = :SALES_COMP_STATUS_APPROVED AND
                                         CreatedDate = THIS_MONTH AND
                                         Contact__c = :contactId)
                                  GROUP BY Contact__c, RecordType.DeveloperName]) {
            String apiName = String.valueOf(ar.get('DeveloperName'));
            Decimal total = (Decimal) ar.get('expr0');
            if (apiName == SALES_COMP_RECORD_TYPE_NAME_CD_CP) {
                wrapper.cdCPtotal = total;
            } else if (apiName == SALES_COMP_RECORD_TYPE_NAME_SPV_MPV) {
                wrapper.spvMPVtotal = total;
            } else if (apiName == SALES_COMP_RECORD_TYPE_NAME_GIFT){
                wrapper.giftTotal = total;
            }
        }
        return wrapper;
    }
}