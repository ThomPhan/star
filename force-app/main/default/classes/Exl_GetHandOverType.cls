public class Exl_GetHandOverType {
    
    // ONLY used in tests
    @TestVisible static Boolean TEST_MODE = false;
    @TestVisible static List<Exl_CaseTypePicklistConfig__mdt> TEST_MAPPINGS; 
    
    public class Output {
        @InvocableVariable public PicklistEntryValue[] entries = new PicklistEntryValue[0];
    }
    public class Input {
        @InvocableVariable public Case caseRecord;
        @InvocableVariable public Boolean hideExtraHandoverTypes;
    }
    
    @InvocableMethod(
        label='Get Hand Over Type Choices'
        description='Returns picklist-ready label/value pairs (Handover Type) for Exclusion Record field.'
    )
    
    public static List<Output> getChoices(Input[] inputs) {
        List<Output> results = new List<Output>();
        Output out = new Output();
        List<String> activeValues = new List<String>();
        case caseVar = new case();
        Boolean hideExtraHandoverTypesVar = true;
        List<String> excludedEntriesList = new List<String>();
        if(!inputs.isEmpty()){
            
            for(Input var: inputs) {
                caseVar = var.caseRecord;
                hideExtraHandoverTypesVar = var.hideExtraHandoverTypes != null ? var.hideExtraHandoverTypes : true;
            }
            if(caseVar != null){
                //Should not be removed from the picklist as per business request in PoP-1333.
                //if(strCaseStatus.equalsIgnoreCase('Amendment In Progress')){
                    //String excludedEntriesString = 'Amend';  //Not to be removed from picklist as requested by business on PoP-1333
                    //excludedEntriesList = excludedEntriesString.split(',');
                //}
                if(caseVar.RecordTypeId == Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('Exl_Revoke_Exclusion').getRecordTypeId() || caseVar.Type == 'TP7DAY' || caseVar.Type == 'TP24HR'){ 
					String excludedEntriesString = 'Amend';  //To be removed For Revocation && TPOE's
                    excludedEntriesList = excludedEntriesString.split(',');
                } else if(caseVar.RecordTypeId == Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('Exl_Apply_Exclusion').getRecordTypeId()) { 
					String excludedEntriesString = 'Not Required,Manually Generated';  //To be removed For Revocation && TPOE's
                    excludedEntriesList = excludedEntriesString.split(',');
                }
                
                if(hideExtraHandoverTypesVar) { 
                    excludedEntriesList.add('Not Required');
                    excludedEntriesList.add('Manually Generated');
                }
                Schema.DescribeFieldResult fieldDetail = WorkOrderLineItem.Handover_Type__c	.getDescribe();
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
            }
        }
        return results;
    }
}