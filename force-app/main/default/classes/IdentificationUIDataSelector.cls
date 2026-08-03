/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class IdentificationUIDataSelector extends ExternalObjectQuerySelector{
    public override List<Schema.SObjectField> getExternalObjectFieldsList() {
        return new List<Schema.SObjectField> {

            identification__x.IdExpiryDate__c,
            identification__x.IdNumber__c,
            identification__x.IdType__c,
            identification__x.State__c,
            identification__x.Country__c,
            identification__x.SalesforceContactId__c

         };
    }

    public override Schema.SObjectType getExternalObjectType() {
        return identification__x.sObjectType;
    }
}