public class Exl_AfterSave_Exclusion_Helper {
    public class FlowInputWrapper {
        @InvocableVariable(required=true) public String exclusionRecId;
        @InvocableVariable(required=true) public String source;
        @InvocableVariable(required=true) public String status;
    }
    
    public class FlowOutputWrapper {
        @InvocableVariable
        public Boolean isSuccessful;
        
        @InvocableVariable
        public String Error;
    }
    
    @InvocableMethod(label='Call Future Method' description='Calls a future method' category='Exl_OnExclusionInsert/Update')
    public static List<FlowOutputWrapper> invokeFuture(List<FlowInputWrapper> inputs) {
        List<FlowOutputWrapper> results = new List<FlowOutputWrapper>();
        
        // If Flow passed nothing, still return one empty output (Flow safe)
        if (inputs == null || inputs.isEmpty()) {
            FlowOutputWrapper emptyOut = new FlowOutputWrapper();
            emptyOut.isSuccessful = false;
            emptyOut.Error = null;
            results.add(emptyOut);
            return results;
        }
        
        for (FlowInputWrapper inWrap : inputs) {
            FlowOutputWrapper out = new FlowOutputWrapper();
            out.isSuccessful = false;
            out.Error = null;
            
            try {
                String incomingexclusionRecId = (inWrap == null) ? null : inWrap.exclusionRecId;
                if (String.isBlank(incomingexclusionRecId)) {
                    results.add(out);
                    continue;
                }
                out.isSuccessful = True;
                doAsyncOperation(inWrap.exclusionRecId, inWrap.source, inWrap.status);
            } catch (Exception e) {
                out.Error = 'Error while Calling Future Method: ' + e.getMessage();
            }
            results.add(out);
        }
        
        return results;
    }
    
    @future(callout=true)
    public static void doAsyncOperation(
        String exclusionRecId,
        String source,
        String status
    ) {
        System.debug('Exclusion Id: ' + exclusionRecId);
        System.debug('Source: ' + source);
        System.debug('Status: ' + status);
        List<Internal_Event_Log__e> eventsToPublish = new List<Internal_Event_Log__e>();
        
        // Create Platform Event
        eventsToPublish.add(new Internal_Event_Log__e(
            Record_Id__c = exclusionRecId,
            Source__c = source,
            Status__c = status
        ));
        
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
        }        
    }
}