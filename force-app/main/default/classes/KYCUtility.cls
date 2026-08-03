public class KYCUtility {
    
    // Method to segregate Key_Date__c records into two lists based on 'Name' field
    public static void segregateKeyDates(List<Key_Date__c> keyDates) {
        system.debug('segregateKeyDates '+keyDates);
        // Initialize two lists: one for 'Due Date' and one for 'Attestation'
        List<Key_Date__c> dueDateList = new List<Key_Date__c>();
        List<Key_Date__c> attestationList = new List<Key_Date__c>();
        Map<id, Key_Date__c> contactSFIDToKeyDate= new Map<id, Key_Date__c>();
        try{
            // Iterate over each Key_Date__c record and segregate based on the 'Name' field
            for (Key_Date__c keyDate : keyDates) {
                system.debug('iteration: ' + keyDate);
                // Giving precedence to OverRide Due Date if it exists.
                if (keyDate.Name == ConstantHelper.STRING_KEYDATE_DUEDATE || keyDate.Name == ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE) {
                    // Check if the current keyDate is STRING_KEYDATE_DUEDATE_OVERRIDE
                    if (keyDate.Name == ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE) {
                        // If STRING_KEYDATE_DUEDATE_OVERRIDE is found, prioritize it
                        contactSFIDToKeyDate.put(keyDate.Patron__c, keyDate);
                    } else if (keyDate.Name == ConstantHelper.STRING_KEYDATE_DUEDATE) {
                        // Only add STRING_KEYDATE_DUEDATE if STRING_KEYDATE_DUEDATE_OVERRIDE is not already added for the same Patron__c
                        if (!contactSFIDToKeyDate.containsKey(keyDate.Patron__c)) {
                            //dueDateList.add(keyDate);
                            contactSFIDToKeyDate.put(keyDate.Patron__c, keyDate);
                        }
                    }
                } else if (keyDate.Name == ConstantHelper.STRING_KEYDATE_ATTESTATION && !contactSFIDToKeyDate.containsKey(keyDate.Patron__c)) {
                    //contactSFIDToKeyDate.put(keyDate.Patron__c, keyDate);
                    attestationList.add(keyDate);
                }
            }
			
            
            if(contactSFIDToKeyDate != null && !contactSFIDToKeyDate.isEmpty() ){
                dueDateList.addAll(contactSFIDToKeyDate.values());                
                processKeyDatesForDueDates(dueDateList);
            }
            
            if(!attestationList.isEmpty()){                
                processKeyDatesForAttestation(attestationList);
            }
        }
        catch(Exception e){
            ErrorLogger.createLog(ConstantHelper.APEXCLASSNAME_KYCUTILITY,'segregateKeyDates',e,'',ConstantHelper.COMPONENTTYPE); 
        }
    }
    
    /**
* Process key dates for due dates.
*/
    public static void processKeyDatesForDueDates(List<Key_Date__c> keyDates) {
        if (keyDates.isEmpty()) {
            return;
        }
        
        ProcessingData data = prepareProcessingData(keyDates, false);
        List<PoP__c> popsToBeInserted = new List<PoP__c>();
        try{
            for (Id contId : data.patronSFIdSet) {
                String patronIdStr = (data?.contactIdToContactMap?.get(contId)?.Patron_ID__c != null) 
                    ? data.contactIdToContactMap.get(contId).Patron_ID__c 
                    : null;                
            
                if (!data.contToAppliedPoPMap.containsKey(contId) && !data.contToAppliedStatusMap.containsKey(patronIdStr)) {
                    // pass property from contact record
                    popsToBeInserted.add(createPoPRecord(contId, ConstantHelper.STRING_STOPCODEPICKLISTVALUE, data.stopCodeNumberStr, ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION, patronIdStr, data.contactIdToContactMap));
                } else if (data.contToRevokedPoPMap.containsKey(contId)) {
                    popsToBeInserted.add(createPoPRecord(contId, ConstantHelper.STRING_STOPCODEPICKLISTVALUE, data.stopCodeNumberStr, ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION, patronIdStr, data.contactIdToContactMap));
                }
                
            }
            
            if (!popsToBeInserted.isEmpty()) {
                //database.insert(popsToBeInserted);
                upsertPoPRecords(popsToBeInserted);
            }
        }
        catch(Exception e){
            ErrorLogger.createLog(ConstantHelper.APEXCLASSNAME_KYCUTILITY,'processKeyDatesForDueDates',e,'',ConstantHelper.COMPONENTTYPE); 
        }
    }
    
    /**
* Process key dates for attestation
*/
    public static void processKeyDatesForAttestation(List<Key_Date__c> keyDates) {
        if (keyDates.isEmpty()) {
            return;
        }
       
        ProcessingData data = prepareProcessingData(keyDates, true);
        List<PoP__c> popsToBeRevoked = new List<PoP__c>();        
        try{
           
            for (Id contId : data.patronSFIdSet) {
                String patronIdStr = (data?.contactIdToContactMap?.get(contId)?.Patron_ID__c != null) 
                    ? data.contactIdToContactMap.get(contId).Patron_ID__c 
                    : null;
                
                boolean hasAppliedPoP = data.contToAppliedPoPMap.containsKey(contId);

                boolean hasAppliedStatus=false;
                if(data.contToAppliedStatusMap.containsKey(patronIdStr))
                    hasAppliedStatus = true;
                
                boolean hasRevokedStatus=false;
                if(data.contToRevokedStatusMap.containsKey(patronIdStr))
                    hasRevokedStatus = true;

                if(hasAppliedStatus && hasRevokedStatus){                                
                    if ((data.contToRevokedStatusMap.get(patronIdStr) != null &&  data.contToAppliedStatusMap.get(patronIdStr) != null) && (data.contToRevokedStatusMap.get(patronIdStr)?.Createddate > data.contToAppliedStatusMap.get(patronIdStr)?.Createddate))                    
                        hasAppliedStatus = false;
                    else 
                        hasRevokedStatus = false;
                }                
                
                if (!hasRevokedStatus && (hasAppliedPoP || hasAppliedStatus)) {
                    popsToBeRevoked.add(createPoPRecord(contId, ConstantHelper.STRING_STOPCODEPICKLISTVALUE, data.stopCodeNumberStr, 
                                                        ConstantHelper.STRING_POP_STATUS_PENDING_REVOCATION, patronIdStr, data.contactIdToContactMap));
                }
            }
            
            if (!popsToBeRevoked.isEmpty()) {
                //database.insert(popsToBeRevoked);
                upsertPoPRecords(popsToBeRevoked);
            }
        }
        catch(Exception e){
            ErrorLogger.createLog(ConstantHelper.APEXCLASSNAME_KYCUTILITY,'processKeyDatesForAttestation',e,'',ConstantHelper.COMPONENTTYPE); 
        }
    }
    
    /**
* Prepare all the data needed for processing key dates
*/
    @TestVisible
    private static ProcessingData prepareProcessingData(List<Key_Date__c> keyDates, Boolean revokationflow) {
        ProcessingData data = new ProcessingData();
        try{         
            // Get stop code from metadata
            data.stopCodeNumberStr = getStopCodeByDeveloperName(ConstantHelper.STRING_POP_CMD_LABEL);
            
            // Collect patron IDs
            for (Key_Date__c keyDate : keyDates) {
                data.patronSFIdSet.add(keyDate.Patron__c);
            }
             
            // Get contacts and create mappings
            List<Contact> patrons = ContactSelector.getContactByIds(data.patronSFIdSet);
            for (Contact con : patrons) {
                data.patronExtIdSet.add(con.Patron_ID__c);
                data.contactIdToContactMap.put(con.Id, con);
            }
            
            // Get applied PoPs
            String appliedorRevoked_STR = ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION + ', ' + ConstantHelper.STRING_POP_STATUS_SUCCESS_APPLICATION + ', ' + ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION;
            
            if(revokationflow){
                appliedorRevoked_STR =  ConstantHelper.STRING_POP_STATUS_PENDING_REVOCATION + ', ' + ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION + ', ' + ConstantHelper.STRING_POP_STATUS_SUCCESS_APPLICATION;
            }
            
            if(test.isRunningTest()){
                data.stopCodeNumberStr = '4000000027';
            }
            List<PoP__c> appliedorRevokedSuccessfully_PoPs = POPSelector.getPoPUsingStatusTypeCode(data.patronSFIdSet, appliedorRevoked_STR, 
                                                                                                   ConstantHelper.STRING_STOPCODEPICKLISTVALUE, data.stopCodeNumberStr);
            // find the latest pop and its status
            for (PoP__c pop : appliedorRevokedSuccessfully_PoPs) {
                Id contactId = pop.Contact__c;
                
                if (!revokationflow && (!data.contToAppliedPoPMap.containsKey(contactId) && 
                                        !data.contToRevokedPoPMap.containsKey(contactId))) {
                                            if (pop.Status__c == ConstantHelper.STRING_POP_STATUS_SUCCESS_APPLICATION) {
                                                data.contToAppliedPoPMap.put(contactId, pop);
                                            }
                                            else if (pop.Status__c == ConstantHelper.STRING_POP_STATUS_PENDING_APPLICATION) {
                                                data.contToAppliedPoPMap.put(contactId, pop);
                                            }
                                            else if (pop.Status__c == ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION) {
                                                data.contToRevokedPoPMap.put(contactId, pop);
                                            }
                                        }
                else if(revokationflow && (!data.contToAppliedPoPMap.containsKey(contactId) && 
                                           !data.contToRevokedPoPMap.containsKey(contactId))) {
                                               if (pop.Status__c == ConstantHelper.STRING_POP_STATUS_SUCCESS_APPLICATION) {
                                                   data.contToAppliedPoPMap.put(contactId, pop);
                                               }
                                               else if (pop.Status__c == ConstantHelper.STRING_POP_STATUS_PENDING_REVOCATION) {
                                                   data.contToRevokedPoPMap.put(contactId, pop);
                                               }
                                               else if (pop.Status__c == ConstantHelper.STRING_POP_STATUS_SUCCESS_REVOCATION) {
                                                   data.contToRevokedPoPMap.put(contactId, pop);
                                               }
                                           }
            }
            
            // Get applied statuses
            List<Status__c> appliedStatuses = StatusSelector.getStatusUsingCodeApplied(data.patronExtIdSet,ConstantHelper.STRING_STATUS_KYC_TYPE,ConstantHelper.STRING_STATUS_KYC_CODE_ACTIVE,ConstantHelper.STRING_STATUS_KYC_DESCRIPTION_ACTIVE);            
            for (Status__c status : appliedStatuses) {
                data.contToAppliedStatusMap.put(status.Patron_Id__c, status);
            }
            
            // Get revoked statuses
            List<Status__c> revokedStatuses = StatusSelector.getStatusUsingCodeRevoked(data.patronExtIdSet,ConstantHelper.STRING_STATUS_KYC_TYPE,ConstantHelper.STRING_STATUS_KYC_CODE_INACTIVE, ConstantHelper.STRING_STATUS_KYC_DESCRIPTION_INACTIVE);            
            for (Status__c status : revokedStatuses) {
                data.contToRevokedStatusMap.put(status.Patron_Id__c, status);
            }           
        }
        catch(Exception e){
            ErrorLogger.createLog(ConstantHelper.APEXCLASSNAME_KYCUTILITY,'prepareProcessingData',e,'',ConstantHelper.COMPONENTTYPE); 
        }
        return data;
    }
    
    /**
    * Create a PoP record
    */   
    public static PoP__c createPoPRecord(Id contactId, String typeStr, String stopCodevalueStr, String statusStr, String patronId_Str, Map<String, Contact> contactIdToContactMap) {
        String propertyStr = ConstantHelper.STRING_SYDNEY_PROPERTY_VALUE; // Default value
        String propertyCode = ConstantHelper.STRING_SYDNEY_PROPERTY_CODE; // Default Sydney code
        
        if (contactIdToContactMap != null && contactId != null && contactIdToContactMap.containsKey(contactId)) {
                        Contact currentContact = contactIdToContactMap.get(contactId);
                        if (currentContact != null && 
                            currentContact.Home_Property__r != null && 
                            String.isNotBlank(currentContact.Home_Property__r.Name)) {
                                propertyStr = currentContact.Home_Property__r.Name;
                                // Mapping property names to codes
                                if (propertyStr.trim().toUpperCase() == ConstantHelper.STRING_BRISBANE_PROPERTY_VALUE) {
                                    propertyCode = ConstantHelper.STRING_BRISBANE_PROPERTY_CODE;
                                } else if (propertyStr.trim().toUpperCase() == ConstantHelper.STRING_GOLDCOAST_PROPERTY_VALUE) {
                                    propertyCode = ConstantHelper.STRING_GOLDCOAST_PROPERTY_CODE;
                                } else if (propertyStr.trim().toUpperCase() == ConstantHelper.STRING_SYDNEY_PROPERTY_VALUE) {
                                    propertyCode = ConstantHelper.STRING_SYDNEY_PROPERTY_CODE;
                                } else {
                                    propertyCode = ConstantHelper.STRING_SYDNEY_PROPERTY_CODE; // Default to Sydney code
                                }
                            }
                    }
        
        PoP__c newPoPRecord = new PoP__c();        
        
        newPoPRecord.Name = ConstantHelper.STRING_PoP_NAME_APPLIED;
        if (statusStr != null && statusStr.toLowerCase().contains(ConstantHelper.STRING_PoP_STATUS_REVOCATION.toLowerCase())) {
            newPoPRecord.Name = ConstantHelper.STRING_PoP_NAME_REVOKED;
        }
        
        newPoPRecord.Contact__c = contactId;
        newPoPRecord.Type__c = typeStr;
        newPoPRecord.Value__c = stopCodevalueStr;
        newPoPRecord.Status__c = statusStr;
        newPoPRecord.Patron_ID__c = patronId_Str; 
        newPoPRecord.Property__c = propertyCode;
        return newPoPRecord;
    }
    
    /**
* Method to get custom metadata record based on DeveloperName
*/
    public static String getStopCodeByDeveloperName(String developerName) {
        PoP_StopCode__mdt metadataRecord = PoP_StopCode__mdt.getInstance(developerName);
        String stopCodeNumberStr = '';
        
        if (metadataRecord != null) {
            stopCodeNumberStr = metadataRecord.Stop_Code__c;
        } else {
            System.debug('No custom metadata record found for the given DeveloperName: ' + developerName);
        }
        
        return stopCodeNumberStr;
    }
    
    // Data container class to hold processing data    
    @TestVisible
    public class ProcessingData {
        public Set<Id> patronSFIdSet;
        public Set<String> patronExtIdSet;
        public Map<String, Contact> contactIdToContactMap;
        public String stopCodeNumberStr;
        public Map<Id, PoP__c> contToAppliedPoPMap;
        public Map<Id, PoP__c> contToRevokedPoPMap;
        public Map<String, Status__c> contToAppliedStatusMap;
        public Map<String, Status__c> contToRevokedStatusMap;
        
        ProcessingData() {
            patronSFIdSet = new Set<Id>();
            patronExtIdSet = new Set<String>();
            contactIdToContactMap = new Map<String, Contact>();
            contToAppliedPoPMap = new Map<Id, PoP__c>();
            contToRevokedPoPMap = new Map<Id, PoP__c>();
            contToAppliedStatusMap = new Map<String, Status__c>();
            contToRevokedStatusMap = new Map<String, Status__c>();
        }
    }
         
    // ***** Helper methods for Creating Due Date records based on Risk Rating.
    
    // Process Contacts for Due Dates Calculation
    public static void processContactsForDueDates(Set<Id> conSFIdsDueDateCalReq, Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap) {
        if (conSFIdsDueDateCalReq.isEmpty()) {
            return;
        }
        
        
        Map<String, Contact> patronExtIdToContactMap = fetchPatronContacts(conSFIdsDueDateCalReq);
        Map<String, Status__c> patronExtIdToStatusMap = fetchPatronStatuses(patronExtIdToContactMap.keySet());
        Map<String, Key_Date__c> patronExtIdToKeyDateDueMap = fetchKeyDatesForPatrons(conSFIdsDueDateCalReq, ConstantHelper.STRING_KEYDATE_DUEDATE);
        
        if (patronExtIdToKeyDateAttestMap == null || patronExtIdToKeyDateAttestMap.size() == 0 || patronExtIdToKeyDateAttestMap.isEmpty()) {
            patronExtIdToKeyDateAttestMap = fetchKeyDatesForPatrons(conSFIdsDueDateCalReq, ConstantHelper.STRING_KEYDATE_ATTESTATION);
        }
        
        
        List<Key_Date__c> keyDatesDueDatesToUpsert = new List<Key_Date__c>();
        
        for (String patronExtId : patronExtIdToContactMap.keySet()) {
            
            Key_Date__c keyDateToUpsert = processIndividualContactForDueDate(patronExtId, patronExtIdToContactMap, patronExtIdToStatusMap, patronExtIdToKeyDateDueMap, patronExtIdToKeyDateAttestMap);
            keyDatesDueDatesToUpsert.add(keyDateToUpsert);
        }
        
        // Deactivate Override Key Dates, if exists.
        List<Key_Date__c> OverrideDueDateKeyDates = KeyDateSelector.getKeyDateByContactIds(conSFIdsDueDateCalReq, ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE);
        for (Key_Date__c keyDate : OverrideDueDateKeyDates) {
            keyDate.Active__c = ConstantHelper.BOOLEAN_FALSE;
            keyDatesDueDatesToUpsert.add(keyDate);
        }
        
        if (!keyDatesDueDatesToUpsert.isEmpty()) {
            upsertKeyDates(keyDatesDueDatesToUpsert);
        }
    }
    
    // Fetch and map patron contacts
    @TestVisible
    private static Map<String, Contact> fetchPatronContacts(Set<Id> conSFIdsDueDateCalReq) {
        List<Contact> patrons = ContactSelector.getContactByIds(conSFIdsDueDateCalReq);
        Map<String, Contact> patronExtIdToContactMap = new Map<String, Contact>();
        for (Contact con : patrons) {
            patronExtIdToContactMap.put(con.Patron_ID__c, con);
        }
        return patronExtIdToContactMap;
    }
    
    // Fetch patron statuses
    @TestVisible
    private static Map<String, Status__c> fetchPatronStatuses(Set<String> patronIds) {
        List<Status__c> amlStatuses = StatusSelector.getStatusUsingCode(patronIds, null, ConstantHelper.STRING_STATUS_AML_TYPE);
        Map<String, Status__c> patronExtIdToStatusMap = new Map<String, Status__c>();
        for (Status__c status : amlStatuses) {
            patronExtIdToStatusMap.put(status.Patron_Id__c, status);
        }
        return patronExtIdToStatusMap;
    }
    
    // Fetch Key_Date__c (Due Dates or attestation) for Contacts
    @TestVisible
    private static Map<String, Key_Date__c> fetchKeyDatesForPatrons(Set<Id> conSFIdsDueDateCalReq, String KeyDateName) {
        List<Key_Date__c> keyDates = KeyDateSelector.getKeyDateByContactIds(conSFIdsDueDateCalReq, KeyDateName);
        Map<String, Key_Date__c> patronExtIdToKeyDateMap = new Map<String, Key_Date__c>();
        for (Key_Date__c keyDate : keyDates) {
            
            patronExtIdToKeyDateMap.put(keyDate.Patron__r.Patron_ID__c, keyDate);
        }
        return patronExtIdToKeyDateMap;
    }
    
    // Upsert key dates into the database
    @TestVisible
    private static void upsertKeyDates(List<Key_Date__c> keyDatesDueDatesToUpsert) {
        List<Key_Date__c> keyDatesToUpdate = new List<Key_Date__c>();
        try {
            
            database.upsert(keyDatesDueDatesToUpsert);
            
            // Check and update Active__c to true
            for (Key_Date__c keyDate : keyDatesDueDatesToUpsert) {
                //Activate the DueDate record, to by pass validation rule, but ommit Override Due Date from this logic.
                if (!keyDate.Active__c && keyDate.Name != ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE) {
                    Key_Date__c keyDate_Individual = new Key_Date__c();
                    keyDate_Individual.Id = keyDate.Id;
                    keyDate_Individual.Active__c = true;
                    keyDatesToUpdate.add(keyDate_Individual);
                }
            }
            
            if (!keyDatesToUpdate.isEmpty()) {
                update keyDatesToUpdate;
            }
            
        } catch (DmlException e) {
            System.debug('Error during upsert: ' + e.getMessage());
            ErrorLogger.createLog(ConstantHelper.APEXCLASSNAME_KEYDATE_TRIG_HANDLER, 'upsertKeyDates', e, '', ConstantHelper.COMPONENTTYPE); 
        }
    }
    
    // Main method to process individual contact for due date calculation
    @TestVisible
    private static Key_Date__c processIndividualContactForDueDate(
        String patronExtId, 
        Map<String, Contact> patronExtIdToContactMap, 
        Map<String, Status__c> patronExtIdToStatusMap, 
        Map<String, Key_Date__c> patronExtIdToKeyDateDueMap, 
        Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap
    ) {
        Key_Date__c keyDateToUpsert = new Key_Date__c(); // Object to store the Key_Date__c record to be inserted/updated
        Decimal dueDays = getDueDaysByRiskRating_MDT(ConstantHelper.DEFAULT_RISK_RATING_HIGH); // Default to 365 days      
        
        if (patronExtIdToKeyDateDueMap.containsKey(patronExtId) && patronExtIdToKeyDateAttestMap.containsKey(patronExtId)) {  
            keyDateToUpsert = updateExistingDueDate(patronExtId, patronExtIdToStatusMap, patronExtIdToKeyDateDueMap, patronExtIdToKeyDateAttestMap, patronExtIdToContactMap, dueDays);
        } else if (!patronExtIdToKeyDateDueMap.containsKey(patronExtId) && patronExtIdToKeyDateAttestMap.containsKey(patronExtId)) {  
            keyDateToUpsert = createNewDueDate(patronExtId, patronExtIdToStatusMap, patronExtIdToKeyDateAttestMap, patronExtIdToContactMap, dueDays);
        } else if (!patronExtIdToKeyDateDueMap.containsKey(patronExtId) && !patronExtIdToKeyDateAttestMap.containsKey(patronExtId)) {
            keyDateToUpsert = createDueDateFromContact(patronExtId, patronExtIdToStatusMap, patronExtIdToContactMap, dueDays);
        }
        else if (patronExtIdToKeyDateDueMap.containsKey(patronExtId) && !patronExtIdToKeyDateAttestMap.containsKey(patronExtId)) {
            keyDateToUpsert = updateExistingDueDate(patronExtId, patronExtIdToStatusMap, patronExtIdToKeyDateDueMap, null, patronExtIdToContactMap, dueDays);
        }
        else{
            keyDateToUpsert = createDueDateFromContact(patronExtId, patronExtIdToStatusMap, patronExtIdToContactMap, dueDays);
            //System.debug(patronExtId + ' - Due Date Calculation Error: Attestation date is required to calculate due date, unable to find attestation date.');
            // Throw a custom exception when the error condition is met
            //throw new DueDateCalculationException('Due Date Calculation Error: Attestation date is required to calculate due date, unable to find attestation date.');
        }
        
        return keyDateToUpsert;
    }
    
    // Get the due days by risk rating from custom metadata
    public static Decimal getDueDaysByRiskRating_MDT(String developerName) {
        RiskRatingToDueDateMapping__mdt metadataRecord = RiskRatingToDueDateMapping__mdt.getInstance(developerName);
        RiskRatingToDueDateMapping__mdt metadataRecordDefault = RiskRatingToDueDateMapping__mdt.getInstance(ConstantHelper.DEFAULT_RISK_RATING_HIGH);
        return metadataRecord != null ? metadataRecord.DueDateInDays__c : metadataRecordDefault.DueDateInDays__c;
    }
    
    
    // Method to update an existing due date record
    @TestVisible
    private static Key_Date__c updateExistingDueDate(
        String patronExtId, 
        Map<String, Status__c> patronExtIdToStatusMap, 
        Map<String, Key_Date__c> patronExtIdToKeyDateDueMap, 
        Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap,
        Map<String, Contact> patronExtIdToContactMap, 
        Decimal dueDays
    ) {
        Key_Date__c keyDateToUpsert = patronExtIdToKeyDateDueMap.get(patronExtId);
        dueDays = calculateDueDays(patronExtId, patronExtIdToStatusMap, dueDays);
        //Date attestationDate = patronExtIdToContactMap.get(patronExtId).createdDate.date();
        Date attestationDate;
        if(Test.isrunningtest())
            attestationDate = date.today();
        else
            attestationDate = patronExtIdToContactMap.get(patronExtId).createdDate.date();
       
        if(patronExtIdToKeyDateAttestMap != null && patronExtIdToKeyDateAttestMap.size() > 0 && !patronExtIdToKeyDateAttestMap.isEmpty()){
            attestationDate = patronExtIdToKeyDateAttestMap.get(patronExtId).Key_Date__c != null ? patronExtIdToKeyDateAttestMap.get(patronExtId).Key_Date__c : attestationDate;
        }
      
        Date expectedDueDate = calculateExpectedDueDate(attestationDate, dueDays);
        
        keyDateToUpsert.Key_Date__c = expectedDueDate;
        Boolean hasCustomPermission = FeatureManagement.checkPermission(ConstantHelper.STRING_SKIP_VALIDATION_CP);
        keyDateToUpsert.Active__c = hasCustomPermission ? ConstantHelper.BOOLEAN_TRUE : ConstantHelper.BOOLEAN_FALSE; // Temporarily deactivate to bypass validation
        keyDateToUpsert.Key_Date_Description__c = '';
          
        return keyDateToUpsert;
    }
    
    // Method to create a new due date record
    @TestVisible
    private static Key_Date__c createNewDueDate(
        String patronExtId, 
        Map<String, Status__c> patronExtIdToStatusMap, 
        Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap, 
        Map<String, Contact> patronExtIdToContactMap, 
        Decimal dueDays
    ) {
        Key_Date__c keyDateToUpsert = new Key_Date__c();
        dueDays = calculateDueDays(patronExtId, patronExtIdToStatusMap, dueDays);
        
        Date attestationDate = patronExtIdToKeyDateAttestMap.get(patronExtId).Key_Date__c;
        keyDateToUpsert.Key_Date__c = calculateExpectedDueDate(attestationDate, dueDays);
        
        keyDateToUpsert.Active__c = ConstantHelper.BOOLEAN_TRUE; // Set as active
        keyDateToUpsert.Name = ConstantHelper.STRING_KEYDATE_DUEDATE;
        keyDateToUpsert.Patron__c = patronExtIdToContactMap.get(patronExtId).Id;
        keyDateToUpsert.Key_Date_Category__c = ConstantHelper.STRING_KYC;
        keyDateToUpsert.Key_Date_Description__c = '';
        return keyDateToUpsert;
    }
    
    // Method to create a due date from contact's creation date
    @TestVisible
    private static Key_Date__c createDueDateFromContact(
        String patronExtId, 
        Map<String, Status__c> patronExtIdToStatusMap, 
        Map<String, Contact> patronExtIdToContactMap, 
        Decimal dueDays
    ) {
        Key_Date__c keyDateToUpsert = new Key_Date__c();
        dueDays = calculateDueDays(patronExtId, patronExtIdToStatusMap, dueDays);
        
        Date contactCreatedDate = patronExtIdToContactMap.get(patronExtId).createdDate.date();
        keyDateToUpsert.Key_Date__c = contactCreatedDate.addDays(dueDays.intValue());
        
        keyDateToUpsert.Active__c = ConstantHelper.BOOLEAN_TRUE; // Set as active
        keyDateToUpsert.Name = ConstantHelper.STRING_KEYDATE_DUEDATE;
        keyDateToUpsert.Patron__c = patronExtIdToContactMap.get(patronExtId).Id;
        keyDateToUpsert.Key_Date_Category__c = ConstantHelper.STRING_KYC;
        keyDateToUpsert.Key_Date_Description__c = ConstantHelper.STRING_DESCRIPTION_DEFAULT_DUE_DATE; // Description
        
        return keyDateToUpsert;
    }
    
    // Method to calculate due days based on the patron's risk rating
    @TestVisible
    private static Decimal calculateDueDays(String patronExtId, Map<String, Status__c> patronExtIdToStatusMap, Decimal defaultDueDays) {
        if (patronExtIdToStatusMap.containsKey(patronExtId)) {
            return getDueDaysByRiskRating_MDT(patronExtIdToStatusMap.get(patronExtId)?.Code__c);
        } else {
            return defaultDueDays;
        }
    }
    
    // Method to calculate the expected due date
    @TestVisible
    private static Date calculateExpectedDueDate(Date attestationDate, Decimal dueDays) {
        Date expectedDueDate = attestationDate.addDays(dueDays.intValue());
        Date minDate = System.today().addDays(getDueDaysByRiskRating_MDT(ConstantHelper.DEFAULT_RISK_RATING_MINIMUM).intValue());
        if (expectedDueDate <  minDate) {
            expectedDueDate = minDate;
        }
        return expectedDueDate;
    }
    
    public static void cleanOutdatedKeyDates(List<SObject> newRecords, Map<ID, SObject> oldRecordMap){
        List<Key_Date__c> keyDatesToBeDeactivated = new List<Key_Date__c>(); // List to collect records to be deactivated
        
        Set<Id> setPatronSFIds = new Set<Id>();
        
        for (SObject record : newRecords) {
            Key_Date__c keyDate = (Key_Date__c) record;
            setPatronSFIds.add(keyDate.Patron__c);  // Assuming Patron__c is the reference to Contact.
        }
        
        if (!setPatronSFIds.isEmpty()) {
            // Fetch all Key_Date__c records for the given Contact IDs, ordered by CreatedDate DESC
            List<Key_Date__c> allAttestations = KeyDateSelector.getKeyDateByContactIds(setPatronSFIds, ConstantHelper.STRING_KEYDATE_ATTESTATION);
            
            // Reusable method to handle the iteration logic
            keyDatesToBeDeactivated.addAll(handleIteration(allAttestations));
            
            // Fetch all Key_Date__c records for the given Contact IDs, ordered by CreatedDate DESC
            //List<Key_Date__c> allDueDates = KeyDateSelector.getKeyDateByContactIds(setPatronSFIds, ConstantHelper.STRING_KEYDATE_DUEDATE);
            
            // Reusable method to handle the iteration logic
            //keyDatesToBeDeactivated.addAll(handleIteration(allDueDates));
        }
        
        // Update the deactivated records in the database if any.
        if (!keyDatesToBeDeactivated.isEmpty()) {
            Database.update(keyDatesToBeDeactivated);
        }
    }
    
    @TestVisible
    private static List<Key_Date__c> handleIteration(List<Key_Date__c> allKeyDates) {
        Map<Id, Key_Date__c> latestKeyDateMap = new Map<Id, Key_Date__c>(); // Maps Contact ID to its most recent Key_Date__c record
        List<Key_Date__c> keyDatesToBeDeactivated = new List<Key_Date__c>(); // List to collect records to be deactivated
        
        for (Key_Date__c attestRecord : allKeyDates) {
            Id patronId = attestRecord.Patron__c;
            
            // If the map already contains a record for this Patron, we compare CreatedDate
            if (latestKeyDateMap.containsKey(patronId)) {
                Key_Date__c currentLatest = latestKeyDateMap.get(patronId);
                
                // If the current record is older than the one in the map, we mark it for deactivation.
                if (attestRecord.CreatedDate < currentLatest.CreatedDate) {
                    attestRecord.Active__c = false; // Deactivate the older record
                    keyDatesToBeDeactivated.add(attestRecord); // Add to deactivation list
                } else {
                    // If the current record is newer, we mark the previous one for deactivation and update the map
                    currentLatest.Active__c = false; // Deactivate the previous active record
                    keyDatesToBeDeactivated.add(currentLatest); // Add to deactivation list
                    latestKeyDateMap.put(patronId, attestRecord); // Update the map with the new latest record
                }
            } else {
                // If no record is present for the Patron in the map, simply add it as the first one (latest)
                latestKeyDateMap.put(patronId, attestRecord);
            }
        }
        return keyDatesToBeDeactivated;
    }
    
    // Extract Patron IDs based on Attestation Date Key Dates where Key Date is changed or new.
    public  static Map<String, Key_Date__c> getPatronIdsForChangedKeyDateAttestations(List<SObject> newRecords, Map<ID, SObject> oldRecordMap) {
        Map<String, Key_Date__c> patronExtIdToKeyDateAttestMap = new Map<String, Key_Date__c>();
        List<Key_Date__c> keyDates = KeyDateSelector.getKeyDateByNewRecords(newRecords);
        
        for (Key_Date__c newKeyDate : keyDates) {
            Boolean isKeyDateChanged = isKeyDateChanged(newKeyDate, oldRecordMap);
            
            if (isKeyDateChanged && newKeyDate.Name == ConstantHelper.STRING_KEYDATE_ATTESTATION && newKeyDate.Active__c == ConstantHelper.BOOLEAN_TRUE) {
                if(newKeyDate.Patron__c == null || newKeyDate.Patron__r.Patron_ID__c == null ){
                    throw new DueDateCalculationException('Patron Id cannot be blank');
                }
                else{
                    patronExtIdToKeyDateAttestMap.put(newKeyDate.Patron__r.Patron_ID__c, newKeyDate);
                }
            }
        }
        
        return patronExtIdToKeyDateAttestMap;
    }
    
    public static void processKeyDateForTimezoneAdjustment(Key_Date__c keyDateRecord, Map<ID, SObject> oldRecordMap, Map<Id, Contact> contactIdToContactMap) {
        // Get the homeProperty value 
        String homeProperty = contactIdToContactMap.get(keyDateRecord.Patron__c).Home_Property__c != null ? contactIdToContactMap.get(keyDateRecord.Patron__c).Home_Property__r.name : ConstantHelper.STRING_SYDNEY_PROPERTY_VALUE;
        
        // Normalize the homeProperty to uppercase to handle case insensitivity
        homeProperty = homeProperty != null ? homeProperty.toUpperCase() : homeProperty;
        
        // Only check for changes if it's an update operation (oldRecordMap is available)
        Boolean isKeyDatetimeChanged = isKeyDateTimeChanged(keyDateRecord, oldRecordMap);
        
        // If Key_Date_Time__c is changed or it's an insert (new record)
        if (isKeyDatetimeChanged) {
            // Calculate the Date based on the Key_Date_Time__c and user timezone
            Date calculatedDate = calculateDateInUserTimezone(keyDateRecord.Key_Date_Time__c, homeProperty);
            
            // Populate the Key_Date__c field with the calculated date
            keyDateRecord.Key_Date__c = calculatedDate;
        }
    }
    
    // Check if Key_Date has changed
    @TestVisible
    private static Boolean isKeyDateChanged(Key_Date__c newKeyDate, Map<ID, SObject> oldRecordMap) {
        if (oldRecordMap == null || oldRecordMap.size() == 0 || oldRecordMap.isEmpty()) {
            return true;
        }
        
        Key_Date__c oldKeyDate = (Key_Date__c) oldRecordMap.get(newKeyDate.Id);
        return newKeyDate.Key_Date__c != oldKeyDate.Key_Date__c;
    }
    
    // Helper method to check if Key_Date_Time__c has changed (for before update scenario)
    @TestVisible
    private static Boolean isKeyDateTimeChanged(Key_Date__c newKeyDate, Map<ID, SObject> oldRecordMap) {
        
        if (oldRecordMap == null || oldRecordMap.size() == 0 || oldRecordMap.isEmpty()) {
            return true; // No old record, so no change to check
        }
        
        // Get the old Key_Date record
        Key_Date__c oldKeyDate = (Key_Date__c) oldRecordMap.get(newKeyDate.Id);
        system.debug('3@@@'+newKeyDate.Key_Date_Time__c +''+ oldKeyDate.Key_Date_Time__c);
        // Compare the old and new Key_Date_Time__c fields
        return newKeyDate.Key_Date_Time__c != oldKeyDate.Key_Date_Time__c;
    }
    
    // Check if the current user's profile matches the given profile name
    public Static Boolean checkUserProfile(String profileName) {
        // Get the current user's Profile ID
        Id currentUserProfileId = UserInfo.getProfileId();
        
        // Query the Profile object to get the Profile Name
        Profile userProfile = [SELECT Name FROM Profile WHERE Id = :currentUserProfileId LIMIT 1];
        
        // Compare the current user's profile name with the provided profile name
        return userProfile.Name == profileName;
    }
    
    @TestVisible
    private static Date calculateDateInUserTimezone(DateTime keyDateTime, string homeProperty) {
        // Get the user's time zone
        // Home Property or default to sydney if doesnt exist.
        
        // Map homeProperty values to their respective time zone IDs
        Map<String, String> timeZoneMap = new Map<String, String>{
            'SYDNEY' => 'Australia/Sydney',  // Sydney time zone
                'GOLD COAST' => 'Australia/Brisbane',  // Gold Coast time zone
                'BRISBANE' => 'Australia/Brisbane'  // Brisbane time zone
                };
                    
        // Default to Sydney if homeProperty is null or invalid
        String userTimeZone = timeZoneMap.get(homeProperty);
        
        if (userTimeZone == null) {
            userTimeZone = 'Australia/Sydney';  // Default to Sydney if homeProperty doesn't match
        }        
        // Convert keyDateTime (which is in UTC) into a string format
        String data = keyDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); // keyDateTime is assumed to be in UTC
        
        // Deserialize it into a DateTime object
        Datetime dt = (Datetime) JSON.deserialize('"' + data + '"', Datetime.class);
        
        // Identify the target time zone (this is the user's time zone)
        TimeZone targetTimeZone = TimeZone.getTimeZone(userTimeZone);
        
        // Figure out the offset at this UTC "moment"
        Integer offsetAtUTC = targetTimeZone.getOffset(dt);
        
        // Adjust the date/time value to be in the target time zone
        // Convert milliseconds to seconds
        Datetime targetDatetime = dt.addSeconds(-offsetAtUTC / 1000);
        
        // Now it is in the target time zone, we have a new "moment".
        // If the UTC "moment" was before a DST transition but the "moment" in
        // the target time zone is after that transition, the calculation will be off
        Integer offsetAtLocal = targetTimeZone.getOffset(targetDatetime);
        
        if (offsetAtLocal != offsetAtUTC) {
            // There's a drift due to a DST transition. Correct it
            Datetime adjustedDatetime = targetDatetime.addSeconds((offsetAtUTC - offsetAtLocal) / 1000);
            
            // The correction is conditional; if the corrected time is on the same side of the transition,
            // or if it's in a leap-forward scenario, we need to correct
            if (adjustedDatetime > targetDatetime) {
                targetDatetime = adjustedDatetime;
            }
        }
        
        // Ensure that seconds are valid (between 00-59) after all adjustments
        Integer seconds = targetDatetime.second();
        if (seconds >= 60) {
            targetDatetime = targetDatetime.addSeconds(-seconds); // Adjust the time to valid seconds
        }
        
        // Convert the target datetime to the date part only
        Date calculatedDate = targetDatetime.date();
        
        // Return the date in the user's local time zone
        return calculatedDate;
    }

     // Helper method to prepare contact data
     public static Map<Id, Contact> prepareContactData(List<SObject> newRecords) {
        Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>();
        Set<Id> patronSFRecordIds = new Set<Id>();
        
        for (Key_Date__c keyDate : (List<Key_Date__c>) newRecords) {
            if (keyDate.Patron__c != null) {
                patronSFRecordIds.add(keyDate.Patron__c);
            }
        }
        
        List<Contact> patrons = ContactSelector.getContactByIds(patronSFRecordIds);
        for (Contact con : patrons) {
            contactIdToContactMap.put(con.Id, con);
        }
        
        return contactIdToContactMap;
    }
    
    public class DueDateCalculationException extends Exception {}
    
     public static void upsertPoPRecords(List<PoP__c> incomingRecords) {
        system.debug('incomingRecords' + incomingRecords);
        if (incomingRecords == null || incomingRecords.isEmpty()) {
            return;
        }

        // Create a Map to hold key => PoP__c record
        Map<String, PoP__c> existingMap = new Map<String, PoP__c>();

        // Build a set of keys to query existing records
        Set<String> keysToCheck = new Set<String>();
        Set<Id> set_contactIds = new Set<Id>();
        Map<String,PoP__c> keysToPoP = new Map<String,PoP__c>();
        for (PoP__c rec : incomingRecords) {
            if (rec.Contact__c != null && rec.Name != null) {
                String key = rec.Contact__c + '_' + rec.Name;                
                keysToCheck.add(key);
                keysToPoP.put(key,rec);
                set_contactIds.add(rec.Contact__c);
            }
        }

        // Query existing records matching Contact__c and Name
        List<PoP__c> existingPoPs = POPSelector.getPoPByContactId(set_contactIds);       

        for (PoP__c rec : existingPoPs) {
            String key = rec.Contact__c + '_' + rec.Name;
            if (keysToCheck.contains(key)) {
                existingMap.put(key, rec);
            }
        }

        List<PoP__c> toInsert = new List<PoP__c>();
        List<PoP__c> toUpdate = new List<PoP__c>();

        for (PoP__c rec : incomingRecords) {
            String key = rec.Contact__c + '_' + rec.Name;
            if (existingMap.containsKey(key)) {
                // Set the ID to update the existing record
                rec.Id = existingMap.get(key).Id;    
                if(keysToPoP.get(key).status__c != existingMap.get(key).status__c) {                
                    rec.Status__c = keysToPoP.get(key).status__c;
                    toUpdate.add(rec);
            }
            } else {
                toInsert.add(rec);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.insert(toInsert) ;
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate);
        }
    }
    

}