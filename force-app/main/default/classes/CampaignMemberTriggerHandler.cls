public class CampaignMemberTriggerHandler extends TriggerHandlerBase { //extending the trigger framework
    static final String APEXCLASSNAME = 'CampaignMemberTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';

    //new method which is required when we extend the TriggerHandlerBase class
    public CampaignMemberTriggerHandler (String triggerName) {
      super(triggerName);
    }
    
    //public static void handleAfterInsert(List<CampaignMember> newCMList){
    public override void beforeInsert(List<SObject> tempNewCMList){
        List<CampaignMember> newCMList = (List<CampaignMember>)tempNewCMList;
        Map<Id, Event_Allocation__c> eventAllocMapNew = new Map<Id, Event_Allocation__c>();
        Map<Id, Event_Allocation__c> eventAllocMapOld = new Map<Id, Event_Allocation__c>();
        Map<String, CampaignMember> errorCMMap = new Map<String, CampaignMember>();
        Map<String, CampaignMember> waitlistCMMap = new Map<String, CampaignMember>();
        List<Event_Allocation__c> eventAllocUpdate = new List<Event_Allocation__c>();
        Map<Id, CampaignMember> allCMMap = new Map<Id, CampaignMember>();
        Set<Id> eventAllocIds = new Set<Id>();
        
        system.debug('###TEST INSERT');
        
        for(CampaignMember cm: newCMList){
            if(!eventAllocIds.contains(cm.Event_Allocation__c)){
                eventAllocIds.add(cm.Event_Allocation__c);
            }
        }
        
        if(!eventAllocIds.isEmpty()){
            eventAllocMapNew = new Map<Id, Event_Allocation__c>([SELECT Id, Capacity__c, No_of_host__c, Seats_Available_Tech__c,
                                                                 Seat_Reserved__c, Waitlisted__c, Seats_Available__c 
                                                                 FROM Event_Allocation__c 
                                                                 WHERE Id IN: eventAllocIds]);
            
            allCMMap = new Map<Id, CampaignMember>([SELECT Id, ContactId, RSVP_Status__c, No_of_guests__c, Event_Allocation__c 
                                                    FROM CampaignMember 
                                                    WHERE Event_Allocation__c IN: eventAllocMapNew.keySet() ORDER BY LastModifiedDate ASC]);
            
            //Initialize values on Event Allocation
            for(Event_Allocation__c ea: eventAllocMapNew.values()){
                Event_Allocation__c eaRecTemp = new Event_Allocation__c();
                eaRecTemp.Id = ea.Id;
                eaRecTemp.Seat_Reserved__c = ea.Seat_Reserved__c;
                eaRecTemp.Waitlisted__c = ea.Waitlisted__c;
                
                eventAllocMapOld.put(eaRecTemp.Id, eaRecTemp);
                if(ea.No_of_host__c == null){
                    ea.No_of_host__c = 0;
                }
                if(ea.Capacity__c == null){
                    ea.Capacity__c = 0;
                }
                ea.Seat_Reserved__c = 0; 
                ea.Waitlisted__c = 0;
                ea.Seats_Available_Tech__c = ea.Capacity__c - (ea.Seat_Reserved__c + ea.No_of_host__c);
            }
            
            for(CampaignMember cm: allCMMap.values()){
                system.debug('###TEST INSERT 1 cm.No_of_guests__c: ' + cm.No_of_guests__c);
                system.debug('###TEST INSERT 1 eventAllocMapNew.get(cm.Event_Allocation__c): ' + eventAllocMapNew.get(cm.Event_Allocation__c));
                if(cm.Event_Allocation__c != null){
                    if(cm.RSVP_Status__c == 'Attending' || cm.RSVP_Status__c == 'Tentative' || cm.RSVP_Status__c == null){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        
                        eaRec.Seat_Reserved__c = eaRec.Seat_Reserved__c + numGuests;
                        eaRec.Seats_Available_Tech__c = eaRec.Seats_Available_Tech__c - numGuests;
                        eventAllocMapNew.put(eaRec.Id, eaRec);
                                        
                    }else if(cm.RSVP_Status__c == 'Waitlist'){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        eaRec.Waitlisted__c = eaRec.Waitlisted__c + numGuests;
                        eventAllocMapNew.put(eaRec.Id, eaRec);
                    }
                }
            }
            
            for(CampaignMember cm :newCMList){
                if(cm.Event_Allocation__c != null){
                    if(cm.RSVP_Status__c == 'Attending' || cm.RSVP_Status__c == 'Tentative' || cm.RSVP_Status__c == null){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        Decimal availSeats = eventAllocMapNew.get(cm.Event_Allocation__c).Seats_Available_Tech__c;
                        system.debug('###TEST INSERT 2 numGuests: ' + numGuests);
                        system.debug('###TEST INSERT 2 availSeats: ' + availSeats);
                        if(numGuests > availSeats && availSeats != 0){
                            system.debug('###TEST INSERT ERROR numGuests: ' + numGuests);
                            system.debug('###TEST INSERT ERROR availSeats: ' + availSeats);
                            String keyName = cm.ContactId + '_' + cm.Event_Allocation__c; 
                            errorCMMap.put(keyName, cm);
                        }else if(numGuests > availSeats && availSeats == 0){
                            eaRec.Waitlisted__c = eaRec.Waitlisted__c + numGuests;
                            eventAllocMapNew.put(eaRec.Id, eaRec);
                            String keyName = cm.ContactId + '_' + cm.Event_Allocation__c;
                            waitlistCMMap.put(keyName, cm);
                        }else{
                            eaRec.Seat_Reserved__c = eaRec.Seat_Reserved__c + numGuests;
                            eaRec.Seats_Available_Tech__c = eaRec.Seats_Available_Tech__c - numGuests;
                            eventAllocMapNew.put(eaRec.Id, eaRec); 
                        }    
                    }else if(cm.RSVP_Status__c == 'Waitlist'){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        eaRec.Waitlisted__c = eaRec.Waitlisted__c + numGuests;
                        eventAllocMapNew.put(eaRec.Id, eaRec);
                    }
                }
            }
            
            for(Event_Allocation__c ea: eventAllocMapNew.values()){
                if(eventAllocMapOld.get(ea.Id).Seat_Reserved__c != ea.Seat_Reserved__c || eventAllocMapOld.get(ea.Id).Waitlisted__c != ea.Waitlisted__c){
                    eventAllocUpdate.add(ea);             
                }
            }
            
            
            if(!errorCMMap.isEmpty() || !waitlistCMMap.isEmpty()){
                for(CampaignMember cm: newCMList){
                    String keyName = cm.ContactId + '_' + cm.Event_Allocation__c;
                    if(errorCMMap.containsKey(keyName)){
                        system.debug('###TEST INSERT 2 keyName: ' + keyName);
                        cm.addError('We don’t have enough seat available, please reduce the number.');
                    }
                    if(waitlistCMMap.containsKey(keyName)){
                        cm.RSVP_Status__c = 'Waitlist';
                    }
                }
            }
            
            if(!eventAllocUpdate.isEmpty()){
                update eventAllocUpdate;
            }
        }
    }
    
    //public static void handleBeforeUpdate(List<CampaignMember> newCMList, Map<Id, CampaignMember> newCMMap, Map<Id, CampaignMember> oldCMMap){
    public override void beforeUpdate(List<SObject> tempOldCMList, List<SObject> tempNewCMList, Map<Id, SObject> tempOldCMMap, Map<Id, SObject> tempNewCMMap){
        List<CampaignMember> newCMList = (List<CampaignMember>)tempNewCMList;
        Map<Id, CampaignMember> newCMMap = (Map<Id, CampaignMember>)tempNewCMMap;
        Map<Id, CampaignMember> oldCMMap = (Map<Id, CampaignMember>)tempOldCMMap;
        
        Map<Id, Event_Allocation__c> eventAllocMapNew = new Map<Id, Event_Allocation__c>();
        Map<Id, Event_Allocation__c> eventAllocMapOld = new Map<Id, Event_Allocation__c>();
        Map<Id, CampaignMember> errorCMMap = new Map<Id, CampaignMember>();
        Map<Id, CampaignMember> waitlistCMMap = new Map<Id, CampaignMember>();
        List<Event_Allocation__c> eventAllocUpdate = new List<Event_Allocation__c>();
        Map<Id, CampaignMember> allCMMap = new Map<Id, CampaignMember>();
        Set<Id> eventAllocIds = new Set<Id>();

        /* CRM2-2057 */
        Map<Id, CampaignMember> cmUpdatedStatusMap = new Map<Id, CampaignMember>();
        /* CRM2-2057 */

        for(CampaignMember cm: newCMList){
            if(newCMMap.get(cm.Id).RSVP_Status__c != oldCMMap.get(cm.Id).RSVP_Status__c ||
               newCMMap.get(cm.Id).No_of_guests__c != oldCMMap.get(cm.Id).No_of_guests__c ||
               newCMMap.get(cm.Id).Event_Allocation__c != oldCMMap.get(cm.Id).Event_Allocation__c){
                   if(!eventAllocIds.contains(cm.Event_Allocation__c)){
                       eventAllocIds.add(cm.Event_Allocation__c);
                       eventAllocIds.add(oldCMMap.get(cm.Id).Event_Allocation__c);
                   }    
               }

            /* CRM2-2057 */
            if (newCMMap.get(cm.Id).Status != oldCMMap.get(cm.Id).Status) {
                cmUpdatedStatusMap.put(cm.Id, cm);
            }
            /* CRM2-2057 */
        }

        /* CRM2-2057 */
        // Users with Profile: TSEG Read Only should not be allowed to update Campaign Member Status
        Profile tsegROprofile = [SELECT Id FROM Profile WHERE Name = 'TSEG Read Only' LIMIT 1];
        String userProfileId = UserInfo.getProfileId();
        if (userProfileId == tsegROprofile.Id) {
            for (CampaignMember cm: cmUpdatedStatusMap.values()) {
                cm.addError(System.Label.UNABLE_TO_UPDATE_CAMPAIGN_MEMBER_STATUS);
            }
        }
        /* CRM2-2057 */

        if(!eventAllocIds.isEmpty()){
            eventAllocMapNew = new Map<Id, Event_Allocation__c>([SELECT Id, Capacity__c, No_of_host__c, Seats_Available_Tech__c, 
                                                                 Seat_Reserved__c, Waitlisted__c, Seats_Available__c  
                                                                 FROM Event_Allocation__c 
                                                                 WHERE Id IN: eventAllocIds]);
            
            allCMMap = new Map<Id, CampaignMember>([SELECT Id, RSVP_Status__c, No_of_guests__c, Event_Allocation__c 
                         FROM CampaignMember 
                         WHERE Event_Allocation__c IN: eventAllocMapNew.keySet() ORDER BY LastModifiedDate ASC]);
            
            Set<Id> sortIndex = new Set<Id>();
            
            //Sort CM records to make newly updated one to always be last from the list
            for(CampaignMember cmRemoveSort : allCMMap.values()){
                if(newCMMap.containsKey(cmRemoveSort.Id)){
                    sortIndex.add(cmRemoveSort.Id);
                }
            }
            
            for(Id removeCM : sortIndex){
                allCMMap.remove(removeCM);    
            }
            
            for(CampaignMember cmAddSort : newCMMap.values()){
                if(eventAllocMapNew.containsKey(cmAddSort.Event_Allocation__c)){
                    allCMMap.put(cmAddSort.Id, cmAddSort);
                }
            }
            //end of sorting
            
            //Initialize values on Event Allocation
            for(Event_Allocation__c ea: eventAllocMapNew.values()){
                Event_Allocation__c eaRecTemp = new Event_Allocation__c();
                eaRecTemp.Id = ea.Id;
                eaRecTemp.Seat_Reserved__c = ea.Seat_Reserved__c;
                eaRecTemp.Waitlisted__c = ea.Waitlisted__c;
                
                eventAllocMapOld.put(eaRecTemp.Id, eaRecTemp);
                if(ea.No_of_host__c == null){
                    ea.No_of_host__c = 0;
                }
                if(ea.Capacity__c == null){
                    ea.Capacity__c = 0;
                }
                ea.Seat_Reserved__c = 0; 
                ea.Waitlisted__c = 0;
                ea.Seats_Available_Tech__c = ea.Capacity__c - (ea.Seat_Reserved__c + ea.No_of_host__c);
            }
            
            for(CampaignMember cm: allCMMap.values()){
                if(cm.Event_Allocation__c != null){
                    if(newCMMap.containsKey(cm.Id)){
                        cm = newCMMap.get(cm.Id);
                    }
                    
                    if(cm.RSVP_Status__c == 'Attending' || cm.RSVP_Status__c == 'Tentative' || cm.RSVP_Status__c == null){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        Decimal availSeats = eventAllocMapNew.get(cm.Event_Allocation__c).Seats_Available_Tech__c;
                        
                        if(oldCMMap.containsKey(cm.Id)){
                            if(numGuests > availSeats && availSeats != 0){
                                errorCMMap.put(cm.id, cm);
                            }else if(numGuests > availSeats && availSeats == 0){
                                eaRec.Waitlisted__c = eaRec.Waitlisted__c + numGuests;
                                eventAllocMapNew.put(eaRec.Id, eaRec);
                                waitlistCMMap.put(cm.id, cm);
                            }else{
                                eaRec.Seat_Reserved__c = eaRec.Seat_Reserved__c + numGuests;
                                eaRec.Seats_Available_Tech__c = eaRec.Seats_Available_Tech__c - numGuests;
                                eventAllocMapNew.put(eaRec.Id, eaRec);
                            }
                        }else{
                            eaRec.Seat_Reserved__c = eaRec.Seat_Reserved__c + numGuests;
                            eaRec.Seats_Available_Tech__c = eaRec.Seats_Available_Tech__c - numGuests;
                            eventAllocMapNew.put(eaRec.Id, eaRec);
                        }                
                    }else if(cm.RSVP_Status__c == 'Waitlist'){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        eaRec.Waitlisted__c = eaRec.Waitlisted__c + numGuests;
                        eventAllocMapNew.put(eaRec.Id, eaRec);
                    }
                }
            }
            
            for(Event_Allocation__c ea: eventAllocMapNew.values()){
                if(eventAllocMapOld.get(ea.Id).Seat_Reserved__c != ea.Seat_Reserved__c || eventAllocMapOld.get(ea.Id).Waitlisted__c != ea.Waitlisted__c){
                    eventAllocUpdate.add(ea);             
                }
            }
            
            if(!errorCMMap.isEmpty() || !waitlistCMMap.isEmpty()){
                for(CampaignMember cm: newCMList){
                    if(errorCMMap.containsKey(cm.Id)){
                        cm.addError('We don’t have enough seats available, please reduce the number.');
                    }
                    if(waitlistCMMap.containsKey(cm.Id)){
                        cm.RSVP_Status__c = 'Waitlist';
                    }
                }
            }
            
            if(!eventAllocUpdate.isEmpty()){
                update eventAllocUpdate;
            }
        }
    }
    
    //public static void handleBeforeDelete(List<CampaignMember> deleteCMList){
    public override void beforeDelete(List<SObject> tempDeleteCMList, Map<ID, SObject> oldCMMap){
        List<CampaignMember> deleteCMList = (List<CampaignMember>) tempDeleteCMList;
        Map<Id, Event_Allocation__c> eventAllocMapNew = new Map<Id, Event_Allocation__c>();
        Map<Id, Event_Allocation__c> eventAllocMapOld = new Map<Id, Event_Allocation__c>();
        List<Event_Allocation__c> eventAllocUpdate = new List<Event_Allocation__c>();
        Map<Id, CampaignMember> allCMMap = new Map<Id, CampaignMember>();
        Set<Id> eventAllocIds = new Set<Id>();
        Set<Id> deleteCMIdSet = new Set<Id>();

        /* CRM2-2057 */
        List<CampaignMember> cmForDeleteList = new List<CampaignMember>();
        /* CRM2-2057 */

        for(CampaignMember cm: deleteCMList){
            if(!eventAllocIds.contains(cm.Event_Allocation__c)){
                eventAllocIds.add(cm.Event_Allocation__c);
            }
            if(!deleteCMIdSet.contains(cm.Id)){
                deleteCMIdSet.add(cm.Id);
            }

            /* CRM2-2057 */
            cmForDeleteList.add(cm);
            /* CRM2-2057 */
        }

        /* CRM2-2057 */
        // Users with Profile: TSEG Read Only should not be allowed to delete Campaign Member records
        Profile tsegROprofile = [SELECT Id FROM Profile WHERE Name = 'TSEG Read Only' LIMIT 1];
        String userProfileId = UserInfo.getProfileId();
        if (userProfileId == tsegROprofile.Id) {
            for (CampaignMember cm: cmForDeleteList) {
                cm.addError(System.Label.UNABLE_TO_DELETE_CAMPAIGN_MEMBER_STATUS);
            }
        }
        /* CRM2-2057 */
        
        if(!eventAllocIds.isEmpty()){
            eventAllocMapNew = new Map<Id, Event_Allocation__c>([SELECT Id, Capacity__c, No_of_host__c, Seats_Available_Tech__c,
                                                                 Seat_Reserved__c, Waitlisted__c, Seats_Available__c 
                                                                 FROM Event_Allocation__c 
                                                                 WHERE Id IN: eventAllocIds]);
            
            allCMMap = new Map<Id, CampaignMember>([SELECT Id, RSVP_Status__c, No_of_guests__c, Event_Allocation__c 
                                                    FROM CampaignMember 
                                                    WHERE Event_Allocation__c IN: eventAllocMapNew.keySet() AND ID NOT IN: deleteCMIdSet ORDER BY LastModifiedDate ASC]);
            
            //Initialize values on Event Allocation
            for(Event_Allocation__c ea: eventAllocMapNew.values()){
                Event_Allocation__c eaRecTemp = new Event_Allocation__c();
                eaRecTemp.Id = ea.Id;
                eaRecTemp.Seat_Reserved__c = ea.Seat_Reserved__c;
                eaRecTemp.Waitlisted__c = ea.Waitlisted__c;
                
                eventAllocMapOld.put(eaRecTemp.Id, eaRecTemp);
                if(ea.No_of_host__c == null){
                    ea.No_of_host__c = 0;
                }
                if(ea.Capacity__c == null){
                    ea.Capacity__c = 0;
                }
                ea.Seat_Reserved__c = 0; 
                ea.Waitlisted__c = 0;
                ea.Seats_Available_Tech__c = ea.Capacity__c - (ea.Seat_Reserved__c + ea.No_of_host__c);
            }
            
            for(CampaignMember cm: allCMMap.values()){
                if(cm.Event_Allocation__c != null){
                    if(cm.RSVP_Status__c == 'Attending' || cm.RSVP_Status__c == 'Tentative' || cm.RSVP_Status__c == null){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        
                        eaRec.Seat_Reserved__c = eaRec.Seat_Reserved__c + numGuests;
                        eaRec.Seats_Available_Tech__c = eaRec.Seats_Available_Tech__c - numGuests;
                        eventAllocMapNew.put(eaRec.Id, eaRec);
                                        
                    }else if(cm.RSVP_Status__c == 'Waitlist'){
                        Event_Allocation__c eaRec = eventAllocMapNew.get(cm.Event_Allocation__c);
                        if(cm.No_of_guests__c == null){
                            cm.No_of_guests__c = 0;
                        }
                        Decimal numGuests = cm.No_of_guests__c + 1;
                        eaRec.Waitlisted__c = eaRec.Waitlisted__c + numGuests;
                        eventAllocMapNew.put(eaRec.Id, eaRec);
                    }
                }
            }
            
            for(Event_Allocation__c ea: eventAllocMapNew.values()){
                if(eventAllocMapOld.get(ea.Id).Seat_Reserved__c != ea.Seat_Reserved__c || eventAllocMapOld.get(ea.Id).Waitlisted__c != ea.Waitlisted__c){
                    eventAllocUpdate.add(ea);             
                }
            }
            
            if(!eventAllocUpdate.isEmpty()){
                update eventAllocUpdate;
            }
        }    
    }
}