@isTest
public class GetQuestionnaireMdtTest {
    
    @testSetup
    static void TestDataFactory(){
        Contact testContact = TestDataFactory.createSingleContact('TestClass');
    }

    static testmethod void printableViewTest(){

        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Date dateToday = System.today();
        List<Trip__c> tripList = new List<Trip__c>();
    
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        tripList.add(firstTrip);

        insert tripList;

        Residency_Checklist__c res = new Residency_Checklist__c();
        res.Trip__c = tripList[0].Id;

        insert res;

        Test.StartTest(); 

            ApexPages.StandardController sc = new ApexPages.StandardController(res);
			GetQuestionnaireMdt questionnaireMDT = new GetQuestionnaireMdt(sc);
			questionnaireMDT.getQuestionInt();
			questionnaireMDT.getQuestionDom();

		Test.StopTest();
    }

    static testmethod void printableViewTest2(){

        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Date dateToday = System.today();
        List<Trip__c> tripList = new List<Trip__c>();
    
        Trip__c firstTrip = new Trip__c();
        firstTrip.Contact__c = testContact.Id;
        firstTrip.Entry_State__c = 'NSW';
        firstTrip.Entry_Date__c = dateToday;
        firstTrip.Exit_Date__c = dateToday.addDays(7);
        firstTrip.Cancelled__c = FALSE;
        firstTrip.is_within_365_days__c = TRUE;
        
        tripList.add(firstTrip);

        insert tripList;

        Residency_Checklist__c res = new Residency_Checklist__c();
        res.Trip__c = tripList[0].Id;

        insert res;

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(res.Id);
        req1.setNextApproverIds(new List<Id>{UserInfo.getUserId()});
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);

        Approval.ProcessWorkitemRequest req =
        new Approval.ProcessWorkitemRequest();
        req.setComments('Approving request.');
        req.setAction('Approve');
        
        ProcessInstanceWorkitem pItem = [Select Id from ProcessInstanceWorkitem  where ProcessInstance.TargetObjectId =: res.id];
       	
        req.setWorkitemId(pItem.Id);

        Approval.ProcessResult result2 = Approval.process(req);

        Test.StartTest(); 
            PageReference resPrintableView = Page.ResidencyPrintableView;
            Test.setCurrentPage(resPrintableView);
            
            ApexPages.currentPage().getParameters().put('id',res.Id);

            ApexPages.StandardController sc = new ApexPages.StandardController(res);
			GetQuestionnaireMdt questionnaireMDT = new GetQuestionnaireMdt(sc);
            questionnaireMDT.getApprovalStatus();
			questionnaireMDT.getApprovalDate();
			questionnaireMDT.getCompletedBy();
            questionnaireMDT.getCompletedByDate();
            questionnaireMDT.getContactType();
            questionnaireMDT.getProgramCode();
            questionnaireMDT.getDuration();

		Test.StopTest();
    }
}