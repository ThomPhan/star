public class GetOriginChoicesAction {
	
    // ONLY used in tests
    @TestVisible static Boolean TEST_MODE = false;
    @TestVisible static List<Exl_CaseTypePicklistConfig__mdt> TEST_MAPPINGS; 
    
    public class Output {
        @InvocableVariable public PicklistEntryValue[] entries = new PicklistEntryValue[0];
    }
    public class Input {
        @InvocableVariable public String caseType;
        @InvocableVariable public String state;
    }
    
    @InvocableMethod(
        label='Get Origin Choices'
        description='Returns picklist-ready label/value pairs (Origin/Source) for Case Type and State.'
    )
    
    public static List<Output> getChoices(List<Input> inputs) {
        List<Output> results = new List<Output>();
        if (inputs == null || inputs.isEmpty()) return results;

        /*Set<String> userIds = new Set<Id>();
        for (Input i : inputs) {
            if (i != null && i.userId != null) userIds.add(i.userId);
        }

        Map<Id, List<String>> userToTypes = new Map<Id, List<String>>();
        for (Id uid : userIds) {
            userToTypes.put(uid, getCaseTypesForUser(uid));
        }
		*/

        for (Input i : inputs) {
            Output out = new Output();
            String caseType = null;
            String state = null;
            if (i != null) { 
                caseType = i.caseType;
                state = i.state;
            }
            
            if (!String.isBlank(caseType) && !String.isBlank(state)) {
                Set<String> origins = getOriginForCaseState(caseType, state);
                // build picklist entries
                for (String rec : origins) {
                    out.entries.add(new PicklistEntryValue(rec, rec));
                }
                
                results.add(out);
            }
        }
        return results;
    }

    private static Set<String> getOriginForCaseState(String caseType, String state) {
        if (String.isBlank(caseType) || String.isBlank(state)) { 
            return new Set<String>();
        } else {
            List<Exl_CaseTypePicklistConfig__mdt> mappings;
            if (TEST_MODE && TEST_MAPPINGS != null) {
            	mappings = TEST_MAPPINGS;
            } else { 
            	mappings = [SELECT Origin_Source__c FROM Exl_CaseTypePicklistConfig__mdt
            				WHERE Case_Type__c =: caseType AND State__c =: state];
            }
            
            Set<String> origins = new Set<String>();
            for (Exl_CaseTypePicklistConfig__mdt m : mappings) {
                if (String.isNotBlank(m.Origin_Source__c)) {
                    for (String s : m.Origin_Source__c.split(',')) {
                        if (String.isNotBlank(s)) origins.add(s.trim());
                    }
                }
            }
            return origins;
        }
    }
}