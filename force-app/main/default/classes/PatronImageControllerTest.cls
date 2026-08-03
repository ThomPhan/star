@isTest
private class PatronImageControllerTest {

    private class Mock implements HttpCalloutMock {
        Integer code;
        String body;
        Mock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @isTest
    static void imageReturned() {
        Contact c = new Contact(LastName = 'PatronImg', Patron_ID__c = '543517');
        insert c;
        String body = '{"patronId":"543517","imageType":"Photograph","imageBase64Content":"/9j/ABCD"}';
        Test.setMock(HttpCalloutMock.class, new Mock(200, body));

        Test.startTest();
        PatronImageController.PatronImage r = PatronImageController.getPatronImage(c.Id, 'Photograph');
        Test.stopTest();

        System.assertEquals('543517', r.patronId, 'Patron id should be returned');
        System.assertEquals('/9j/ABCD', r.imageBase64, 'Base64 image should be returned');
    }

    @isTest
    static void nullContact() {
        PatronImageController.PatronImage r = PatronImageController.getPatronImage(null, null);
        System.assertEquals(null, r.patronId);
        System.assertEquals(null, r.imageBase64);
    }

    @isTest
    static void noPatronIdOnContact() {
        Contact c = new Contact(LastName = 'NoPatron');
        insert c;
        PatronImageController.PatronImage r = PatronImageController.getPatronImage(c.Id, null);
        System.assertEquals(null, r.patronId, 'No patron id -> null');
        System.assertEquals(null, r.imageBase64);
    }

    @isTest
    static void imageNotFound404() {
        Contact c = new Contact(LastName = 'PatronImg', Patron_ID__c = '999001');
        insert c;
        Test.setMock(HttpCalloutMock.class,
            new Mock(404, '{"statusCode":"APIG.404","statusMessage":"Patron Image Not Found"}'));

        Test.startTest();
        PatronImageController.PatronImage r = PatronImageController.getPatronImage(c.Id, 'Photograph');
        Test.stopTest();

        System.assertEquals('999001', r.patronId, 'Patron id still returned on 404');
        System.assertEquals(null, r.imageBase64, '404 -> no image');
    }

    @isTest
    static void serverErrorThrows() {
        Contact c = new Contact(LastName = 'PatronImg', Patron_ID__c = '999002');
        insert c;
        Test.setMock(HttpCalloutMock.class, new Mock(500, '{"error":"boom"}'));

        Test.startTest();
        Boolean threw = false;
        try {
            PatronImageController.getPatronImage(c.Id, 'Photograph');
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Non-200/404 status should throw');
    }
}