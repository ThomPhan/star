public class TripService extends TriggerHandlerBase { //extending the trigger framework
    private static final String NSWSTRING = 'NSW';
    private static final String QLDSTRING = 'QLD';
    
    private static final String CANCELLEDSTRING = 'Cancelled';
    private static final String APPROVEDSTRING = 'Approved';
    private static final String REJECTEDSTRING = 'Rejected';
    
    private static final String DUPERRORMSG = 'Duplicate or overlap trip with the same entry state and entry date';
    private static final String CANCELLEDVALIDATION = 'Trip cannot be cancelled if there is at least 1 Approved or Rejected Residency Checklist';
    
    static final String APEXCLASSNAME = 'TripService';
    static final String COMPONENTTYPE = 'Apex Class';

    //new method which is required when we extend the TriggerHandlerBase class
    public TripService(String triggerName) {
      super(triggerName);
    }
    
    public override void beforeInsert(List<SObject> newTripList){
        checkIfWithin365DaysInsert((List<Trip__c>)newTripList);
        validateDuplicateTripRecord((List<Trip__c>)newTripList);
    }
    
    public override void beforeUpdate(List<SObject> oldTripList, List<SObject> newTripList, Map<ID, SObject> oldTripMap, Map<ID, SObject> newTripMap){
        checkIfWithin365DaysUpdate((List<Trip__c>)newTripList, (List<Trip__c>)oldTripList);
        validateDuplicateTripRecordUpdate((List<Trip__c>)newTripList, (List<Trip__c>)oldTripList);
    }
    
    public override void afterInsert(List<SObject> newTripList, Map<ID, SObject> newTripMap){
        countTripDurationInsert((List<Trip__c>)newTripList);
    }
    
    public override void afterUpdate(List<SObject> oldTripList, List<SObject> newTripList, Map<ID, SObject> oldTripMap, Map<ID, SObject> newTripMap){
        countTripDurationUpdate((List<Trip__c>)newTripList, (List<Trip__c>)oldTripList);
    }
    
    public override void afterDelete(List<SObject> oldTripList, Map<ID, SObject> oldTripMap){
        countTripDurationInsert((List<Trip__c>)oldTripList);
    }
    
    public static void countTripDurationInsert(List<Trip__c> newTripList){
        Set<Id> contactId = new Set<Id>();
        Integer daysToBeSubtracted=0;
        List<Contact> updateContactList = new List<Contact>();
        List<Trip__c> filteredTripList = new List<Trip__c>();
        List<String> entryDatesNSW = new List<String>();
        List<String> entryDatesQLD = new List<String>();
        List<String> exitDatesNSW = new List<String>();
        List<String> exitDatesQLD = new List<String>();
        Map<Id, Integer> contactDaysMap = new Map<Id, Integer>();
        
        try{
            for(Trip__c tripObj : newTripList){
                if(!tripObj.Cancelled__c){
                    contactId.add(tripObj.Contact__c);
                }
            }
            
            for(Trip__c tripObj : [SELECT Id, Name, Entry_State__c, Entry_Date__c, Exit_Date__c, Contact__c, Cancelled__c 
                                   FROM Trip__c 
                                   WHERE Contact__c IN : contactId 
                                   AND Cancelled__c = FALSE
                                   AND is_Within_365_Days__c = TRUE
                                   ORDER BY Entry_Date__c]){
                                       
                                       filteredTripList.add(tripObj);
                                       if(NSWSTRING.equalsIgnoreCase(tripObj.Entry_State__c)){
                                           entryDatesNSW.add(String.valueOf(tripObj.Contact__c) + String.valueOf(tripObj.Entry_Date__c));
                                           exitDatesNSW.add(String.valueOf(tripObj.Contact__c) + String.valueOf(tripObj.Exit_Date__c));
                                       }else if(QLDSTRING.equalsIgnoreCase(tripObj.Entry_State__c)){
                                           entryDatesQLD.add(String.valueOf(tripObj.Contact__c) + String.valueOf(tripObj.Entry_Date__c));
                                           exitDatesQLD.add(String.valueOf(tripObj.Contact__c) + String.valueOf(tripObj.Exit_Date__c));
                                       }
                                   }
            
            for(Trip__c existingTrips : filteredTripList){
                if(NSWSTRING.equalsIgnoreCase(existingTrips.Entry_State__c)){
                    if(exitDatesQLD.contains(String.valueOf(existingTrips.Contact__c) + String.valueOf(existingTrips.Entry_Date__c))
                       || entryDatesQLD.contains(String.valueOf(existingTrips.Contact__c) + String.valueOf(existingTrips.Exit_Date__c))){
                           daysToBeSubtracted = daysToBeSubtracted+1;
                       }
                }else if(QLDSTRING.equalsIgnoreCase(existingTrips.Entry_State__c)){
                    if(exitDatesNSW.contains(String.valueOf(existingTrips.Contact__c) + String.valueOf(existingTrips.Entry_Date__c)) 
                       || entryDatesNSW.contains(String.valueOf(existingTrips.Contact__c) + String.valueOf(existingTrips.Exit_Date__c))){
                           daysToBeSubtracted = daysToBeSubtracted+1;
                       }
                }
                contactDaysMap.put(existingTrips.Contact__c,daysToBeSubtracted/2);
            }
            
            for(Contact contactObj : [SELECT Id, Overlapping_Days__c FROM Contact WHERE Id IN : contactDaysMap.keySet()]){
                contactObj.Overlapping_Days__c = contactDaysMap.get(contactObj.Id);
                updateContactList.add(contactObj);
            }
            
            if(!updateContactList.isEmpty()){
                Database.update(updateContactList, TRUE);
            }
        }catch(Exception e){
            ErrorLogger.createLog('TripService','countTripDurationInsert',e,'','Apex Class'); 
        }
    }
    
    public static void countTripDurationUpdate(List<Trip__c> newTripList, List<Trip__c> oldTripList){
        Trip__c oldTripRecord = new Trip__c();
        List<Trip__c> tripListToUpdate = new List<Trip__c>();
        Map<Id, Trip__c> oldTripMap = new Map<Id, Trip__c>();
        
        try{
            for(Trip__c oldTripObj : oldTripList){
                oldTripMap.put(oldTripObj.Id, oldTripObj);
            }
            
            for(Trip__c newTripObj : newTripList){
                oldTripRecord = oldTripMap.containsKey(newTripObj.Id) ? oldTripMap.get(newTripObj.Id) : new Trip__c();
                if(newTripObj.Entry_Date__c != oldTripRecord.Entry_Date__c || newTripObj.Exit_Date__c != oldTripRecord.Exit_Date__c){
                    tripListToUpdate.add(newTripObj);
                }
            }
            
            if(!tripListToUpdate.isEmpty()){
                countTripDurationInsert(tripListToUpdate);
            }
        }catch(Exception e){
            ErrorLogger.createLog('TripService','countTripDurationUpdate',e,'','Apex Class'); 
        }
    }
    
    public static void checkIfWithin365DaysInsert(List<Trip__c> newTripList){
        List<Trip__c> tripListToUpdate = new List<Trip__c>();
        Date dateToday = Date.today();
        Integer tripDuration;
        
        try{
            for(Trip__c tripObj : newTripList){
                tripDuration = tripObj.Entry_Date__c.daysBetween(dateToday);
                if(tripDuration>365){
                    tripObj.is_within_365_days__c = FALSE;                    
                }else{
                    tripObj.is_within_365_days__c = TRUE;
                }
                
                tripListToUpdate.add(tripObj);
            }
            
            if(!tripListToUpdate.isEmpty()){
                Database.update(tripListToUpdate, true);
            }
        }catch(Exception e){
            ErrorLogger.createLog('TripService','checkIfWithin365Days',e,'','Apex Class'); 
        }
    }
    
    public static void checkIfWithin365DaysUpdate(List<Trip__c> newTripList, List<Trip__c> oldTripList){
        Trip__c oldTripRecord = new Trip__c();
        List<Trip__c> tripListToUpdate = new List<Trip__c>();
        Map<Id, Trip__c> oldTripMap = new Map<Id, Trip__c>();
        
        try{
            for(Trip__c oldTripObj : oldTripList){
                oldTripMap.put(oldTripObj.Id, oldTripObj);
            }
            
            for(Trip__c newTripObj : newTripList){
                oldTripRecord = oldTripMap.containsKey(newTripObj.Id) ? oldTripMap.get(newTripObj.Id) : new Trip__c();
                if(newTripObj.Entry_Date__c != oldTripRecord.Entry_Date__c){
                    tripListToUpdate.add(newTripObj);
                }
            }
            
            if(!tripListToUpdate.isEmpty()){
                countTripDurationInsert(tripListToUpdate);
            }
        }catch(Exception e){
            ErrorLogger.createLog('TripService','checkIfWithin365DaysUpdate',e,'','Apex Class'); 
        }
    }
    
    public static void validateDuplicateTripRecord(List<Trip__c> newTripList){
        Set<Id> contactIdSet = new Set<Id>();
        Set<String> existingTripsSet = new Set<String>();

        try{
            for(Trip__c tripObj : newTripList){
                contactIdSet.add(tripObj.Contact__c);
            }
            for(Trip__c tripBuff : [SELECT Id, Contact__c, Entry_Date__c, Entry_State__c FROM Trip__c WHERE Contact__c IN : contactIdSet]){
                existingTripsSet.add(tripBuff.Contact__c + tripBuff.Entry_State__c + tripBuff.Entry_Date__c);
            }

            for(Trip__c newTrips : newTripList){
                if(existingTripsSet.contains(newTrips.Contact__c + newTrips.Entry_State__c + newTrips.Entry_Date__c)){
                    newTrips.addError(DUPERRORMSG);
                }
            }

        }catch(Exception e){
            ErrorLogger.createLog('TripService','validateDuplicateTripRecord',e,'','Apex Class'); 
        }
    }
    
    public static void validateDuplicateTripRecordUpdate(List<Trip__c> newTripList, List<Trip__c> oldTripList){
        Trip__c oldTrip = new Trip__c();
        Set<Id> contactIdSet = new Set<Id>();
        Set<String> existingTripsSet = new Set<String>();
        Map<Id, Trip__c> oldTripMap = new Map<Id, Trip__c>();

        try{
            for(Trip__c oldTripRec : oldTripList){
                oldTripMap.put(oldTripRec.Id, oldTripRec);
            }
            
            for(Trip__c tripObj : newTripList){
                oldTrip = oldTripMap.containsKey(tripObj.Id) ? oldTripMap.get(tripObj.Id) : new Trip__c();
                if(tripObj.Contact__c != oldTrip.Contact__c || tripObj.Entry_Date__c != oldTrip.Entry_Date__c || tripObj.Entry_State__c != oldTrip.Entry_State__c){
                    contactIdSet.add(tripObj.Contact__c);
                } 
            }
            
            for(Trip__c tripBuff : [SELECT Id, Entry_Date__c, Contact__c, Entry_State__c FROM Trip__c WHERE Contact__c IN : contactIdSet]){
                existingTripsSet.add(tripBuff.Contact__c + tripBuff.Entry_State__c + tripBuff.Entry_Date__c);
            }
            
            for(Trip__c newTrips : newTripList){
                if(existingTripsSet.contains(newTrips.Contact__c + newTrips.Entry_State__c + newTrips.Entry_Date__c)){
                    newTrips.addError(DUPERRORMSG);
                }
            }

        }catch(Exception e){
            ErrorLogger.createLog('TripService','validateDuplicateTripRecordUpdate',e,'','Apex Class'); 
        }
    }
}