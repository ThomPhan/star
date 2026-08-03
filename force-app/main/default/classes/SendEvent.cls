/*
 * Main class for sending events to Amazon EventBridge.
 */
global class SendEvent {
    /*
     * Calls the EventBridge PutEvents API to send events to a custom event bus
     * in EventBridge.
     */
    @future(callout = true)
    public static void pushToEventBridge(List < String > awsEventList) {
        /*
         * The EventBridge PutEvents API takes a maximum of 10 events.
         * Maximum possible length of Entries array is 10.
         * Reference doc:
         * https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_PutEvents.html
         */
        Integer maxBatchCount = 10;
        Integer totalEvents = awsEventList.size();
        Integer iterationsOfPutEventsAPI;
        // Determine the number of iterations needed for the PutEvents API call.
        // The max batch size of events in each call is 10.
        if (math.mod(totalEvents, maxBatchCount) == 0) {
            iterationsOfPutEventsAPI = totalEvents / maxBatchCount;
        } else {
            iterationsOfPutEventsAPI = totalEvents / maxBatchCount + 1;
        }
        for (Integer i = 0; i < iterationsOfPutEventsAPI; i++) {
            JSONGenerator jsonBody = JSON.createGenerator(true);
            jsonBody.writeStartObject();
            jsonBody.writeFieldName('Entries');
            jsonBody.writeStartArray();
            for (Integer j = i * maxBatchCount; j < (i * maxBatchCount + maxBatchCount) &&
                j < awsEventList.size(); j++) {
                jsonBody.writeStartObject();
                jsonBody.writeStringField('Source', 'mySource');
                // As an example, we set DetailType to the name of the platform event.
                jsonBody.writeStringField('DetailType', 'Carbon_Comparison__e');
                // Set the custom event bus
                // Replace the entire string for EventBusName with your custom event bus name
                jsonBody.writeStringField('rs-salesforce',
                    'arn:aws:events:ap-southeast-2:285326897192:event-bus/rs-salesforce');
                // The Detail field contains the event payload in JSON.
                jsonBody.writeStringField('Detail', awsEventList.get(j));
                jsonBody.writeEndObject();
            }
            jsonBody.writeEndArray();
            jsonBody.writeEndObject();
            jsonBody.close();
            // Make the API call via an Apex callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AWS_EventBridge');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-amz-json-1.1');
            req.setHeader('X-Amz-Target', 'AWSEvents.PutEvents');
            req.setBody(jsonBody.getAsString());
            System.debug(req.getBody());
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug(res.getStatusCode());
            System.debug(res.getBody());
        }
    }
}