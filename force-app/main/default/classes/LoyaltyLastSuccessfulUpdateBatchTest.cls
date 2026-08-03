@isTest
public class LoyaltyLastSuccessfulUpdateBatchTest{
    @TestSetup
    private static void testDataSetup(){
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
        
        for(Integer x = 0 ; x<=10;x++)
            lpList.add(new Loyalty_Program__c(
                Name = 'Star Gold' +x
            ));
        if(lpList.size()>0){insert lpList;}
        //Loyalty
        System.debug('PATRON LIST : ' +conList);
        System.debug('LOYALTY PROGRAM LIST : ' +lpList);
    }
    
    @IsTest 
    static void test_LoyaltyObjectUpdate(){
        Contact con = [SELECT Id,Name FROM Contact WHERE LastName = 'Patron0' Limit 1];
        Loyalty_Program__c lp = [Select Id,Name From Loyalty_Program__c Where Name = 'Star Gold0' Limit 1];
        List<Loyalty__c> loList = new List<Loyalty__c>();
        
        insert new LoyaltyDay__c(Add_Day__c = 0);
        
        Loyalty__c loy = new Loyalty__c();
        loy.Name ='Test Gold';
        loy.Tier_Points_Earned_Today__c = 10;
        loy.Tier_Points_Earned_This_Week__c=20;
        loy.Tier_Points_Earned_This_Month__c =300;
        loy.External_ID__c = null;
        loy.last_successful_update__C = '';
        loy.CasinoBalance__c = null;
        loy.CompBalance__c = null;
        loy.Tier_Balance__c = null;
        loy.Tier__c = 'Gold';
        loy.Loyalty_Program__c = lp.Id;
        loy.Patron__c = con.id;
        loList.add(loy);
        insert loList;
        
        Test.startTest();
        LoyaltyLastSuccessfulUpdateBatch batch = new LoyaltyLastSuccessfulUpdateBatch();
        String sch = '0 1 * * * ?';
        system.schedule('Test Sched', sch, batch);
        Test.stopTest();
        
        System.assertEquals(true, loList[0].last_successful_update__C != null, 'field is blank');
    }
}