/*
* @File Name          : Update_MTDY_ContactHostTriggerTest
* @Description        : 
* @Author             : Lawrence Faith Abella
* @Group              : Simplus
* @Last Modified By   : Lawrence Faith Abella
* @Last Modified On   : 12/03/21
**/
@isTest
public class Update_MTDY_ContactHostTriggerTest {
    
    @isTest
    static void TestInsert()
    {
        List<Contact> conList = new List<Contact>();
        List<MTDYTD_Trend_Data__c> mtdyList = new List<MTDYTD_Trend_Data__c>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        
        List<User> uu = new List<User>();
        
        while (uu.size() < 5) 
        {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String uid = h.SubString(0,8);
            User u = new User(Alias = uid, Email= uid + '@myorg.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, 
                              TimeZoneSidKey='America/New_York', UserName= uid + '@myorg.com');      
            uu.add(u);
        }
        
        insert(uu);       
        
        Test.startTest();
        
        date dob = date.newInstance(1990, 11, 21);
        
        //Patron
        for(Integer x = 0 ; x<=100;x++)
            conList.add(new Contact(
                lastName = 'Patron' +x,
                firstName = 'Testing'+x,
                Date_of_Birth__c = dob,
                patron_Id__c = '123'+x,
                Host_Sydney__c = uu[0].id,
                Host_Brisbane__c = uu[1].id,
                Host_GC__c = uu[2].id,
                Host_International__c =  uu[3].id
                
            ));
        if(conList.size()>0){insert conList;}
        
        for(Integer x = 0 ; x<=100;x++)
        {
            mtdyList.add(new MTDYTD_Trend_Data__c(
                Patron_id__c = '123'+x
            ));
        }
        
        if(mtdyList.size()>0){insert mtdyList;}
        System.debug('PATRON LIST : ' +conList);
        System.debug('mtdyList: ' +mtdyList);
        
        
        Update_MTDY_ContactHostTriggerHandler.updatContactHostMapping(mtdyList);
        
        //Test callout to cover the MTDYTDGetRecordCount and MTDYTDDeleteRecords Test coverage
        MTDYTDGetRecordCount.GetRecordCount();
        MTDYTDDeleteRecords.doDelete();
        Test.stopTest();
    }
    
}