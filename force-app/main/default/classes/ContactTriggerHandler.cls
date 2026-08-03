/**
 * @description       : Trigger handler class for ContactTriggerHandler
 * @author            : Simplus
 * @group             : Simplus
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   10-09-2023   Simplus                      Initial Version
 */
public class ContactTriggerHandler extends TriggerHandlerBase { //extending the trigger framework
    static final String APEXCLASSNAME = 'ContactTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';

    //new method which is required when we extend the TriggerHandlerBase class
    public ContactTriggerHandler (String triggerName) {
      super(triggerName);
    }

    //public static void handleBeforeUpdate(List<Contact> contList, Map<Id, Contact> oldContMap){
    public override void beforeUpdate(List<SObject> oldContactList, List<SObject> newContactList, Map<ID, SObject> oldContactMap, Map<ID, SObject> newContactMap){
        List<Contact> contList = (List<Contact>)newContactList;
        Map<Id, Contact> oldContMap = (Map<Id, Contact>)oldContactMap;
        
        List<Schema.FieldSetMember> forBusinessFS = Schema.SObjectType.Contact.fieldSets.getMap().get('SOW_For_Business').getFields();

        List<Schema.FieldSetMember> forIndivFS = Schema.SObjectType.Contact.fieldSets.getMap().get('SOW_For_Individuals').getFields();

        List<Schema.FieldSetMember> allFields = new List<Schema.FieldSetMember>();
        allFields.addAll(forBusinessFS);
        allFields.addAll(forIndivFS);

        boolean isChanged = false;

        //Check SOW Field update
        for(Contact c : contList){

            isChanged = false;

            for(Schema.FieldSetMember f : allFields){

                if(c.get(f.getFieldPath()) != oldContMap.get(c.Id).get(f.getFieldPath())){
                    
                    isChanged = true;
                }
            }

            if(isChanged){

                c.SoW_Update_DateTime__c = DateTime.now();
            }

            /* Logic to uncheck the Sync pending field for Member Portal*/

            if(c.get('Email') != oldContMap.get(c.Id).get('Email')){
                c.Portal_Email_Update_Sync_Wait__c = false;
            }

            if(c.get('MobilePhone') != oldContMap.get(c.Id).get('MobilePhone')){
                c.Portal_Mobile_Update_Sync_Wait__c = false;
            }
        }
    }

    //public static void handleAfterUpdate(List<Contact> contList, Map<Id, Contact> oldContMap){
    public override void afterUpdate(List<SObject> oldContactList, List<SObject> newContactList, Map<ID, SObject> oldContactMap, Map<ID, SObject> newContactMap){
        
        List<Contact> contList = (List<Contact>)newContactList;
        Map<Id, Contact> oldContMap = (Map<Id, Contact>)oldContactMap;
        
        //update User email from Contact email
        ContactTriggerHelper.updateUserEmailfromContact(contList, oldContMap);
        
        //method to reconcile Restriction records - POP-550
        ContactTriggerHelper.reconcileRestrictionRecords(contList, oldContMap);
        
    }
}