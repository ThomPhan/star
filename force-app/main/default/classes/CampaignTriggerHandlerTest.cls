@isTest
public class CampaignTriggerHandlerTest {
    static testmethod void testInsertUpdate(){
        
        // List<CampaignMember> cmlist = new List<CampaignMember>();
        Campaign C = TestDataFactory.createSingleCampaign('Event');
        Event_Allocation__c Al = TestDataFactory.createSingleEventAllocation(150,c);
        
        Contact con1 = TestDataFactory.createSingleContact('CM1');
        Contact con2 = TestDataFactory.createSingleContact('CM2');
        Contact con3  = TestDataFactory.createSingleContact('CM3');
        Contact con4  = TestDataFactory.createSingleContact('CM4');
        Contact con5  = TestDataFactory.createSingleContact('CM4');
        
        List<Contact> conList = new List<Contact>();
        List<CampaignMember> cmList = new List<CampaignMember>();
        
        Test.startTest();
        try
        {
            for(integer x = 0 ;x<=50 ; x++)
            {
                Contact con = new Contact(FirstName = 'Sample'+x , LastName = 'Simplus', Email = 'none@testsimplus.com');
                conList.add(con);
                //  system.debug('contacts >>>>>>>>' +conList[x]);
            }
            
            insert conList;
            
            for(integer i = 0; i <=50 ; i++)
            {
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = c.Id;
                cm.Event_Allocation__c = al.Id;
                cm.RSVP_Status__c =  'Tentative' ; 
                cm.No_of_guests__c = 1; 
                cm.Status = 'Invited';
                cm.ContactId = conList[i].id;   
                cmList.add(cm);
            }
            insert cmList;
            
            system.debug('Campaign member list : ' +cmList);
            
            //Bulk Update RSVP Status
            for(integer j = 0 ; j<=10;j++)
            {   
                if(j<=10){
                    cmList[j].RSVP_Status__c = 'Attending';       
                    system.debug('Attendies ' +cmList[j].RSVP_Status__c );
                    
                }
                if(j>10 && j<=20)
                {
                    cmList[j].RSVP_Status__c = 'Waitlist'; 
                    system.debug('WAITLIST ' +cmList[j].RSVP_Status__c );
                }
            }            
            
            update cmList;
            system.debug('Campaign member list AFTER UPDATE >>>>>>>>>>>>>> : ' +cmList);
            
            List<CampaignMember> todelete  = new List<CampaignMember>();
            List<CampaignMember> todeleteWaitlist  = new List<CampaignMember>();
            
            //Delete Attendies
            for(integer j = 0 ; j<=10;j++)
            {
                todelete.add(cmList[j]);
            }   
            delete todelete;
            
            for(CampaignMember cm : cmList)
            {
                if(cm.RSVP_Status__c == 'Waitlist')
                {
                    todeleteWaitlist.add(cm);
                    
                    System.debug('TO BE DELETED : ' +todeleteWaitlist);
                    
                }
            }
            //Delete Waitlist
            System.debug('TO BE DELETED : ' +todeleteWaitlist);
            if(todeleteWaitlist!=null)
            {
                delete todeleteWaitlist;    
            }
            
            system.debug('Campaign Members >>> ' +cmList);
            system.debug('contacts >>>>>>>>' +conList);
            
            //Single Update
            CampaignMember cm1 = TestDataFactory.createCampaingMember(con1, Al,c,'Tentative',0);
            CampaignMember cm2 = TestDataFactory.createCampaingMember(con2, Al,c,'Tentative',1);
            CampaignMember cm3 = TestDataFactory.createCampaingMember(con3, Al,c,'Attending',1);
            CampaignMember cm4 = TestDataFactory.createCampaingMember(con4, Al,c,'Waitlist',1);
            CampaignMember cm5 = TestDataFactory.createCampaingMember(con5, Al,c,'Waitlist',1);
            
            cm5.RSVP_Status__c = 'Attending';
            update cm5;
            system.assertEquals('Attending', cm5.RSVP_Status__c);
            
            cm3.RSVP_Status__c ='Waitlist';
            update cm3;
            system.assertEquals('Waitlist', cm3.RSVP_Status__c);
            
            
            cm3.RSVP_Status__c = 'Attending';
            cm3.No_of_guests__c = 50;
            update cm3;
            
            //Delete Single record
            Delete cm4;
            
            
        }
        catch( Exception e)
        {
            System.Assert(e.getMessage().contains('We don’t have enough seat available, please reduce the number.'));
        }
        
        Test.stopTest();
        
    }
}