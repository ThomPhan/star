public with sharing class TravellerTriggerHandler {
   
    public static void onBeforeInsert(List<Other_Traveller__c> travellerList){

        checkLimitOfRecords(travellerList);
    }

    public static void checkLimitOfRecords(List<Other_Traveller__c> travellerList){
        
        Set<Id> tempServiceSet = new Set<Id>();

        for(Other_Traveller__c otherTravRec : travellerList){

            tempServiceSet.add(otherTravRec.Service__c);
        }

        //Map<Id, AggregateResult> aggServMap = new Map<id, AggregateResult>([SELECT Service__c Id, Count(Id) travCount FROM Other_Traveller__c WHERE Service__c IN: tempServiceSet GROUP BY Service__c]);

        Map<Id, Service__c> serviceMap = new Map<Id, Service__c>([SELECT Id, RecordType.Name, (SELECT Id FROM Other_Travellers__r) FROM Service__c WHERE Id IN: tempServiceSet]);

        if(!serviceMap.isEmpty()){

            for(Other_Traveller__c otherTravRec : travellerList){

                if(serviceMap.containsKey(otherTravRec.Service__c)){
                    
                    if(serviceMap.get(otherTravRec.Service__c).Other_Travellers__r.size() >= 5){

                        otherTravRec.addError('You cannot add more than 5 Travellers');
                    }
                }
            }
        }
    }
}