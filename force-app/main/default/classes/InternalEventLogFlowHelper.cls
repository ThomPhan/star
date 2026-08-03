public without sharing class InternalEventLogFlowHelper {
    public class FlowInputWrapper {
        @InvocableVariable(required = true)
        public List<Exl_Exclusion__c> exclusionRecordsForUpdate;
    }

    public class FlowOutputWrapper {
        @InvocableVariable
        public List<Exl_Exclusion__c> uniqueExclusionRecords;

        @InvocableVariable
        public String Error;
    }

    @InvocableMethod(
        label='Get Unique Exclusions'
        description='Returns records deduplicated by Id. Records without Id are returned as-is.'
    )
    public static List<FlowOutputWrapper> getCleanExclusionsList(List<FlowInputWrapper> inputs) {
        List<FlowOutputWrapper> results = new List<FlowOutputWrapper>();

        // If Flow passed nothing, still return one empty output (Flow safe)
        if (inputs == null || inputs.isEmpty()) {
            FlowOutputWrapper emptyOut = new FlowOutputWrapper();
            emptyOut.uniqueExclusionRecords = new List<Exl_Exclusion__c>(0);
            emptyOut.Error = null;
            results.add(emptyOut);
            return results;
        }

        for (FlowInputWrapper inWrap : inputs) {
            FlowOutputWrapper out = new FlowOutputWrapper();
            out.uniqueExclusionRecords = new List<Exl_Exclusion__c>();
            out.Error = null;

            try {
                List<Exl_Exclusion__c> incoming = (inWrap == null) ? null : inWrap.exclusionRecordsForUpdate;
                if (incoming == null || incoming.isEmpty()) {
                    results.add(out);
                    continue;
                }

                // Pre-size for fewer heap reallocations
                out.uniqueExclusionRecords = new List<Exl_Exclusion__c>(incoming.size());

                // Track first-seen Ids → stable, O(1) dedupe
                Set<Id> seenIds = new Set<Id>();

                for (Integer i = 0, n = incoming.size(); i < n; i++) {
                    Exl_Exclusion__c rec = incoming[i];
                    if (rec == null) continue;

                    Id rid = rec.Id;
                    if (rid != null) {
                        if (seenIds.contains(rid)){
                            continue; // duplicate by Id
                        }
                        seenIds.add(rid);
                        out.uniqueExclusionRecords.add(rec);
                    }
                }
            } catch (Exception e) {
                out.Error = 'Error while deduplicating Exl_Exclusion__c records: ' + e.getMessage();
            }
            results.add(out);
        }

        return results;
    }
}