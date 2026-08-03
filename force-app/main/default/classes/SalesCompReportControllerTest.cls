@isTest
public class SalesCompReportControllerTest{
    
    @isTest
    static void testSowUpdate(){

        Contact c = new Contact();
        c.FirstName = 'Test FName';
        c.LastName = 'Test LName';
        insert c;

        RecordType scRT = [SELECT Id FROM RecordType WHERE SobjectType ='sales_Comp__c' AND DeveloperName = 'SPV_MPV'];

        Sales_Comp__c sc = new Sales_Comp__c();
        sc.RecordTypeId = scRT.Id;
        insert sc;

        SalesCompReportController.getSalesCompWithApprovalHistory();
        SalesCompReportController.getSalesCompWithApprovalHistoryFiltered('a');
    }
}