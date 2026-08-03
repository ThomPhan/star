public with sharing class Exl_AzureEventToSF_INBOUND_JSON {
    public class FlowOutputWrapper {
        @InvocableVariable public Exl_PlatformEvent_Inbound_JSONBody iNBOUND_JSONBody ;
        @InvocableVariable public String error;
        
    }
    
    @InvocableMethod(label='Deserialize INBOUND JSON String')
    public static List<FlowOutputWrapper> deserializeJson(List<String> jsonStrings) {
        List<FlowOutputWrapper> outs = new List<FlowOutputWrapper>();
        FlowOutputWrapper out = new FlowOutputWrapper();
        try{
            system.debug('jsonStrings'+jsonStrings);
            List<Exl_PlatformEvent_Inbound_JSONBody> results = new List<Exl_PlatformEvent_Inbound_JSONBody>();
            for (String jsonString : jsonStrings) {
                // Deserialize the JSON string into an instance of your wrapper class
                Exl_PlatformEvent_Inbound_JSONBody wrapper = (Exl_PlatformEvent_Inbound_JSONBody) JSON.deserialize(jsonString, Exl_PlatformEvent_Inbound_JSONBody.class);
                results.add(wrapper);
            }
            if(results.isEmpty()){
                return  new List<FlowOutputWrapper>();
            }
            system.debug('results[0]'+results[0]);
            out.iNBOUND_JSONBody = results[0]; 
            
            outs.add(out);
        }
        Catch(Exception e) {
            out.error = 'Invalid Response' + e.getMessage();
            outs.add(out);
        }
        system.debug('outs'+outs);
        return outs;
    }
}