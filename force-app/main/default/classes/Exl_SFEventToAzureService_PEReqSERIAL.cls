public class Exl_SFEventToAzureService_PEReqSERIAL {
    
    public class FlowInputWrapper {
        @InvocableVariable(required=true) public ExternalService.ExclusionsExternalEvents_PlatformEventRequest PERequest; //ExternalService.SFEventToAzureService_PlatformEventRequest
    }
    public class FlowOutputWrapper {
        @InvocableVariable public String serialised_Final_PE_PayLoad ;
        @InvocableVariable public String error;
        
    }
    
    @InvocableMethod(label='Serialize JSON object')
    public static List<FlowOutputWrapper> deserializeJson(List<FlowInputWrapper> reqs) {
        List<FlowOutputWrapper> outs = new List<FlowOutputWrapper>();
        FlowOutputWrapper out = new FlowOutputWrapper();
        
        ExternalService.ExclusionsExternalEvents_PlatformEventRequest PERequest;
        
        try { 
            PERequest = (ExternalService.ExclusionsExternalEvents_PlatformEventRequest) reqs[0].PERequest;
            system.debug('PERequest:: '+PERequest);
            out.serialised_Final_PE_PayLoad = JSON.serialize(PERequest);
            outs.add(out);
        }
        catch (Exception e) {
            out.error = 'Invalid Exclusion Id: ' + e.getMessage();
            outs.add(out);
            return outs;
        }
        
        
        return outs;
    }
    
}