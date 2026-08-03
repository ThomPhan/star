global class highProfileTestBatch implements Database.Batchable<sObject>{
    global highProfileTestBatch() {

    }

    global Iterable<SObject> start(Database.BatchableContext BC){
        return [SELECT EventDate,EventIdentifier,Operation,QueriedEntities,RecordId,SourceIp,Username,DevicePlatform,OsName,UserType FROM LightningUriEvent WHERE EventDate = LAST_N_DAYS:30 LIMIT 5];
    }

    global void execute(Database.BatchableContext BC, List<LightningUriEvent> lightningURIList){

        List<ContactLightningURIEvent__b> contURIEventList = new List<ContactLightningURIEvent__b>();

        for(LightningUriEvent lEvent : lightningURIList){

            ContactLightningURIEvent__b contURIEvent = new ContactLightningURIEvent__b();
            contURIEvent.EventDate__c = lEvent.EventDate;
            contURIEvent.Operation__c = lEvent.Operation;
            contURIEvent.EventIdentifier__c = lEvent.EventIdentifier;
            contURIEvent.QueriedEntities__c = lEvent.QueriedEntities;
            contURIEvent.RecordId__c = lEvent.RecordId;
            contURIEvent.IPAddress__c = 'TESTING OF BATCH';
            contURIEvent.User__c = lEvent.Username;
            contURIEvent.Platform__c = lEvent.DevicePlatform;
            contURIEvent.OperatingSystem__c = lEvent.OsName;
            contURIEvent.UserType__c = lEvent.UserType;
            contURIEventList.add(contURIEvent);
        }

        if(!contURIEventList.isEmpty()){

            Database.insertImmediate(contURIEventList);
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }
}