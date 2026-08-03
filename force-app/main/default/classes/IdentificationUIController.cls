/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 08-26-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-26-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public without sharing class IdentificationUIController {
    @AuraEnabled
    public static List<IdentificationUIDataProvider.IdentificationUIDataWrapper> getIDDetailsByContactId(String recordId){
        system.debug('Controller '+ IdentificationUIDataProvider.getIDDetailsByContactId(recordId));
        return IdentificationUIDataProvider.getIDDetailsByContactId(recordId);
    }
}