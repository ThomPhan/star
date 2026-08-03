@isTest
    public class LoyaltyBatchJobTest {
    
    @testSetup static void TestDataSetup()
    {
        //Patron <- Contact
        //Loyalty Program
        //Loyalty 
        // Tier 
        List<Contact> conList = new List<Contact>();
        List<Loyalty_Program__c> lpList = new List<Loyalty_Program__c>();
       
        date dob = date.newInstance(1990, 11, 21);

         //Patron
        for(Integer x = 0 ; x<=10;x++)
            conList.add(new Contact(
                lastName = 'Patron' +x,
                firstName = 'Testing'+x,
                Date_of_Birth__c = dob
            ));
        if(conList.size()>0){insert conList;}
        
        //Loyalty Program
        //Star Gold
        //Star Club
        //Star Club Interstate
        
        for(Integer x = 0 ; x<=10;x++)
            lpList.add(new Loyalty_Program__c(
                Name = 'Star Gold' +x
            ));
        if(lpList.size()>0){insert lpList;}
        //Loyalty
        System.debug('PATRON LIST : ' +conList);
        System.debug('LOYALTY PROGRAM LIST : ' +lpList);
        
    }
    @isTest
    static void LoyaltyResetDaily()
    {
        TestDataSetup();
        Contact con = [SELECT Id,Name FROM Contact WHERE LastName = 'Patron0' Limit 1];
        Loyalty_Program__c lp = [Select Id,Name From Loyalty_Program__c Where Name = 'Star Gold0' Limit 1];
        List<Loyalty__c> loList = new List<Loyalty__c>();
        
        insert new LoyaltyDay__c(Add_Day__c = 0);

         Loyalty__c loy = new Loyalty__c();
                loy.Name ='Test Gold';
                loy.Tier_Points_Earned_Today__c = 10;
                loy.Tier_Points_Earned_This_Week__c=20;
                loy.Tier_Points_Earned_This_Month__c =300;
                loy.Tier__c = 'Gold';
                loy.Loyalty_Program__c = lp.Id;
                loy.Patron__c = con.id;
            loList.add(loy);
        insert loList;
       System.debug('LOYALTY LIST : ' +loList);
       // if(loList.size() > 0){insert loList;}
        System.debug('LOYALTY LIST -----> '+loList);
        Test.startTest();
        
        LoyaltyBatchJob abj = new LoyaltyBatchJob();
        database.executeBatch(abj, 100);
        
        abj.execute(null,loList);
        abj.Finish(null);
        Test.stopTest();
    }
    
     @isTest
    static void LoyaltyResetMonthly()
    {
        TestDataSetup();
        Contact con = [SELECT Id,Name FROM Contact WHERE LastName = 'Patron1' Limit 1];
        Loyalty_Program__c lp = [Select Id,Name From Loyalty_Program__c Where Name = 'Star Gold1' Limit 1];
        List<Loyalty__c> loList = new List<Loyalty__c>();
        
        integer day = 5;
        insert new LoyaltyDay__c(Add_Day__c = day);

         Loyalty__c loy = new Loyalty__c();
                loy.Name ='Test Gold1';
                loy.Tier_Points_Earned_Today__c = 10;
                loy.Tier_Points_Earned_This_Week__c=20;
                loy.Tier_Points_Earned_This_Month__c =300;
                loy.Tier__c = 'Gold';
                loy.Loyalty_Program__c = lp.Id;
                loy.Patron__c = con.id;
            loList.add(loy);
        
        insert loList;
       System.debug('LOYALTY LIST : ' +loList);
       // if(loList.size() > 0){insert loList;}
        System.debug('LOYALTY LIST -----> '+loList);
        Test.startTest();
        
        LoyaltyBatchJob abj = new LoyaltyBatchJob();
        database.executeBatch(abj, 100);
        
        abj.execute(null,loList);
        abj.Finish(null);
        Test.stopTest();
    }
}