/* Description: Service class for Service__c object
 * Author: Simplus
 * Created: 31/5/22
 * History:
 * 31/05		Created
 */
public class ServiceService {
    
    public static void onBeforeInsert(List<Service__c> newServiceList){
		//updatePreference(newServiceList);
    }
    
    public static void updatePreference(List<Service__c> newServiceList){
        Id limoRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByName().get('Limo Service Booking').getRecordTypeId();
        Id restoRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByName().get('Restaurant Booking').getRecordTypeId();
        Set<Id> contactIdSet = new Set<Id>();
		Set<Id> vipBookingIdSet = new Set<Id>();
        List<Service__c> updateServiceList = new List<Service__c>();
        Map<Id, Id> vipBookingContactIdMap = new Map<Id, Id>();
        Map<Id, Preferences__c> contactPreferencesMap = new Map<Id, Preferences__c>();
        
        try{
            for(Service__c serviceObj : newServiceList){//loop through trigger.new
                vipBookingIdSet.add(serviceObj.VIP_Booking__c);//save booking ID to get the contact
                contactIdSet.add(serviceObj.Contact__c);
            }
            for(Preferences__c prefObj : [SELECT Id, Transportation_Notes__c, Dining_Notes__c, Dietary__c, Patron__c FROM Preferences__c WHERE Patron__c IN : contactIdSet]){
                //get child preference record of the VIP Booking's contact
                contactPreferencesMap.put(prefObj.Patron__c, prefObj);//save the transpo note. used a map to pair the appropriate values
            }
            for(Service__c serviceObj : newServiceList){//loop through trigger.new again to populate the field
                if(serviceObj.RecordTypeId == limoRTId){//if Record Type is Limo, populate Car Type Preference
                    serviceObj.Preferences__c = contactPreferencesMap.get(serviceObj.Contact__c).Transportation_Notes__c;
                }
                if(serviceObj.RecordTypeId == restoRTId){//if Record Type is Resto, populate Dining Notes and Dietary Reqts
                    serviceObj.Dining_Notes__c = contactPreferencesMap.get(serviceObj.Contact__c).Dining_Notes__c;
                    serviceObj.Dietary_Requirements__c = contactPreferencesMap.get(serviceObj.Contact__c).Dietary__c;
                }
                updateServiceList.add(serviceObj);
            }
            
            if(!updateServiceList.isEmpty()){
                Database.update(updateServiceList, TRUE);
            }

        }catch(Exception excp){
            System.debug('@@@Error: ' + excp.getMessage());
            System.debug('@@@Error: ' + excp.getStackTraceString());
        }
    }
}