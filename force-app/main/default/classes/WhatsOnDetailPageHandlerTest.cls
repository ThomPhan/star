@isTest
public class WhatsOnDetailPageHandlerTest{
	@isTest static void testPostCallout() {
      Test.setMock(HttpCalloutMock.class, new HttpCallout()); 
	String response = WhatsOnDetailPageHandler.getEvents();
        String response1 = WhatsOnDetailPageHandler.getEventDetailsOnClick();
        System.assertEquals('{"access_token":"243-sd3hh","id":"014drr45hd738","status":"Succeeded"}', response,'Response not received');
    }
    @isTest static void getEventDetailsOnClickTest() {
      Test.setMock(HttpCalloutMock.class, new HttpCallout()); 
	String response1 = WhatsOnDetailPageHandler.getEventDetailsOnClick();
        System.assertEquals('{"access_token":"243-sd3hh","id":"014drr45hd738","status":"Succeeded"}', response1,'Response not received');
    }
}