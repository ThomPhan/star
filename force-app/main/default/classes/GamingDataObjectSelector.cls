/**
 * @description       : Class for getting the fields and type of the External Object (called by the GamingDataProvider.apxc)
 * @author            : dominicjasper.caberoy@simplus.com
 * @group             : 
 * @last modified on  : 08-17-2020
 * @last modified by  : dominicjasper.caberoy@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-17-2020   dominicjasper.caberoy@simplus.com   Initial Version
**/
public class GamingDataObjectSelector extends ExternalObjectQuerySelector{
    public override List<Schema.SObjectField> getExternalObjectFieldsList(){
        return new List<Schema.SObjectField>{
            GamingData__x.Actual__c,
            GamingData__x.ADT__c,
            GamingData__x.AverageBet__c,
            GamingData__x.FreePlay__c,
            GamingData__x.Frequency__c,
            GamingData__x.Type__c,
            GamingData__x.NetTheo__c,
            GamingData__x.PreferredVisitDay__c,
            GamingData__x.Trips__c,
            GamingData__x.Turnover__c,
            GamingData__x.Period__c,
            GamingData__x.SalesforceContactID__c,
            GamingData__x.ExternalId,
            GamingData__x.SalesforcePropertyID__c
        };
    }
    public override Schema.SObjectType getExternalObjectType(){
        return GamingData__x.sObjectType;
    }
}