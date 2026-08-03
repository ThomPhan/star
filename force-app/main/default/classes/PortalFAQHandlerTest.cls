@isTest
public class PortalFAQHandlerTest {
	@isTest static void testPostCallout() {
      Test.setMock(HttpCalloutMock.class, new HttpCallout()); 
	String response = PortalFAQHandler.getFAQDetails();
        System.assertEquals('{"access_token":"243-sd3hh","id":"014drr45hd738","status":"Succeeded"}', response,'Response not received');
    }
}