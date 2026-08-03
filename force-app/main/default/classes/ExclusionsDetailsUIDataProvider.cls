/*
 *Description       : 
 *Author            : Simplus
 *Created Date		: 15-08-2023
 *History:
 *15-08-2023		Created
*/
public class ExclusionsDetailsUIDataProvider {

    public static List<ExclusionsDetailsUIDataProvider.ExclusionsDetailsWrapper> getIDDetailsByContactId(String recordId){
        
        List<ExclusionsDetailsWrapper> idDetailsObjWrapList = new List<ExclusionsDetailsWrapper>();
        try{
            List<POE__x> exclusionsData = getIdDetailsByContactQueryByContactId(recordId);
            if(exclusionsData.size() > 0){
                for(POE__x  idObj : exclusionsData){
                    idDetailsObjWrapList.add(

                        new ExclusionsDetailsWrapper(idObj.Behavior__c, idObj.CurrentDate__c, idObj.Description__c, idObj.ExpiryDate__c, idObj.IssuedDate__c, idObj.Length__c, idObj.POENumber__c, idObj.POEType__c, idObj.Property__c)
                    ); 
                }
            }            
        }
        catch(Exception e){
            system.debug('Exception happenned '+ e.getMessage() );
            ErrorLogger.createLog('ExclusionsDetailsUIDataProvider','getIDDetailsByContactId',e,recordId,'Apex Class'); 
            return null;
        }
        return idDetailsObjWrapList;
    }
    
    
    public static List<POE__x> getIdDetailsByContactQueryByContactId(Id contactId){
        ExclusionsDetailsUIDataSelector selector = new ExclusionsDetailsUIDataSelector();
        String externalFields = String.valueOf(selector.getExternalObjectFieldsList()).remove(')').remove('(');
        Schema.SObjectType externalObj = selector.getExternalObjectType();
        if(Test.isRunningTest()){
            if(ExclusionDetailsUIControllerTest.testException == true){
                throw new ExclusionsDetailsUIDataProviderException();
            }
            
            List<POE__x> ids = new List<POE__x>();
            ids.add(new POE__x(SalesforceContactId__c = ExclusionDetailsUIControllerTest.ct.Id, behavior__c = 'test', CurrentDate__c = String.valueOf(Date.today()), Description__c = 'test', ExpiryDate__c = String.valueOf(Date.today()), IssuedDate__c = String.valueOf(Date.today()), Length__c = 'test', POENumber__c = '1', POEType__c = 'test', Property__c = 'test'));
            return ids;
        } else {
            String query = 'SELECT ' + externalFields + ' FROM ' + externalObj + ' WHERE SalesforceContactId__c = \'' + contactId + '\' ORDER BY IssuedDate__c DESC LIMIT 50';
            system.debug('-----'+query);
            return Database.query(query);
        }
    }
    
    
    public class ExclusionsDetailsWrapper{
        @AuraEnabled public String behavior {get;set;}
        @AuraEnabled public String currentDate {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String expiryDate {get;set;}
        @AuraEnabled public String issuedDate {get;set;}
        @AuraEnabled public String lengthField {get;set;}
        @AuraEnabled public String poeNumber {get;set;}
        @AuraEnabled public String poeType {get;set;}
        @AuraEnabled public String property {get;set;}

        public ExclusionsDetailsWrapper(String behavior, String currentDate, String description, String expiryDate, String issuedDate, String lengthField, String poeNumber, String poeType, String property){
            this.behavior = behavior;
            this.currentDate = currentDate;
            this.description = description;
            this.expiryDate = expiryDate;
            this.issuedDate = issuedDate;
            this.lengthField = lengthField;
            this.poeNumber = poeNumber;
            this.poeType = poeType;
            this.property = property;
        }
    }
    
    public class ExclusionsDetailsUIDataProviderException extends Exception{}
}