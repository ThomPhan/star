public With Sharing class StatusTriggerHandler extends TriggerHandlerBase {
    private static Boolean hasRun = false;
    
    public StatusTriggerHandler(String triggerName) {
        super(triggerName);
    }
    
    // Before Insert
    public override void beforeInsert(List<SObject> newRecords) {
        processStatusRecords(null, newRecords, null, null);  // No old records for beforeInsert
    }
    
    // Before Update
    public override void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
        processStatusRecords(oldRecords, newRecords, oldRecordMap, newRecordMap);  // Pass both old and new records for beforeUpdate
    }
    
    // After Insert
    public override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        processForDueDatesBasedOnRiskRating(newRecords, null);
    }
    
    // After Update
    public override void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
        processForDueDatesBasedOnRiskRating(newRecords, oldRecordMap);        
    }
   
    
    private void processForDueDatesBasedOnRiskRating(List<SObject> newRecords, Map<ID, SObject> oldRecordMap){
        // Extract Contact IDs from new Status__c records        
        Set<Id> contactIds = new Set<Id>();        
        Map<Id,Status__c> mapContactToStatus= new Map<Id,Status__c>();
        Map<String, Contact> contactIdToContactMap = new Map<String, Contact>();

        for (SObject record : newRecords) {
            Status__c status = (Status__c) record;
            if (isRiskRatingChanged(status, oldRecordMap) && status.Contact__c != null ) {
                contactIds.add(status.Contact__c);
            }
            //this will check status changes for contact
            if (isPoPRevoked(status, oldRecordMap) && status.Contact__c != null ) {
                mapContactToStatus.put(status.Contact__c,status);
            }
        }

        List<PoP__c> li_pop = POPSelector.getPoPUsingStatusTypeCode(mapContactToStatus.keySet(), 'Pending Application, Revocation Successful, Application Successful', null, null);
          
        Map<Id,Pop__c> mapContactIdPoP = new Map<Id,PoP__c>();        
        for(PoP__c pop : li_pop)
        {
            if(! mapContactIdPoP.containsKey(pop.Contact__c))
                mapContactIdPoP.put(pop.Contact__c,pop);
        }
   
        List<Contact> patrons = ContactSelector.getContactByIds(mapContactToStatus.keySet());
        for (Contact con : patrons) {
            contactIdToContactMap.put(con.Id, con);
        }
     
        List<PoP__c> li_popToBeInserted = new List<PoP__c>();
        for(Id contactId: mapContactToStatus.keySet())
        {  
            if(mapContactIdPoP.containsKey(contactId) && mapContactIdPoP.get(contactId).Status__c != ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION)
            {    
                li_popToBeInserted.add(KYCUtility.createPoPRecord(contactId, ConstantHelper.STRING_STOPCODEPICKLISTVALUE, KYCUtility.getStopCodeByDeveloperName(ConstantHelper.STRING_POP_CMD_LABEL), ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION, contactIdToContactMap.get(contactId).Patron_ID__c , contactIdToContactMap));
            }
        }

        if(!li_popToBeInserted.isEmpty())
        {
            //insert li_popToBeInserted;
            KYCUtility.upsertPoPRecords(li_popToBeInserted);
        }

        //Remove contact from the list if Due Date Override exist for that contact
        // Query Key_Date__c records with Active__c Due Date Override
        List<Key_Date__c> activeOverrideDueDates = KeyDateSelector.getKeyDateByContactIds(contactIds, ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE);
        
        // Extract contact IDs that have active key date records
        Set<Id> contactIdsWithActiveDueDateOverride = new Set<Id>();
        for (Key_Date__c kd : activeOverrideDueDates ) {
            contactIdsWithActiveDueDateOverride.add(kd.Patron__r.id);
        }
        
        // Remove those contact IDs from the original set
        contactIds.removeAll(contactIdsWithActiveDueDateOverride);        
        //Remove if Due Date Override exist
                
        // Send Contact IDs into KYCUtility.processContactsForDueDates
        if (!contactIds.isEmpty()) {
            KYCUtility.processContactsForDueDates(contactIds, null);
        }
    }
    
    // Process Status Records (Reusable Method for Insert and Update)
    private void processStatusRecords(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
        Map<Id, Status__c> oldStatusMap = (Map<Id, Status__c>)oldRecordMap;
        Map<Id, Status__c> newStatusMap = (Map<Id, Status__c>)newRecordMap;
        
        // Reusable method to handle both before insert and before update
        Map<String, Status__c> patronExtIdToStatusMap = new Map<String, Status__c>();
        Map<String, Contact> patronExtIdToContactMap = new Map<String, Contact>();
        // If it's a before insert scenario, no old records, so we just add all new records
        if (oldRecordMap == null) {
            patronExtIdToStatusMap = fetchPatronToStatuses(newRecords);
            patronExtIdToContactMap = fetchPatronContacts(patronExtIdToStatusMap.keySet()); // Get contacts for those new records
        } else {
            // If it's before update, we need to check for changes and add updated records
            patronExtIdToStatusMap = fetchPatronToStatuses(newRecords);
            patronExtIdToContactMap = fetchPatronContacts(patronExtIdToStatusMap.keySet());
        }
        // Now that we have the maps, update the Contact__c field in the Status__c records
        updateStatusWithContacts(newRecords, patronExtIdToContactMap);
    }

    // Handle Before Insert (adding records directly)
    private Map<String, Status__c> fetchPatronToStatuses(List<SObject> newRecords) {
        Map<String, Status__c> patronExtIdToStatusMap = new Map<String, Status__c>();

        for (SObject record : newRecords) {
            
            Status__c newStatus = (Status__c) record;
            patronExtIdToStatusMap.put(newStatus.Patron_Id__c, newStatus);
        }
        return patronExtIdToStatusMap;
    }

    // Fetch and map patron contacts to External Ids
    private static Map<String, Contact> fetchPatronContacts(Set<String> conExtIds) {
        List<Contact> patrons = ContactSelector.getContactByExtIds(conExtIds);
        Map<String, Contact> patronExtIdToContactMap = new Map<String, Contact>();
        for (Contact con : patrons) {
            patronExtIdToContactMap.put(con.Patron_ID__c, con);
        }
        return patronExtIdToContactMap;
    }

    // Update Status__c with Contact__c mappings
    private void updateStatusWithContacts(List<SObject> newRecords, Map<String, Contact> patronExtIdToContactMap) {
        
        for (SObject record : newRecords) {
            Status__c newStatus = (Status__c) record;
            if(newStatus.Patron_Id__c != null && patronExtIdToContactMap.containsKey(newStatus.Patron_Id__c)){                
            	newStatus.Contact__c = patronExtIdToContactMap.get(newStatus.Patron_Id__c).Id;
            }
            
            
        }
        
    }
    
    // Check if Risk Rating has changed (for before update scenario)
    private static Boolean isRiskRatingChanged(Status__c newStatus, Map<ID, SObject> oldRecordMap) {
        //this will check if the type is AML
        if (! newStatus.Type__c.equalsIgnoreCase(ConstantHelper.STRING_STATUS_AML_TYPE))
            return false;

        if (oldRecordMap == null || oldRecordMap.size() == 0 || oldRecordMap.isEmpty()) {
            return true;  // Always return true for new (before insert) records
        }
        
        Status__c oldStatus = (Status__c) oldRecordMap.get(newStatus.Id);
        return newStatus.Code__c != oldStatus.Code__c;  // Check if the Code has changed
    }
    
    private static Boolean isPoPRevoked(Status__c newStatus, Map<ID, SObject> oldRecordMap) {        
        //this will check if the type KYC Details Control
        if (! (newStatus.Type__c.equalsIgnoreCase(ConstantHelper.STRING_STATUS_KYC_TYPE) && newStatus.Description__c.equalsIgnoreCase(ConstantHelper.STRING_STATUS_KYC_DESCRIPTION_INACTIVE)))
            return false;
            
        if (oldRecordMap == null || oldRecordMap.size() == 0 || oldRecordMap.isEmpty()) {
            return true;  // Always return true for new (before insert) records
        }
        
        Status__c oldStatus = (Status__c) oldRecordMap.get(newStatus.Id);
        return newStatus.Description__c != oldStatus.Description__c;  // Check if the Code has changed
    }
}