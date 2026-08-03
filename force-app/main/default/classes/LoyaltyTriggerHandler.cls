/**
* Class Name  : LoyaltyTriggerHandler
* @author     : Capgemini
* @Description: Handler for class LoyaltyTrigger
* @version    : Version 1 : 29/10/2025
**/

public class LoyaltyTriggerHandler extends TriggerHandlerBase {
    
    //method which is required when we extend the TriggerHandlerBase class
    public LoyaltyTriggerHandler (String triggerName) {
      super(triggerName);
    }    
    
    public override void afterUpdate(List<SObject> oldLoyaltyList, List<SObject> newLoyaltyList, Map<ID, SObject> oldLoyaltyMap, Map<ID, SObject> newLoyaltyMap){
        List<Loyalty__c> newLoyalty_List = (List<Loyalty__c>)newLoyaltyList;
        Map<Id, Loyalty__c> oldLoyalty_Map = (Map<Id, Loyalty__c>)oldLoyaltyMap;
        
        //method to reconcile Restriction records - POP-549
        LoyaltyTriggerHelper.reconcileRestrictionRecords(newLoyalty_List, oldLoyalty_Map);
        
    }
    
}