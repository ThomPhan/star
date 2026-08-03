/*
 * Converts a platform event to a JSON string format representation.
 * Modify this class based on your platform event fields.
 */
global class AWSEvent {
    public String eventToJSON;
    public AWSEvent(Carbon_Comparison__e event) {
        eventToJSON = '{ \"Annual_Mileage__c\": \"' + event.Annual_Mileage__c + '\",';
        eventToJSON += '\"Current_Vehicle__c\": \"' + event.Current_Vehicle__c + '\",';
        eventToJSON += '\"Model_Year__c\": \"' + event.Model_Year__c + '\"}';
    }
    public String getEventToJSON() {
        return this.eventToJSON;
    }
}