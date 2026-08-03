@isTest
public class TestDataFactory {
    public static Contact createSingleContact (String name )
    {
        Contact con = new Contact(FirstName = name , LastName = 'Simplus', Email = 'none@testsimplus.com');
        insert con;
        return con;
    }
    public static Campaign createSingleCampaign(String RecordType)
    {
        Datetime dateTimeNow = Datetime.now();
        Datetime StartDate = dateTimeNow.addDays(2);
        Datetime EndDate = dateTimeNow.addDays(7);
        
        String rtID = Schema.Sobjecttype.Campaign.getRecordTypeInfosByName().get(RecordType).getRecordTypeId();
        Campaign c = new Campaign(Name='Test',Event_Start_Date_Time__c = StartDate, Event_End_Date_Time__c = EndDate, Description = 'Test Data Campaign', RecordTypeId = rtID );
        insert c;
        return c;
    }
    public static Event_Allocation__c createSingleEventAllocation(integer capacity, Campaign c )
    {
        Allocation__c a = new Allocation__c(Name = 'Local');
        insert a;

        Event_Allocation__c al = new Event_Allocation__c();
        al.Name = 'Event Allocation Test ';
        al.Capacity__c = capacity; 
        al.No_of_host__c = 1;
        al.Event__c = c.Id;
        al.Allocation__c =a.id;
        al.Seat_Reserved__c = 0;
        system.debug('Seats Available >>> '+        al.Seats_Available__c);
        insert al;
        return al;
    }
    public static CampaignMember createCampaingMember(Contact con, Event_Allocation__c Al,Campaign c, String rsvpStatus, Integer noOfGuest)
    {
        
        CampaignMember cm = new CampaignMember();
        cm.CampaignId = c.Id;
        cm.Event_Allocation__c = al.Id;
        cm.RSVP_Status__c =  rsvpStatus ; 
        cm.No_of_guests__c = noOfGuest; 
        cm.Status = 'Invited';
        cm.ContactId = con.id;
        
        system.debug('Campaign Member >> ' +cm);
        
        insert cm;
        return cm;
        
    }
    
    @future
    public static void createUser(String profileName, String roleName){
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = :profileName];
        UserRole userRole = [SELECT Id FROM UserRole WHERE Name = :roleName];
        User testUser = new User(
            FirstName = 'Test First',
            LastName = 'Test Last',
            Email = 'testUser@starTest.com',
            Alias = 'tasu',
            Username = 'testAdminUser@starTest.com',
            CommunityNickname = 'TestUser',
            ProfileId = userProfile.Id,
            UserRoleId = userRole.Id,
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        
        insert testUser;
    }
}