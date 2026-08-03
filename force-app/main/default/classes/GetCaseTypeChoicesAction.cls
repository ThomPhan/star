public with sharing class GetCaseTypeChoicesAction {

    // ---- Test seam (ONLY used in tests) ----
    @TestVisible static Boolean TEST_MODE = false;
    @TestVisible static List<String> TEST_CUSTOM_PERMS;
    @TestVisible static List<Custom_Permissions_Case_Type_Mapping__mdt> TEST_MAPPINGS;

    public class Output {
        @InvocableVariable public PicklistEntryValue[] entries = new PicklistEntryValue[0];
    }
    public class Input {
        @InvocableVariable public Id userId;
        @InvocableVariable public String flowName;
        @InvocableVariable public String removeOutcome;
    }

    @InvocableMethod(
        label='Get Case Type Choices'
        description='Returns picklist-ready label/value pairs (Case Types) for each input user.'
    )
    public static List<Output> getChoices(List<Input> inputs) {

        List<Output> results = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            return results;
        }

        for (Input inp : inputs) {

            Output out = new Output();

            if (inp == null || inp.userId == null) {
                results.add(out);
                continue;
            }

            List<String> userCaseTypes = getCaseTypesForUser(inp.userId, inp.flowName, inp.removeOutcome);

            if (userCaseTypes != null && !userCaseTypes.isEmpty()) {
                Set<String> uniq = new Set<String>();
                for (String t : userCaseTypes) {
                    if (String.isNotBlank(t)) uniq.add(t.trim());
                }
                List<String> sorted = new List<String>(uniq);
                sorted.sort();

                for (String t : sorted) {
                    out.entries.add(new PicklistEntryValue(t, t));
                }
            }

            results.add(out);
        }

        return results;
    }

    private static List<String> getCaseTypesForUser(Id userId, String flowName, String removeOutcome) {
        if (userId == null) return new List<String>();

        // Determine user's Custom Permission names
        List<String> userCustomPermissions;
        if (TEST_MODE && TEST_CUSTOM_PERMS != null) {
            userCustomPermissions = TEST_CUSTOM_PERMS;
        } else {
            userCustomPermissions = CustomPermissionUtils.getCustomPermissionsForUser(userId);
        }

        if (userCustomPermissions == null || userCustomPermissions.isEmpty()) {
            return new List<String>();
        }

        // Fetch mappings
        List<Custom_Permissions_Case_Type_Mapping__mdt> mappings = new List<Custom_Permissions_Case_Type_Mapping__mdt>();
        if (TEST_MODE && TEST_MAPPINGS != null) {
            mappings = TEST_MAPPINGS;
        } else {
            mappings = [
                SELECT Case_Types__c, Case_Types_Contraventions__c, Case_Types_Preventions__c,
                       Case_Types_Revocations__c, Custom_Permission_Name__c
                FROM Custom_Permissions_Case_Type_Mapping__mdt
                WHERE Custom_Permission_Name__c IN :userCustomPermissions
            ];
        }

        // Parse and collect case types
        List<String> caseTypes = new List<String>();

        for (Custom_Permissions_Case_Type_Mapping__mdt m : mappings) {

            String caseTypeString;

            if (String.isBlank(flowName) ||
                ConstantHelper.STRING_APPLY_EXCLUSION_FLOW.equalsIgnoreCase(flowName)) {

                caseTypeString = m.Case_Types__c;

            } else if (ConstantHelper.STRING_APPLY_CONTRAVENTION_FLOW.equalsIgnoreCase(flowName)) {

                caseTypeString = m.Case_Types_Contraventions__c;

            } else if (ConstantHelper.STRING_APPLY_TPOE_FLOW.equalsIgnoreCase(flowName)) {

                caseTypeString = m.Case_Types_Preventions__c;

            } else if (ConstantHelper.STRING_CASE_REVOCATION_OUTCOME.equalsIgnoreCase(flowName)) {

                caseTypeString = m.Case_Types_Revocations__c;

            } else {
                caseTypeString = m.Case_Types__c;
            }

            if (String.isNotBlank(caseTypeString)) {
                for (String s : caseTypeString.split(',')) {
                    if (String.isNotBlank(s)) {
                        String trimmed = s.trim();
                        if (!caseTypes.contains(trimmed)) {
                            caseTypes.add(trimmed);
                        }
                    }
                }
            }
        }

        // removeOutcome logic
        if(!String.isBlank(removeOutcome)) {
            List<String> removeOutcomeList = new List<String>();
            if(removeOutcome.contains(',')) {
                for(String outcomeValue : removeOutcome.split(',')) {
                    removeOutcomeList.add(outcomeValue.trim());
                }
            } else {
                removeOutcomeList.add(removeOutcome.trim());
            }

            for(String outcome : removeOutcomeList) {
                Integer num = caseTypes.indexOf(outcome);
                if(num >= 0) {
                    caseTypes.remove(num);
                }
            }
        } 

        return caseTypes;
    }
}