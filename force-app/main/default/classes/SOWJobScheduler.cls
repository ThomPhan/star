public class SOWJobScheduler {
    public static void runSOWBatchJob(){
        SOWBatchJob b = new SOWBatchJob();
        String sch1 = '0 3 * * * ?';
        String sch2 = '0 6 * * * ?';
        String sch3 = '0 9 * * * ?';
        String sch4 = '0 12 * * * ?';
        String sch5 = '0 15 * * * ?';
        String sch6 = '0 18 * * * ?';
        String sch7 = '0 21 * * * ?';
        String sch8 = '0 24 * * * ?';
        String sch9 = '0 27 * * * ?';
        String sch10 = '0 30 * * * ?';
        String sch11 = '0 33 * * * ?';
        String sch12 = '0 36 * * * ?';
        String sch13 = '0 39 * * * ?';
        String sch14 = '0 42 * * * ?';
        String sch15 = '0 45 * * * ?';
        String sch16 = '0 48 * * * ?';
        String sch17 = '0 51 * * * ?';
        String sch18 = '0 54 * * * ?';
        String sch19 = '0 57 * * * ?';
        String sch20 = '0 0 * * * ?';
        
        system.schedule('SOWBatchJob 03', sch1, b);
        system.schedule('SOWBatchJob 06', sch2, b);
        system.schedule('SOWBatchJob 09', sch3, b);
        system.schedule('SOWBatchJob 12', sch4, b);
        system.schedule('SOWBatchJob 15', sch5, b);
        system.schedule('SOWBatchJob 18', sch6, b);
        system.schedule('SOWBatchJob 21', sch7, b);
        system.schedule('SOWBatchJob 24', sch8, b);
        system.schedule('SOWBatchJob 27', sch9, b);
        system.schedule('SOWBatchJob 30', sch10, b);
        system.schedule('SOWBatchJob 33', sch11, b);
        system.schedule('SOWBatchJob 36', sch12, b);
        system.schedule('SOWBatchJob 39', sch13, b);
        system.schedule('SOWBatchJob 42', sch14, b);
        system.schedule('SOWBatchJob 45', sch15, b);
        system.schedule('SOWBatchJob 48', sch16, b);
        system.schedule('SOWBatchJob 51', sch17, b);
        system.schedule('SOWBatchJob 54', sch18, b);
        system.schedule('SOWBatchJob 57', sch19, b);
        system.schedule('SOWBatchJob 00', sch20, b);
    }
    public static void deleteSOWBatchJob(){
        List<CronTrigger> abort_job = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name Like 'SOWBatchJob%'];
        
        for (CronTrigger t : abort_job) { //for each record
            System.abortJob(t.Id); //abort the job
        }
    }
    
    public static void runSOWBatchJob1700(){
        SOWBatchJob1700 b = new SOWBatchJob1700();
        String sch1 = '0 3 * * * ?';
        String sch2 = '0 6 * * * ?';
        String sch3 = '0 9 * * * ?';
        String sch4 = '0 12 * * * ?';
        String sch5 = '0 15 * * * ?';
        String sch6 = '0 18 * * * ?';
        String sch7 = '0 21 * * * ?';
        String sch8 = '0 24 * * * ?';
        String sch9 = '0 27 * * * ?';
        String sch10 = '0 30 * * * ?';
        String sch11 = '0 33 * * * ?';
        String sch12 = '0 36 * * * ?';
        String sch13 = '0 39 * * * ?';
        String sch14 = '0 42 * * * ?';
        String sch15 = '0 45 * * * ?';
        String sch16 = '0 48 * * * ?';
        String sch17 = '0 51 * * * ?';
        String sch18 = '0 54 * * * ?';
        String sch19 = '0 57 * * * ?';
        String sch20 = '0 0 * * * ?';
        
        system.schedule('1700SOWBatchJob 03', sch1, b);
        system.schedule('1700SOWBatchJob 06', sch2, b);
        system.schedule('1700SOWBatchJob 09', sch3, b);
        system.schedule('1700SOWBatchJob 12', sch4, b);
        system.schedule('1700SOWBatchJob 15', sch5, b);
        system.schedule('1700SOWBatchJob 18', sch6, b);
        system.schedule('1700SOWBatchJob 21', sch7, b);
        system.schedule('1700SOWBatchJob 24', sch8, b);
        system.schedule('1700SOWBatchJob 27', sch9, b);
        system.schedule('1700SOWBatchJob 30', sch10, b);
        system.schedule('1700SOWBatchJob 33', sch11, b);
        system.schedule('1700SOWBatchJob 36', sch12, b);
        system.schedule('1700SOWBatchJob 39', sch13, b);
        system.schedule('1700SOWBatchJob 42', sch14, b);
        system.schedule('1700SOWBatchJob 45', sch15, b);
        system.schedule('1700SOWBatchJob 48', sch16, b);
        system.schedule('1700SOWBatchJob 51', sch17, b);
        system.schedule('1700SOWBatchJob 54', sch18, b);
        system.schedule('1700SOWBatchJob 57', sch19, b);
        system.schedule('1700SOWBatchJob 00', sch20, b);
    }
    public static void deleteSOWBatchJob1700(){
        List<CronTrigger> abort_job = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name Like '1700SOWBatchJob%'];
        
        for (CronTrigger t : abort_job) { //for each record
            System.abortJob(t.Id); //abort the job
        }
    }

}