public class GetDeliveryStatusChoicesAction {
	
    // ONLY used in tests
    @TestVisible static Boolean TEST_MODE = false;
    @TestVisible static List<Exl_CaseTypePicklistConfig__mdt> TEST_MAPPINGS; 
    
    public class Output {
        @InvocableVariable public PicklistEntryValue[] entries = new PicklistEntryValue[0];
    }
    public class Input {
        //@InvocableVariable public String caseType;
        //@InvocableVariable public String state;
    }
    
    @InvocableMethod(
        label='Get Delivery Status Choices'
        description='Returns picklist-ready label/value pairs (Delivery Status) for Exclusion Record field.'
    )
    
    public static List<Output> getChoices() {
        List<Output> results = new List<Output>();
        Output out = new Output();
        List<String> activeValues = new List<String>();
        
        String excludedEntriesString = System.Label.Excluded_Delivery_Status;
        List<String> excludedEntriesList = excludedEntriesString.split(',');
        Schema.DescribeFieldResult fieldDetail = Exl_Exclusion__c.Delivery_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDetail.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            if(!excludedEntriesList.contains(entry.getValue())) {
                if (entry.isActive()) {
                    activeValues.add(entry.getValue());
                }
            }
        }
        // build picklist entries
        for (String rec : activeValues) {
            out.entries.add(new PicklistEntryValue(rec, rec));
        }
        results.add(out);
        return results;
    }
}