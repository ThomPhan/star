// GetExclusionGroupChoicesAction.cls
public with sharing class GetExclusionGroupChoicesAction {

    // === Flow I/O DTOs (same as your working pattern) ===
    public class Input {
        @InvocableVariable public Id contactId;
        @InvocableVariable public Integer maxItemsInLabel; // optional; default 5
    }
    public class Output {
        // Mapped by Flow to an Apex-Defined collection variable of type ExlExclusionChoiceItem
        @InvocableVariable public ExlExclusionChoiceItem[] entries = new ExlExclusionChoiceItem[0];
    }

    @InvocableMethod(
        label='Get Exclusion Group Choices'
        description='Returns picklist-ready label/value pairs (one radio option per Case-group) for the given Contact.'
    )
    public static List<Output> getChoices(List<Input> inputs) {
        List<Output> results = new List<Output>();
        if (inputs == null || inputs.isEmpty()) return results;

        for (Input i : inputs) {
            Output out = new Output();
            results.add(out); // always return one Output, even if empty

            if (i == null || i.contactId == null) continue;
            Integer maxItems = (i.maxItemsInLabel == null || i.maxItemsInLabel <= 0) ? 5 : i.maxItemsInLabel;

            // 1) Collect this Contact's Case Ids (the path you had when it worked)
            Set<Id> caseIds = new Set<Id>();
            for (Case c : [
                SELECT Id
                FROM Case
                WHERE ContactId = :i.contactId
                LIMIT 50000
            ]) {
                caseIds.add(c.Id);
            }

            // 2) Query exclusions under those Cases
            List<Exl_Exclusion__c> exs = new List<Exl_Exclusion__c>();
            if (!caseIds.isEmpty()) {
                exs = [
                    SELECT Id, Name, POE_Type__c, Origin__c, ApplyCase__c
                    FROM Exl_Exclusion__c
                    WHERE ApplyCase__c IN :caseIds
                    ORDER BY ApplyCase__c, CreatedDate DESC
                    LIMIT 2000
                ];
                // Add AND Status__c = 'Active' here if you have it
            }

            // 2b) Minimal fallback: if nothing yet, try direct relationship
            if (exs.isEmpty()) {
                exs = [
                    SELECT Id, Name, POE_Type__c, Origin__c, ApplyCase__c
                    FROM Exl_Exclusion__c
                    WHERE RevokeCase__r.ContactId = :i.contactId
                    ORDER BY ApplyCase__c, CreatedDate DESC
                    LIMIT 2000
                ];
                // Add AND Status__c = 'Active' here too if needed
            }

            if (exs.isEmpty()) continue;

            // 3) Group by ApplyCase__c
            Map<Id, List<Exl_Exclusion__c>> byCase = new Map<Id, List<Exl_Exclusion__c>>();
            for (Exl_Exclusion__c e : exs) {
                if (e.ApplyCase__c == null) continue;
                List<Exl_Exclusion__c> bucket = byCase.get(e.ApplyCase__c);
                if (bucket == null) {
                    bucket = new List<Exl_Exclusion__c>();
                    byCase.put(e.ApplyCase__c, bucket);
                }
                bucket.add(e);
            }
            if (byCase.isEmpty()) continue;

            // 4) Deterministic order of groups
            List<Id> groupIds = new List<Id>(byCase.keySet());
            groupIds.sort();

            // 5) Build label/value per group — ONLY THE FORMAT CHANGED
            for (Id caseId : groupIds) {
                List<Exl_Exclusion__c> items = byCase.get(caseId);

                List<String> parts = new List<String>();
                Integer count = 0;
                for (Exl_Exclusion__c e : items) {
                    if (count >= maxItems) break;
                    parts.add(
                        safe(e.Name) + ' - "' + safe(e.POE_Type__c) + '" - ' + safe(e.Origin__c)
                    );
                    count++;
                }

                String label = String.join(parts, ' |  ');
                if (items.size() > maxItems) {
                    label += '  +' + String.valueOf(items.size() - maxItems) + ' more…';
                }

                // Value = Case Id (group selection)
                out.entries.add(new ExlExclusionChoiceItem(label, String.valueOf(caseId)));
            }
        }
        return results;
    }

    // Null/blank-safe helper for label parts
    private static String safe(Object o) {
        String s = (o == null) ? '-' : String.valueOf(o).trim();
        return (s == '') ? '-' : s;
    }
}