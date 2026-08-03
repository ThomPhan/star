/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-26-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class IdentificationUIDataProvider {

    public static List<IdentificationUIDataProvider.IdentificationUIDataWrapper> getIDDetailsByContactId(String recordId){
        
        List<IdentificationUIDataWrapper> idDetailsObjWrapList = new List<IdentificationUIDataWrapper>();
        try{
            List<identification__x > idData = getIdDetailsByContactQueryByContactId(recordId);
  
            if(idData.size() > 0){

                for(identification__x  idObj : idData){
                    idDetailsObjWrapList.add(
                        new IdentificationUIDataWrapper(idObj.SalesforceContactId__c,idObj.IdType__c,idObj.IdNumber__c,idObj.IdExpiryDate__c,idObj.State__c,idObj.Country__c)
                    ); 

                }
            
            }            
            
        }
        catch(Exception e){
            system.debug('Exception happenned '+ e.getMessage() );
            ErrorLogger.createLog('IdentificationUIDataProvider','getIDDetailsByContactId',e,recordId,'Apex Class'); 
            return null;
        }
        return idDetailsObjWrapList;
    }
    
    
    public static List<identification__x> getIdDetailsByContactQueryByContactId(Id contactId){
        IdentificationUIDataSelector selector = new IdentificationUIDataSelector();
        String externalFields = String.valueOf(selector.getExternalObjectFieldsList()).remove(')').remove('(');
        Schema.SObjectType externalObj = selector.getExternalObjectType();
        if(Test.isRunningTest()){
            if(IdentificationUIControllerTest.testException == true){
                throw new IdentificationDataProviderException();
            }
            List<identification__x> ids = new List<identification__x>();
            ids.add(new identification__x(SalesforceContactId__c=IdentificationUIControllerTest.ct.Id,IdType__c='Driving License',IdNumber__c='2323224',IdExpiryDate__c='2021-03-04',State__c='CA',Country__c='PH'));
            return ids;
        } else {
            String query = 'SELECT ' + externalFields + ' FROM ' + externalObj + ' WHERE SalesforceContactId__c = \'' + contactId + '\' LIMIT 50';
            system.debug('-----'+query);
            return Database.query(query);
        }
    }
    
    
    public class IdentificationUIDataWrapper{
        @AuraEnabled public String contactId {get;set;}
        @AuraEnabled public String idType {get;set;}
        @AuraEnabled public String idNumber {get;set;}
        @AuraEnabled public String idExpiryDate {get;set;}
        @AuraEnabled public String idState {get;set;}
        @AuraEnabled public String idCountry {get;set;}

        public IdentificationUIDataWrapper(String contactId,String idType,String idNumber,String expiryDate, String idState, String idCountry){
            this.contactId = contactId;
            this.idType = idType;
            this.idNumber = idNumber;
            this.idExpiryDate = expiryDate;
            this.idState = idState;
            this.idCountry = idCountry;

        }
    }
    
    public class IdentificationDataProviderException extends Exception{}
}