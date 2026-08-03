@isTest()
public class SOWBatchJobTest{
    
    @IsTest
    static void test_LoyaltyObjectUpdate(){
        List<Contact> conList = new List<Contact>();
        date dob = date.newInstance(1990, 11, 21);
        
        //Patron
        for(Integer x = 0 ; x<=10;x++)
            conList.add(new Contact(
                lastName = 'Patron' +x,
                firstName = 'Testing'+x,
                Date_of_Birth__c = dob
            ));
        if(conList.size()>0){
            insert conList;
        }
        
        conList[0].Name_of_business_or_company__c = 'test';
        conList[0].Refused_to_provide_SOW__c = false;
        conList[0].Bulk_Update_for_Data_Fix__c = false;
        update conList;
        
        insert new SOW_Id__c(Is_updated__c = false, Name = 'Test1');

        Test.startTest();
        SOWBatchJob batch1 = new SOWBatchJob();
        SOWBatchJob1700 batch2 = new SOWBatchJob1700();
        String sch = '0 1 * * * ?';
        system.schedule('Test Schedule for SOWBatchJob', sch, batch1);
        system.schedule('Test Schedule for SOWBatchJob1700', sch, batch2);
        Test.stopTest();
        
    }
    
    @IsTest 
    static void test_SOWJobScheduler(){
        Test.startTest();
        SOWJobScheduler.runSOWBatchJob();
        SOWJobScheduler.deleteSOWBatchJob();
        SOWJobScheduler.runSOWBatchJob1700();
        SOWJobScheduler.deleteSOWBatchJob1700();
        Test.stopTest();
        
    }
}