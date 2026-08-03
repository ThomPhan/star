public class ScheduleHighProfileSyncBatch implements Database.Batchable<sObject>, Schedulable {
    private String dynamicDateLiteral;
    @TestVisible List<LightningUriEvent> lightningURIListTest;
    @TestVisible private static Boolean runOriginalConstructor = true;

    public ScheduleHighProfileSyncBatch() {
        HighProfileSyncSetting__c hpsSetting = HighProfileSyncSetting__c.getOrgDefaults();
        Integer numberOfDays = (hpsSetting.Num_of_Days__c == null) ? 90 : (Integer) hpsSetting.Num_of_Days__c;
        this.dynamicDateLiteral = 'LAST_N_DAYS:' + String.valueOf(numberOfDays);
    }

    @TestVisible public ScheduleHighProfileSyncBatch(List<LightningUriEvent> lightningURIList){

        lightningURIListTest = lightningURIList;
    }

    /* Schedulable */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ScheduleHighProfileSyncBatch());
    }

    /* Batch Apex */
    public Iterable<sObject> start(Database.BatchableContext bc) {
    
        if(runOriginalConstructor){

            String queryString = 'SELECT EventDate, Operation, EventIdentifier, QueriedEntities, RecordId, SourceIp, Username, DevicePlatform, OsName, UserType FROM LightningUriEvent WHERE (EventDate = ' + this.dynamicDateLiteral + ')';

            return Database.query(queryString);
        }
        else{

            return lightningURIListTest;
        }
    }

    public void execute(Database.BatchableContext bc, List<LightningUriEvent> lightningURIList) {
        System.debug('lightningURIList: ' + lightningURIList);

        List<ContactLightningURIEvent__b> conURIEventList = new List<ContactLightningURIEvent__b>();
        for (LightningUriEvent lUriEvent: lightningURIList) {
            if (lUriEvent.QueriedEntities != null && lUriEvent.QueriedEntities.contains('Contact')) {
                ContactLightningURIEvent__b conURIEvent = new ContactLightningURIEvent__b();
                conURIEvent.EventDate__c = lUriEvent.EventDate;
                conURIEvent.Operation__c = lUriEvent.Operation;
                conURIEvent.EventIdentifier__c = lUriEvent.EventIdentifier;
                conURIEvent.QueriedEntities__c = lUriEvent.QueriedEntities;
                conURIEvent.RecordId__c = lUriEvent.RecordId;
                conURIEvent.IPAddress__c = lUriEvent.SourceIp;
                conURIEvent.User__c = lUriEvent.Username;
                conURIEvent.Platform__c = lUriEvent.DevicePlatform;
                conURIEvent.OperatingSystem__c = lUriEvent.OsName;
                conURIEvent.UserType__c = lUriEvent.UserType;
                conURIEventList.add(conURIEvent);
            }
        }

        System.debug('conURIEventList: ' + conURIEventList);

        try {
            if(!Test.isRunningTest()){
                Database.insertImmediate(conURIEventList);
            }
        } catch (Exception e) {
            ErrorLogger.createLog('ScheduleHighProfileSyncBatch', 'scheduleHighProfileSyncBatch', e, null, 'Apex Class'); 
        }
    }

    public void finish(Database.BatchableContext bc) {
        ScheduledDeleteBigObjectBatch deleteBigObjectBatch = new ScheduledDeleteBigObjectBatch();
        Database.executeBatch(deleteBigObjectBatch);
    }
}