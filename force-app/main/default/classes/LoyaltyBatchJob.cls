/**
* @File Name          : LoyaltyBatchJob.apxc
* @Description        : Loyalty Batch Job that runs everyday,every monday and every 1st day of the month at 12AM
* @Author             : Lawrence Faith Abella
* @Group              : Simplus
* @Last Modified By   : Lawrence Faith Abella
* @Last Modified On   : 19/01/21
**/
global class LoyaltyBatchJob implements Database.Batchable<sObject>, Schedulable{
    //Batch Apex
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select ID, Name,Tier_Points_Earned_Today__c,Tier_Points_Earned_This_Week__c,Tier_Points_Earned_This_Month__c From Loyalty__c]);
    }
    global void execute(Database.BatchableContext BC, List<Loyalty__c> LoList){
        
        //Reset the following field on Loyalty records based on the following criteria
        //Tier_Points_Earned_Today__c, Every Day
        //Tier_Points_Earned_This_Week__c,   Every Monday
        //Tier_Points_Earned_This_Month__    Every First Day of the Month
        /*
*  If DateToday.Time = 0:00:00(12:AM) Tier_Points_Earned_Today__c = 0
*  If DateToday = Monday Then Tier_Points_Earned_This_Week__c = 0
*  If DateToday = Firstday of the month THEN Tier_Points_Earned_This_Month__ = 0
*/
        System.debug('Loyalty List : ' +LoList);
        
        //        Date dateToday = System.today().addDays(12); 
        //        Date firstDayOfMonth = System.today().toStartOfMonth().addDays(31); 
        //        Use above code for testing the criteria
        
        
        LoyaltyDay__c mc = LoyaltyDay__c.getOrgDefaults();
        System.debug('DAY -------> ' +mc.Add_Day__c);
        integer days = mc.Add_Day__c.intValue();
        Date dateToday = System.today().addDays(days); 
        System.debug('DATE TODAY  -----------------> ' +dateToday);
        Datetime dt = (DateTime)dateToday;
        String dayOfWeek = dt.format('EEEE');
        system.debug('Day of the week : ' +dayOfWeek);
        
        Date firstDayOfMonth = dateToday.toStartOfMonth();
        system.debug('Fist Day of the month' +firstDayOfMonth);
        
        
        for(Loyalty__c lo : LoList)
        {
            lo.Tier_Points_Earned_Today__c = 0;
            
            If(dateToday != firstDayOfMonth && dayOfWeek !='Monday')
            {            	
                System.debug('TODAY IS not 1st day of the month AND not a Monday');
            }
            if (dateToday == firstDayOfMonth)
            {
                lo.Tier_Points_Earned_This_Month__c = 0;
                System.debug('FIRST DAY OF THE MONTH ---------- >: TRUE');
            }
            if (dayOfWeek =='Monday')
            {
                lo.Tier_Points_Earned_This_Week__c = 0;
                System.debug(' Update Week Tier to 0 : TRUE');
            }
        }
        
        // List<Loyalty__c> LoyaltyToUpdate = new List<Loyalty__c>();
        update LoList;
    }
    global void finish(Database.BatchableContext BC){
        
    }
    //Schedule this Batch Apex Class
    global void execute(SchedulableContext ctx){
        LoyaltyBatchJob abj = new LoyaltyBatchJob();
        database.executeBatch(abj, 100);
    }
}