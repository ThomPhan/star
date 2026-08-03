global class LoyaltyScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        LoyaltyBatchJob abj = new LoyaltyBatchJob();
        database.executeBatch(abj, 100);
    }
}