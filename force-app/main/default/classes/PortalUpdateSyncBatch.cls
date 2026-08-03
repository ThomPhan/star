global class PortalUpdateSyncBatch implements Database.Batchable<sObject> {
    
    // Query to select all accounts
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Portal_Email_Update_Sync_Wait__c, Portal_Email_Updated_Time__c, Portal_Mobile_Update_Sync_Wait__c, Portal_Mobile_Updated_Time__c FROM Contact where Portal_Email_Updated_Time__c != null OR Portal_Mobile_Updated_Time__c != null');
    }
    
    // Update the Industry field for each batch of accounts
    global void execute(Database.BatchableContext bc, List<Contact> contacts) {
        // Retrieve the custom label value
        String minutesToSubtractStr = Label.Portal_MinutesToSubtract; // Custom label
        //String minutesToSubtractStr = '5'; // Custom label
        
        // Convert the custom label value to an Integer
        Integer minutesToSubtract;
        try {
            minutesToSubtract = Integer.valueOf(minutesToSubtractStr);
        } catch (Exception e) {
            // Handle the case where the custom label value is not a valid integer
            System.debug('Invalid value in custom label MinutesToSubtract: ' + minutesToSubtractStr);
            minutesToSubtract = 0; // Fallback to 0 or any default value
        }
        
        // Subtract the minutes from the current DateTime
        Datetime adjustedDateTime = Datetime.now().addMinutes(-minutesToSubtract);
        
        // Output the result for verification
        System.debug('DateTime ' + minutesToSubtract + ' minutes ago: ' + adjustedDateTime);
        
        for (Contact con : contacts) {
            system.debug('Field values==>'+con.Portal_Email_Updated_Time__c+con.Portal_Mobile_Updated_Time__c);
            if(con.Portal_Email_Updated_Time__c < adjustedDateTime){
                con.Portal_Email_Updated_Time__c = null;
                con.Portal_Email_Update_Sync_Wait__c = false;
            }
            if(con.Portal_Mobile_Updated_Time__c < adjustedDateTime){
                con.Portal_Mobile_Updated_Time__c = null;
                con.Portal_Mobile_Update_Sync_Wait__c = false;
            }
        }
        update contacts;
    }
    
    // Send an email notification when the batch is complete
    global void finish(Database.BatchableContext bc) {
        system.debug('Batch Class Finished.');
    }
}