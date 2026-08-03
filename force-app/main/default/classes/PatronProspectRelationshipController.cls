/**
 * Class Name  : PatronProspectRelationshipController
 * Summary     : Controller class for 'PatronProspectRelationship' aura component 
 * Methods     : getRelationships
                 isDeletableObject
                 isUpdateableObject
                 getRecordTypes
                 deleteRelationship
 * @author       Fritz Gerald Moran
   @Description: This class fetches the list of active relationships, checks the user access permissions for the object,
				 gets the record types, and deletes relationship
 * @version      $Revision: 1.0 $, $Date: 24/Jul/2020 
 */

//with sharing used with class definition to enforce user access restrictions 
public with sharing class PatronProspectRelationshipController {
    
    //method for fetching active Relationships that is associated with the Patron and is Limit to 10.
    @AuraEnabled
    public static List<Relationships__c> getRelationships(String recordId, boolean hasLimit) {
        String objLimit = '';
        List<Relationships__c> relationshipsList = new List<Relationships__c>(); 
        if(hasLimit) {
             objLimit = 'LIMIT 10';
        } else {
             objLimit = '';
        }
        try {
            String relList = 'SELECT Id, Non_Player_Name__c, To_Patron__r.Name, To_Patron__c, Type__c, Active__c, From_Patron__r.Name, Prospect__r.Name, Prospect__c, From_Patron__c, RecordType.Name, RecordTypeId, Name FROM Relationships__c WHERE Active__c = TRUE AND (To_Patron__c != null OR Prospect__c != null OR Non_Player_Name__c != null)  AND (To_Patron__r.Id =: recordId OR From_Patron__r.Id =: recordId) ORDER BY ACTIVE__C DESC, Name DESC, TYPE__c DESC ' +objLimit; 
            relationshipsList = Database.query(relList);
        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }
       
        system.debug(relationshipsList);
        return relationshipsList;
    }
    
    //method for checking if the logged-in user has delete permissions on the object
    @AuraEnabled
    public static Boolean isDeletableObject(String objectAPIName) {
        Boolean returnValue = false;
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sobjectType = globalDescribeMap.get(objectAPIName);
        // Retrieve the object type from global describe and verify if user has delete permission for the object
        if (sobjectType != null) {
            returnValue = sobjectType.getDescribe().isDeletable();
        }
        return returnValue;
    }
    
    //method for checking if the logged-in user has create permissions on the object
    @AuraEnabled
    public static Boolean isCreatable(String objectAPIName) {
        Boolean returnValue = false;
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sobjectType = globalDescribeMap.get(objectAPIName);
        // Retrieve the object type from global describe and verify if user has delete permission for the object
        if (sobjectType != null) {
            returnValue = sobjectType.getDescribe().isCreateable();
        }
        return returnValue;
    }
  
    //method for checking if the logged-in user has update permissions on the object
    @AuraEnabled
    public static Boolean isUpdateableObject(String objectAPIName) {
        Boolean returnValue = false;
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sobjectType = globalDescribeMap.get(objectAPIName);
        // Retrieve the object type from global describe and verify if user has update permission for the object
        if (sobjectType != null) {
            returnValue = sobjectType.getDescribe().isUpdateable();
        }
        return returnValue;
    }
   
    @AuraEnabled
    public String defaultRecordTypeId {get; set;} //initialize variable that will hold the default record type
    
    @AuraEnabled
    public Map<Id, String> relationRecordTypes {get; set;} //initialize map to append the recordTypeId and record type info
    
    //method for getting the record types of Relationships Object
    @AuraEnabled
    public static PatronProspectRelationshipController getRecordTypes() {
        PatronProspectRelationshipController obj = new PatronProspectRelationshipController();
        Map<Id, String> recordtypeMap = new Map<Id, String>();
        //Get all record types of Contact object
        List<Schema.RecordTypeInfo> recordTypeInfoList = Relationships__c.SObjectType.getDescribe().getRecordTypeInfos();
        for(RecordTypeInfo info: recordTypeInfoList) {
            //Check record type is available for current user profile
            if(info.isAvailable()) {
                //Check master record type
                if(info.getName() != 'Master' && info.getName().trim() != ''){
                    recordtypeMap.put(info.getRecordTypeId(), info.getName());
                }
                //Get the default record type for current user profile
                if(info.isDefaultRecordTypeMapping()){
                    obj.defaultRecordTypeId = info.getRecordTypeId();
                }
            }
        }    
        obj.relationRecordTypes = recordtypeMap;
        return obj;
    }
    
    //method for deleting Relationships record that corresponds to the passed ID
    @AuraEnabled
    public static void deleteRelationship(String recordId) {
        List<Relationships__c> relationshipRec = [SELECT Id, Name FROM Relationships__c WHERE ID =: recordId];
        
        if(!relationshipRec.isEmpty() && relationshipRec != NULL) {
            try {
                delete relationshipRec;   
            } catch(Exception ex) {
                ErrorLogger.createLog('Relationships__c','deleteRelationship', ex, recordId, 'Apex Class');
            }   
        }
    }
}