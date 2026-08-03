@IsTest
public class PortalFooterControllerTest {
	@IsTest
    static void getFooterMessagesTest(){
        Portal_Footer_Message__mdt pfm = new Portal_Footer_Message__mdt();
        pfm.MasterLabel = 'test';
        pfm.DeveloperName = 'test';
        pfm.Location__c = 'Sydney';
        PortalFooterController.getFooterMessages('Sydney');
        Portal_Footer_Message__mdt message = [Select Id,Location__c,Address__c,Legal_Statement__c from Portal_Footer_Message__mdt where Location__c ='Sydney' LIMIT 1];
        PortalFooterController.getFooterLinks('Sydney');
        System.assertEquals('Sydney', message.Location__c, 'No record is Present');
    }
}