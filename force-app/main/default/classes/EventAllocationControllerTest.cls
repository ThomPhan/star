/**
 * Class Name  : EventAllocationControllerTest
 * Summary     : Controller class for 'EventAllocationControllerTest' aura component 
 * Methods     : testGetCampaignDetails
                 testSaveEventAllocationTest
 * @author       Fritz Gerald Moran
   @Description: This class tests the fetches the list of campaigns and saves the event allocation

 * @version      $Revision: 1.0 $, $Date: 5/Aug/2020 
 */

/*parent class that holds the methods for testing the apex controller of EventAllocationControllerTest*/
@isTest
public class EventAllocationControllerTest {

    /*test for fetching the campaign details from the record page*/
    @isTest
    static void testGetCampaignDetails() {
        List<Campaign> cmpList = new List<Campaign>();
        Campaign campaignRec = new Campaign();
        campaignRec.Name = 'Campaign Rec';
        campaignRec.Status = 'Active';
        campaignRec.StartDate = system.today();
        campaignRec.EndDate = system.today()+3;
        
        insert campaignRec;
        
        Test.startTest();
        try {
            cmpList = EventAllocationController.getCampaignDetails(campaignRec.Id);
        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }
        Test.stopTest();
        
        system.assert(!cmpList.isEmpty());
    }
    
    /*test for creating event allocation*/
    @isTest
    static void testSaveEventAllocationTest() {
        String result = '';
        
        Campaign campaignRec = new Campaign();
        campaignRec.Name = 'Campaign Rec';
        campaignRec.Status = 'Active';
        campaignRec.StartDate = system.today();
        campaignRec.EndDate = system.today()+3;
        
        insert campaignRec;
        
        Allocation__c allocRec = new Allocation__c();
        allocRec.Name = 'Domestic';
        
        insert allocRec;
        
		String json = '[{\"Id\":0,\"Allocation\":\"Domestic\",\"Capacity\":\"1\",\"Budget\":\"1.11\",\"Host_Allocated\":\"1\",\"Cost\":\"11.11\",\"Actual\":\"1.12\"}]';
        
        Test.startTest();
        try {
            result = EventAllocationController.saveEventAllocation(json, campaignRec.Id);
        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }
        Test.stopTest();
		
        system.assert(result != NULL);
        
    }
}