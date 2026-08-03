public class ApplyKYCRefreshScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        ApplyKYCRefresh batch = new ApplyKYCRefresh();
        Database.executeBatch(batch, 100);
    }
}