/*
 *Description       : 
 *Author            : Simplus
 *Created Date		: 15-08-2023
 *History:
 *15-08-2023		Created
*/
public class ExclusionsDetailsUIDataSelector extends ExternalObjectQuerySelector{
    public override List<Schema.SObjectField> getExternalObjectFieldsList() {
        return new List<Schema.SObjectField> {
            
                POE__x.Behavior__c,
                POE__x.CurrentDate__c,
                POE__x.Description__c,
                POE__x.ExpiryDate__c,
                POE__x.IssuedDate__c,
                POE__x.Length__c,
                POE__x.POENumber__c,
                POE__x.POEType__c,
                POE__x.Property__c,
                POE__x.SalesforceContactId__c
         };
    }

    public override Schema.SObjectType getExternalObjectType() {
        return POE__x.sObjectType;
    }
}