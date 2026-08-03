public without sharing class Exl_SFEventToAzureService_PERequest {
    public class FlowInputWrapper {
        @InvocableVariable(required=true) public String exclusionId;
    }
    public class FlowOutputWrapper {
        @InvocableVariable public Exl_PlatformEvent_JSONBody Exl_PlatformEvent_JSONBody;
        @InvocableVariable public String error; 
    }
    
    @InvocableMethod(label='Deserialize JSON String')
    public static List<FlowOutputWrapper> deserializeJson(List<String> jsonStrings) {
        system.debug('deserializeJson::%%:: ' + jsonStrings);
        if (jsonStrings.isEmpty()) {
            System.debug('Error: JSON input is null or blank. Cannot create parser.');
            return new List<FlowOutputWrapper>();
        }

        List<FlowOutputWrapper> outs = new List<FlowOutputWrapper>();

        for (String jsonString : jsonStrings) {
            system.debug('jsonString::%%:: ' + jsonString);
            FlowOutputWrapper out = new FlowOutputWrapper();

            if (jsonString != null && String.isNotBlank(jsonString)) {
                try {
                    // Deserialize the JSON string into an instance of your wrapper class
                    Exl_PlatformEvent_JSONBody wrapper = (Exl_PlatformEvent_JSONBody) JSON.deserialize(jsonString, Exl_PlatformEvent_JSONBody.class);
                    System.debug(LoggingLevel.INFO, 'Deserialized object: ' + JSON.serializePretty(wrapper));

                    // Validate the exclusionNumber field
                    if (wrapper.exclusionNumber == null || String.isBlank(wrapper.exclusionNumber)) {
                        out.error = 'Error: exclusionNumber is null or blank after deserialization. Input JSON: ' + jsonString;
                        System.debug(out.error);
                    } else {
                        out.Exl_PlatformEvent_JSONBody = wrapper;
                    }
                } catch (Exception e) {
                    // Handle deserialization errors
                    out.error = 'Error during JSON deserialization: ' + e.getMessage() + '. Input JSON: ' + jsonString;
                    System.debug(LoggingLevel.ERROR, out.error);
                }
            } else {
                // Handle null or empty input
                out.error = 'Error: JSON input is null or empty. Cannot parse.';
                System.debug(out.error);
            }

            outs.add(out);
        }

        return outs;
    }
}