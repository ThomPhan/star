global class ExclusionRollupScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ExclusionRollupBatch(), 200);
    }
}