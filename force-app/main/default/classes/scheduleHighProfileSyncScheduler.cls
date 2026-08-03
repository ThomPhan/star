global class scheduleHighProfileSyncScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        
        System.schedule('scheduleHighProfileSync', '0 0 0 * * ?', new scheduleHighProfileSync(UserInfo.getSessionId()));
    }
}