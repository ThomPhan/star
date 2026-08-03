public with sharing class PlatformEventSwitch {

    // Cache per transaction
    @testVisible
    private static Map<String, PlatformEvent_Switch__mdt> byApiName;

    @testVisible
    private static Map<String, PlatformEvent_Switch__mdt> getMap() {
        if (byApiName == null) {
            byApiName = new Map<String, PlatformEvent_Switch__mdt>();
            for (PlatformEvent_Switch__mdt s :
                [SELECT PlatformEventApiName__c, IsDisabled__c, Disabled_Until__c
                 FROM PlatformEvent_Switch__mdt]
            ) {
                if (String.isNotBlank(s.PlatformEventApiName__c)) {
                    byApiName.put(s.PlatformEventApiName__c.trim(), s);
                }
            }
        }
        return byApiName;
    }

    // Core logic (reusable from Apex)
    public static Boolean isPublishBlocked(String platformEventApiName) {
        if (String.isBlank(platformEventApiName)) return false;

        PlatformEvent_Switch__mdt s = getMap().get(platformEventApiName.trim());
        if (s == null) return false; // no record => allow publish

        // blocked if explicitly disabled
        if (s.IsDisabled__c) return true;

        // blocked if DisabledUntil is in the future
        if (s.Disabled_Until__c != null && s.Disabled_Until__c > System.now()) return true;

        return false;
    }

    // ==== FLOW ENTRYPOINT ====
    public class FlowRequest {
        @InvocableVariable(required=true)
        public String platformEventApiName;
    }

    public class FlowResponse {
        @InvocableVariable
        public Boolean isBlocked;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Check Platform Event Publish Switch'
                     description='Returns whether publishing for a Platform Event is blocked by custom metadata.')
    public static List<FlowResponse> checkPublishBlocked(List<FlowRequest> requests) {
        List<FlowResponse> res = new List<FlowResponse>();

        for (FlowRequest r : requests) {
            FlowResponse out = new FlowResponse();
            if (r == null || String.isBlank(r.platformEventApiName)) {
                out.isBlocked = false;
                out.message = 'No Platform Event API name provided. Defaulting to not blocked.';
            } else {
                out.isBlocked = isPublishBlocked(r.platformEventApiName);
                out.message = out.isBlocked
                    ? 'Publishing is blocked by PlatformEvent_Switch__mdt.'
                    : 'Publishing is allowed.';
            }
            res.add(out);
        }
        return res;
    }
}