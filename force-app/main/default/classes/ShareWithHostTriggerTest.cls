@isTest
public class ShareWithHostTriggerTest 
{
    static testMethod void testShareRead()
    {
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
        
        test.startTest();
        
        MTDYTD_Trend_Data__c mtd = new MTDYTD_Trend_Data__c();
        mtd.Host_Sydney__c = uu[0].id;
        mtd.Host_Brisbane__c = uu[1].id;
        mtd.Host_GC__c = uu[2].id;
        mtd.Host_International__c =  uu[3].id;   
        mtd.Gaming_Days_MTD__c = 100;
        insert mtd;
        
        mtd.Host_GC__c = uu[3].id; 
        mtd.Host_Sydney__c = uu[1].id;
        mtd.Host_Brisbane__c = uu[0].id;
        mtd.Host_International__c =  uu[0].id;   
        update mtd;
        
        test.stopTest();
    }
}