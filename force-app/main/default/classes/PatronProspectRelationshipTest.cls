/**
 * Class Name  : PatronProspectRelationshipTest
 * Summary     : Controller class for 'PatronProspectRelationshipTest' aura component 
 * Methods     : testGetRelationships
                 testIsDeletableObject
                 testIsUpdateableObject
                 testGetRecordTypes
                 testDeleteRelationship
 * @author       Fritz Gerald Moran
   @Description: This class tests the list of active relationships, checks the user access permissions for the object,
                 gets the record types, and deletes relationship
 * @version      $Revision: 1.0 $, $Date: 25/Jul/2020 
 */

/*parent class that holds the methods for testing the apex controller of PatronProspectRelationshipController*/
@isTest
public class PatronProspectRelationshipTest {
    
    /*testing fetch relationships with and without limit*/
    @isTest static void testGetRelationships() {
        List<Relationships__c> relationshipsList;
        List<Relationships__c> relationshipsListWithLimit;
        
        Contact conRecParent = new Contact();
        conRecParent.LastName = 'Parent Patron';
        //conRecParent.Occupation__c = 'Parent Patron';
        conRecParent.Email = 'star@yopmail.com';
        conRecParent.HomePhone='+61439217734';
        conRecParent.OtherPhone='+61488886666';
        conRecParent.MobilePhone='+86130888866665555';
        
        insert conRecParent;
        
        Contact conRecChild = new Contact();
        conRecChild.LastName = 'Child Patron';
        //conRecChild.Occupation__c = 'Child Patron';
        conRecChild.Email = 'starchild@yopmail.com';
        conRecChild.HomePhone='+61439217734';
        conRecChild.OtherPhone='+61488886666';
        conRecChild.MobilePhone='+86130888866665555';
        
        insert conRecChild;
        
        Relationships__c relRec = new Relationships__c();
        relRec.Name = 'Relationship Name';
        relRec.From_Patron__c = conRecParent.Id;
        relRec.To_Patron__c = conRecChild.Id;
        relRec.Active__c = TRUE;
        
        insert relRec;
        
        Test.startTest();
        try {
            relationshipsList = PatronProspectRelationshipController.getRelationships(conRecParent.Id, TRUE);
            relationshipsListWithLimit = PatronProspectRelationshipController.getRelationships(conRecParent.Id, FALSE);
        } catch(Exception ex) {
            system.debug(ex.getMessage());  
        }
        Test.stopTest();
        
        system.assert(!relationshipsList.isEmpty());
        system.assert(!relationshipsListWithLimit.isEmpty());
    }
    
    /*test user permissions if is has a delete access on the record*/
    @isTest static void testIsDeletableObject() {
        String sObjectName = 'Relationships__c';
        Boolean isDeletable;
        Test.startTest();
        try {
            isDeletable = PatronProspectRelationshipController.isDeletableObject(sObjectName);
        } catch(Exception ex) {
            system.debug(ex.getMessage()); 
        }
        Test.stopTest();
        
        system.assert(isDeletable);
    }

    /*test user permissions if is has a create access on the record*/
    @isTest static void testIsCreateableObject() {
        String sObjectName = 'Relationships__c';
        Boolean isCreateable;
        Test.startTest();
        try {
            isCreateable = PatronProspectRelationshipController.isCreatable(sObjectName);
        } catch(Exception ex) {
            system.debug(ex.getMessage()); 
        }
        Test.stopTest();
        
        system.assert(isCreateable);
    }    
    
    /*test user permissions if is has a update access on the record*/
    @isTest static void testIsUpdateableObject() {
        String sObjectName = 'Relationships__c';
        Boolean isUpdatable;
        Test.startTest();
        try {
            isUpdatable = PatronProspectRelationshipController.isUpdateableObject(sObjectName);
        } catch(Exception ex) {
            system.debug(ex.getMessage()); 
        }
        Test.stopTest();
        
        system.assert(isUpdatable);
    }
    
    
    /*test fetching of record types*/
    @isTest static void testGetRecordTypes() {
        PatronProspectRelationshipController obj;
        Test.startTest();
        try {
            obj = PatronProspectRelationshipController.getRecordTypes();
        } catch(Exception ex) {
            system.debug(ex.getMessage()); 
        }
        Test.stopTest();
        
        system.assert(obj != NULL);
    }
     
    
    /*test for deleting a relationship record by Id*/
    @isTest static void testDeleteRelationship() {
        Contact conRecParent = new Contact();
        conRecParent.LastName = 'Parent Patron';
        //conRecParent.Occupation__c = 'Parent Patron';
        conRecParent.Email = 'star@yopmail.com';
        conRecParent.HomePhone='+61439217734';
        conRecParent.OtherPhone='+61488886666';
        conRecParent.MobilePhone='+86130888866665555';
        
        insert conRecParent;
        
        Contact conRecChild = new Contact();
        conRecChild.LastName = 'Child Patron';
        //conRecChild.Occupation__c = 'Child Patron';
        conRecChild.Email = 'starchild@yopmail.com';
        conRecChild.HomePhone='+61439217734';
        conRecChild.OtherPhone='+61488886666';
        conRecChild.MobilePhone='+86130888866665555';
        
        insert conRecChild;
        
        Relationships__c relRec = new Relationships__c();
        relRec.Name = 'Relationship Name';
        relRec.From_Patron__c = conRecParent.Id;
        relRec.To_Patron__c = conRecChild.Id;
        relRec.Active__c = TRUE;
        
        insert relRec;
        
        Test.startTest();
        try {
            PatronProspectRelationshipController.deleteRelationship(relRec.Id);
        } catch(Exception ex) {
            system.debug(ex.getMessage()); 
        }
        Test.stopTest();
        
        system.debug(relRec == NULL);
    }
}