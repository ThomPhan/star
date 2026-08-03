global class PortalUpdateSyncBatchSchedule implements Schedulable
{
     global void execute(SchedulableContext sc)
     {
     PortalUpdateSyncBatch b = new PortalUpdateSyncBatch(); 
       database.executeBatch(b);
     }
}