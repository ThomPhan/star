public with sharing class GetExclusionChoicesAction {

    // === Flow I/O DTOs ===
    public class Input {
        @InvocableVariable public Id contactId;
    }
    public class Output {
        // Flow maps this to an Apex-Defined collection variable of type ExlExclusionChoiceItem
        @InvocableVariable public ExlExclusionChoiceItem[] entries = new ExlExclusionChoiceItem[0];
    }

    @InvocableMethod(
        label='Get Exclusion Choices (Each Exclusion)'
        description='Returns picklist-ready label/value pairs for all exclusions for a contact, irrespective of Case.'
    )
    public static List<Output> getChoices(List<Input> inputs) {
        List<Output> results = new List<Output>();
        if (inputs == null || inputs.isEmpty()) return results;

        for (Input i : inputs) {
            Output out = new Output();
            results.add(out);  // always add an Output so Flow mapping is stable

            if (i == null || i.contactId == null) continue;

            // --- A) Exclusions tied via Case (RevokeCase__r.ContactId) ---
            List<Exl_Exclusion__c> byCase = [
                SELECT Id, Name, POE_Type__c, Origin__c, CreatedDate
                FROM Exl_Exclusion__c
                WHERE RevokeCase__r.ContactId = :i.contactId
                ORDER BY CreatedDate DESC
                LIMIT 2000
            ];
            // If you gate by status, add: AND Status__c = 'Active'

            // --- B) Exclusions directly linked via Contact__c (if that field exists) ---
            List<Exl_Exclusion__c> byDirect = new List<Exl_Exclusion__c>();
            Schema.DescribeSObjectResult d = Exl_Exclusion__c.SObjectType.getDescribe();
            if (d.fields.getMap().containsKey('Contact__c')) {
                byDirect = [
                    SELECT Id, Name, POE_Type__c, Origin__c, CreatedDate
                    FROM Exl_Exclusion__c
                    WHERE Contact__c = :i.contactId
                    ORDER BY CreatedDate DESC
                    LIMIT 2000
                ];
                // Add AND Status__c = 'Active' here too if needed
            }

            // --- Union results while preserving order (byCase first, then byDirect), no duplicates ---
            Set<Id> seen = new Set<Id>();
            List<Exl_Exclusion__c> ordered = new List<Exl_Exclusion__c>();
            for (Exl_Exclusion__c e : byCase) {
                if (seen.add(e.Id)) ordered.add(e);
            }
            for (Exl_Exclusion__c e : byDirect) {
                if (seen.add(e.Id)) ordered.add(e);
            }
            if (ordered.isEmpty()) continue;

            // --- Build one choice per exclusion ---
            for (Exl_Exclusion__c e : ordered) {
                String label = safe(e.Name) + ' - "' + safe(e.POE_Type__c) + '" - ' + safe(e.Origin__c);
                String value = String.valueOf(e.Id);

                // Append to the fixed-size array out.entries
                ExlExclusionChoiceItem[] cur = out.entries;
                ExlExclusionChoiceItem[] nextArr = new ExlExclusionChoiceItem[cur.size() + 1];
                for (Integer k = 0; k < cur.size(); k++) nextArr[k] = cur[k];
                nextArr[cur.size()] = new ExlExclusionChoiceItem(label, value);
                out.entries = nextArr;
            }
        }
        return results;
    }

    // Null/blank-safe formatter
    private static String safe(Object o) {
        String s = (o == null) ? '-' : String.valueOf(o).trim();
        return (s == '') ? '-' : s;
    }
}