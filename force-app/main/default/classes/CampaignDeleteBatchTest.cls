@isTest
public class CampaignDeleteBatchTest {
    
    @TestSetup
    static void testData(){

        CampaignDeleteBatchSetting__c campDeleteSetting = new CampaignDeleteBatchSetting__c();

        campDeleteSetting.Num_of_Days__c = 90;
        campDeleteSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert campDeleteSetting;
        
        Id offerRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Offer').getRecordTypeId();

        Campaign c = new Campaign();
        c.Name = 'Test Campaign';
        c.RecordTypeId = offerRecType;

        insert c;

        Test.setCreatedDate(c.Id, Date.valueOf('2020-01-01'));

        Contact cont = new Contact();
        cont.FirstName = 'Test 1';
        cont.LastName = 'Test 2';
        insert cont;

        CampaignMember cm = new CampaignMember();
        cm.CampaignId = c.Id;
        cm.ContactId = cont.Id;
        insert cm;
    }

    @isTest
    static void testMethodRunBatch(){

        CampaignDeleteBatch cBatch = new CampaignDeleteBatch();
        Database.executeBatch(cBatch);
    }

    @isTest
    static void testMethodRunBatch2(){

        Campaign c = [SELECT Id FROM Campaign LIMIT 1];
        Set<Id> testIdSet = new Set<Id>();
        testIdSet.add(c.Id);
        CampaignDeleteBatch cBatch = new CampaignDeleteBatch(testIdSet);
        Database.executeBatch(cBatch);
    }

    @isTest
    static void testMethodScheduleBatch(){

        CampaignDeleteBatch cBatch = new CampaignDeleteBatch();
        cBatch.execute(null);
    }
}