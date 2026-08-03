@IsTest
private class PlatformEventSwitchTest {
    private static PlatformEvent_Switch__mdt mdtRec(
        String apiName,
        Boolean isDisabled,
        Datetime disabledUntil
    ) {
        PlatformEvent_Switch__mdt r = new PlatformEvent_Switch__mdt();
        r.PlatformEventApiName__c = apiName;
        r.IsDisabled__c = isDisabled;
        r.Disabled_Until__c = disabledUntil;
        return r;
    }

    private static void setCache(Map<String, PlatformEvent_Switch__mdt> data) {
        PlatformEventSwitch.byApiName = data;
    }

    @IsTest
    static void test_noRecord_defaultsToNotBlocked() {
        setCache(new Map<String, PlatformEvent_Switch__mdt>());

        System.assertEquals(false, PlatformEventSwitch.isPublishBlocked('External_Event_Log__e'),
            'If no metadata record exists, publishing should be allowed (not blocked).');
    }

    @IsTest
    static void test_isDisabled_true_blocks() {
        Map<String, PlatformEvent_Switch__mdt> m = new Map<String, PlatformEvent_Switch__mdt>();
        m.put('External_Event_Log__e', mdtRec('External_Event_Log__e', true, null));
        setCache(m);

        System.assertEquals(true, PlatformEventSwitch.isPublishBlocked('External_Event_Log__e'),
            'IsDisabled__c=true must block publishing.');
    }

    @IsTest
    static void test_disabledUntil_future_blocks() {
        Datetime futureTime = System.now().addHours(2);

        Map<String, PlatformEvent_Switch__mdt> m = new Map<String, PlatformEvent_Switch__mdt>();
        m.put('External_Event_Log__e', mdtRec('External_Event_Log__e', false, futureTime));
        setCache(m);

        System.assertEquals(true, PlatformEventSwitch.isPublishBlocked('External_Event_Log__e'),
            'Disabled_Until__c in the future must block publishing.');
    }

    @IsTest
    static void test_disabledUntil_past_allows() {
        Datetime pastTime = System.now().addHours(-2);

        Map<String, PlatformEvent_Switch__mdt> m = new Map<String, PlatformEvent_Switch__mdt>();
        m.put('External_Event_Log__e', mdtRec('External_Event_Log__e', false, pastTime));
        setCache(m);

        System.assertEquals(false, PlatformEventSwitch.isPublishBlocked('External_Event_Log__e'),
            'After Disabled_Until__c has passed, it should behave as not disabled (allowed).');
    }

    @IsTest
    static void test_flow_invocable_returns_expected() {
        Map<String, PlatformEvent_Switch__mdt> m = new Map<String, PlatformEvent_Switch__mdt>();
        m.put('Event_A_e', mdtRec('Event_A_e', true, null)); // blocked
        m.put('Event_B_e', mdtRec('Event_B_e', false, System.now().addMinutes(30))); // blocked
        m.put('Event_C_e', mdtRec('Event_C_e', false, System.now().addMinutes(-30))); // allowed
        setCache(m);

        List<PlatformEventSwitch.FlowRequest> reqs = new List<PlatformEventSwitch.FlowRequest>();

        PlatformEventSwitch.FlowRequest r1 = new PlatformEventSwitch.FlowRequest();
        r1.platformEventApiName = 'Event_A__e';
        reqs.add(r1);

        PlatformEventSwitch.FlowRequest r2 = new PlatformEventSwitch.FlowRequest();
        r2.platformEventApiName = 'Event_C__e';
        reqs.add(r2);

        PlatformEventSwitch.FlowRequest r3 = new PlatformEventSwitch.FlowRequest();
        r3.platformEventApiName = ''; // blank input
        reqs.add(r3);

        Test.startTest();
        List<PlatformEventSwitch.FlowResponse> out = PlatformEventSwitch.checkPublishBlocked(reqs);
        Test.stopTest();

        System.assertEquals(3, out.size(), 'Must return one response per request.');

        System.assertEquals(true, out[0].isBlocked, 'Event_A__e should be blocked.');
        System.assertEquals(false, out[1].isBlocked, 'Event_C__e should be allowed.');
        System.assertEquals(false, out[2].isBlocked, 'Blank name should default to not blocked.');

        System.assert(out[0].message != null && out[0].message.length() > 0, 'Message should be populated.');
    }

    @IsTest
    static void test_trimming_input_works() {
        Map<String, PlatformEvent_Switch__mdt> m = new Map<String, PlatformEvent_Switch__mdt>();
        m.put('External_Event_Log__e', mdtRec('External_Event_Log__e', true, null));
        setCache(m);

        System.assertEquals(true, PlatformEventSwitch.isPublishBlocked('  Order_Update__e  '),
            'Input API name should be trimmed.');
    }
    
    @IsTest
    static void test_GetMap() {
        PlatformEventSwitch.getMap();
    }
}