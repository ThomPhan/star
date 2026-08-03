/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 07-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-20-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public abstract class ExternalObjectQuerySelector {
    
    public abstract List<Schema.SobjectField> getExternalObjectFieldsList();

    public abstract Schema.SObjectType getExternalObjectType();


}