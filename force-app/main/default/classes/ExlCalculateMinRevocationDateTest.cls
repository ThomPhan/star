@isTest
public class ExlCalculateMinRevocationDateTest {

    @isTest
    static void testCalculate_NSW_FallbackWhenNoBH() {
        List<ExlCalculateMinRevocationDate.Request> requests = new List<ExlCalculateMinRevocationDate.Request>();
        ExlCalculateMinRevocationDate.Request req = new ExlCalculateMinRevocationDate.Request();
        req.startDate = Date.today();
        req.jurisdiction = 'NSW';
        requests.add(req);

        Test.startTest();
        List<ExlCalculateMinRevocationDate.Response> responses = ExlCalculateMinRevocationDate.calculate(requests);
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Response list should not be null');
        System.assertEquals(1, responses.size(), 'Should return exactly one response');
        System.assertNotEquals(null, responses[0].minRevocationDate, 'Min revocation date should not be null');
        System.assert(responses[0].minRevocationDate > Date.today(), 'Min revocation date must be in the future');
    }

    @isTest
    static void testCalculate_QLD_FallbackWhenNoBH() {
        List<ExlCalculateMinRevocationDate.Request> requests = new List<ExlCalculateMinRevocationDate.Request>();
        ExlCalculateMinRevocationDate.Request req = new ExlCalculateMinRevocationDate.Request();
        req.startDate = Date.today().addDays(-40);
        req.jurisdiction = 'QLD';
        requests.add(req);

        Test.startTest();
        List<ExlCalculateMinRevocationDate.Response> responses = ExlCalculateMinRevocationDate.calculate(requests);
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Response list should not be null');
        System.assertEquals(1, responses.size(), 'Should return exactly one response');
        System.assert(responses[0].minRevocationDate > Date.today().addDays(-40), 'Min revocation date must be after start date');
    }

    @isTest
    static void testCalculate_WithBusinessHours() {
        // Use the default org Business Hours if available
        List<BusinessHours> defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        if (defaultBH.isEmpty()) {
            return; // Skip if no default BH in test org
        }

        // We can't rename existing BH, so test by verifying the fallback path still produces a date
        List<ExlCalculateMinRevocationDate.Request> requests = new List<ExlCalculateMinRevocationDate.Request>();
        ExlCalculateMinRevocationDate.Request req = new ExlCalculateMinRevocationDate.Request();
        req.startDate = Date.today().addDays(-60);
        req.jurisdiction = 'NSW';
        requests.add(req);

        Test.startTest();
        List<ExlCalculateMinRevocationDate.Response> responses = ExlCalculateMinRevocationDate.calculate(requests);
        Test.stopTest();

        System.assertNotEquals(null, responses[0].minRevocationDate, 'Should always return a date');
        System.assert(responses[0].minRevocationDate > req.startDate, 'Min date must be after start date');
    }

    @isTest
    static void testCalculate_NullStartDate_HitsCatchBlock() {
        // null startDate causes NPE inside the BH-not-found branch, exercising the catch block
        ExlCalculateMinRevocationDate.Request req = new ExlCalculateMinRevocationDate.Request();
        req.startDate = null;
        req.jurisdiction = 'NSW';

        Test.startTest();
        List<ExlCalculateMinRevocationDate.Response> responses =
            ExlCalculateMinRevocationDate.calculate(new List<ExlCalculateMinRevocationDate.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response even on exception');
        System.assertNotEquals(null, responses[0].minRevocationDate, 'Catch block fallback should provide a date');
        System.assertNotEquals(null, responses[0].errorMessage, 'Catch block should set an error message');
    }

    @isTest
    static void testCalculate_MultipleRequests() {
        List<ExlCalculateMinRevocationDate.Request> requests = new List<ExlCalculateMinRevocationDate.Request>();

        ExlCalculateMinRevocationDate.Request req1 = new ExlCalculateMinRevocationDate.Request();
        req1.startDate = Date.today().addDays(-50);
        req1.jurisdiction = 'NSW';
        requests.add(req1);

        ExlCalculateMinRevocationDate.Request req2 = new ExlCalculateMinRevocationDate.Request();
        req2.startDate = Date.today().addDays(-30);
        req2.jurisdiction = 'QLD';
        requests.add(req2);

        Test.startTest();
        List<ExlCalculateMinRevocationDate.Response> responses = ExlCalculateMinRevocationDate.calculate(requests);
        Test.stopTest();

        System.assertEquals(2, responses.size(), 'Should return two responses');
        System.assertNotEquals(null, responses[0].minRevocationDate);
        System.assertNotEquals(null, responses[1].minRevocationDate);
    }
}