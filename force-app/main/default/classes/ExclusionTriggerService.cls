public class ExclusionTriggerService extends TriggerHandlerBase {
    
    //new method which is required when we extend the TriggerHandlerBase class
    public ExclusionTriggerService(String triggerName) {
        super(triggerName);
    }
    
    public override void afterDelete(List<SObject> oldSObjectList, Map<ID, SObject> oldSObjectMap){
        List<Internal_Event_Log__e> eventsToPublish = new List<Internal_Event_Log__e>();
        Set<Id> contactIds = new Set<Id>();
        
        for(id ExclusionId : oldSObjectMap.keySet()){
            if (oldSObjectMap != null && oldSObjectMap.containsKey(ExclusionId)) {
                SObject sobj = oldSObjectMap.get(ExclusionId);
                if (sobj instanceof Exl_Exclusion__c) {
                    Exl_Exclusion__c oldExclusion = (Exl_Exclusion__c) sobj;
                    contactIds.add(oldExclusion.Contact__c);
                }
            }
        }
        if (contactIds != null && !contactIds.isEmpty()) {
            for(Id conId : contactIds){
                eventsToPublish.add(new Internal_Event_Log__e(
                    Record_Id__c = conId,
                    Source__c = 'ExclusionTrigger'
                ));
            }
        }
        
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
        }
    }
    public override void afterUndelete(List<SObject> newRecords, Map<ID, SObject> newRecordMap){
        List<Internal_Event_Log__e> eventsToPublish = new List<Internal_Event_Log__e>();
        Set<Id> contactIds = new Set<Id>();
        
        for(id ExclusionId : newRecordMap.keySet()){
            if (newRecordMap != null && newRecordMap.containsKey(ExclusionId)) {
                SObject sobj = newRecordMap.get(ExclusionId);
                if (sobj instanceof Exl_Exclusion__c) {
                    Exl_Exclusion__c oldExclusion = (Exl_Exclusion__c) sobj;
                    contactIds.add(oldExclusion.Contact__c);
                }
            }
        }
        if (contactIds != null && !contactIds.isEmpty()) {
            for(Id conId : contactIds){
                eventsToPublish.add(new Internal_Event_Log__e(
                    Record_Id__c = conId,
                    Source__c = 'ExclusionTrigger'
                ));
            }
        }
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
        }
        
    }
    
    public override void beforeInsert(List<SObject> newSObjectList){
    }
    
    public override void beforeUpdate(List<SObject> oldSObjectList, List<SObject> newSObjectList, Map<ID, SObject> oldSObjectMap, Map<ID, SObject> newSObjectMap){
    }
    
    public override void afterInsert(List<SObject> newSObjectList, Map<ID, SObject> newSObjectMap){
    }
    
    public override void afterUpdate(List<SObject> oldSObjectList, List<SObject> newSObjectList, Map<ID, SObject> oldSObjectMap, Map<ID, SObject> newSObjectMap){
    }
    
}