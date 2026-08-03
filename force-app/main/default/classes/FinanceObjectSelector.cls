/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-01-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class FinanceObjectSelector extends ExternalObjectQuerySelector{
    
    public override List<Schema.SObjectField> getExternalObjectFieldsList() {
       return new List<Schema.SObjectField> {
            FinancialSummary__x.HeaderLabel__c,
            FinancialSummary__x.SalesforceContactId__c,

            FinancialSummary__x.CreateDt__c,

            FinancialSummary__x.ADT__c,
            FinancialSummary__x.ADTTrend__c,

            FinancialSummary__x.TotalTheo__c,
            FinancialSummary__x.TheoTrend__c,

            FinancialSummary__x.TotalTrips__c,
            FinancialSummary__x.TripsTrend__c,

            FinancialSummary__x.TotalActual__c,
            FinancialSummary__x.ActualTrend__c
        };
    }

    public override Schema.SObjectType getExternalObjectType() {
        return FinancialSummary__x.sObjectType;
        //return null;
    }

}