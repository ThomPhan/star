/**
 * Class Name  : EventAllocationController
 * Summary     : Controller class for 'EventAllocationController' aura component 
 * Methods     : getCampaignDetails
                 saveEventAllocationTest
 * @author       Fritz Gerald Moran
   @Description: This class fetches the list of campaigns and saves the event allocation

 * @version      $Revision: 1.0 $, $Date: 5/Aug/2020 
 */

/*parent class that holds the methods for testing the apex controller of EventAllocationController*/
public with sharing class EventAllocationController {
    
    //Wrapper class for event allocation json
    public class EventAllocationWrapperClass {
        public Integer Id;
        public String Allocation;
        public Integer Capacity;
        public Double Budget;
        public Integer Host_Allocated;
        public Double Cost;
        public Double Actual;
    }
    
    //fetches the campaign details from the record page
    @AuraEnabled
    public static List<Campaign> getCampaignDetails(String recordId) {
        return [SELECT Id, Name, Status, StartDate, EndDate, Type, Host__c FROM Campaign WHERE Id = :recordId];
    } 
    
    //creates event allocation for domestic, international, interstate, local allocations
    @AuraEnabled
    public static String saveEventAllocation(String eventAllocationList, String recordId) {
        List<Event_Allocation__c> eventAllocToAdd = new  List<Event_Allocation__c>();
        List<Allocation__c> allocList = [SELECT Id, Name FROM Allocation__c];
        boolean isSuccess = FALSE;
        
        List<EventAllocationWrapperClass> ObjList = new List<EventAllocationWrapperClass>();
        ObjList = (List<EventAllocationWrapperClass>)System.JSON.deserialize(eventAllocationList, List<EventAllocationWrapperClass>.class);
        
        if(!ObjList.isEmpty() && ObjList != NULL) {
            for(EventAllocationWrapperClass obj: ObjList) {
                for(Allocation__c alloc: allocList) {
                    if(obj.Allocation.equals(alloc.Name)) {
                        eventAllocToAdd.add(new Event_Allocation__c(
                            Allocation__c = alloc.Id,
                            Event__c = recordId,
                            Budget__c = obj.Budget,
                            Cost__c = obj.Cost,
                            Capacity__c = obj.Capacity,
                            Actual__c = obj.Actual
                        ));
                    }   
                }
            }
        }
        
        if(!eventAllocToAdd.isEmpty()) {
            try {
                insert eventAllocToAdd;
                system.debug(eventAllocToAdd);
                system.debug(eventAllocToAdd.isEmpty());
                isSuccess = TRUE;
            } catch(Exception ex) {
                isSuccess = FALSE;
                ErrorLogger.createLog('EventAllocationController', 'saveEventAllocation', ex, recordId, 'Apex Class');
            }
        }
        return isSuccess ? 'SUCCESS': 'ERROR';
    }
}