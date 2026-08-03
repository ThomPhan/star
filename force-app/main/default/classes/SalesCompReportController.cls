public class SalesCompReportController {
    
    @AuraEnabled(cacheable=true)
    public static List<Sales_Comp__c> getSalesCompWithApprovalHistory() {
        return [SELECT Id, Name, Adjustment_Type__c, Owner.Name, Comp_Type__c, Contact__r.Tier__c, Contact__r.Loyalty_Program__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Patron_ID__c, 
                Amount__c, Status__c, Property__c, Description__c, Comments__c, Additional_Comments__c, CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate, 
                (SELECT Id, TargetObjectId, StepStatus, Comments, ProcessInstance.LastActor.Name, ProcessInstance.SubmittedBy.Name FROM ProcessSteps) FROM Sales_Comp__c WHERE Contact__c != null];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Sales_Comp__c> getSalesCompWithApprovalHistoryFiltered(String keyValue) {
        keyValue = '%' + keyValue + '%';
        return [SELECT Id, Name, Adjustment_Type__c, Owner.Name, Comp_Type__c, Contact__r.Tier__c, Contact__r.Loyalty_Program__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Patron_ID__c, 
                Amount__c, Status__c, Property__c, Description__c, Comments__c, Additional_Comments__c, CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate, 
                (SELECT Id, TargetObjectId, StepStatus, Comments, ProcessInstance.LastActor.Name, ProcessInstance.SubmittedBy.Name 
                 FROM ProcessSteps) 
                FROM Sales_Comp__c 
                Where Contact__c != null AND (Contact__r.Patron_ID__c LIKE :keyValue 
                OR Comp_Type__c LIKE :keyValue 
                OR Status__c LIKE :keyValue 
                OR Property__c LIKE :keyValue
                OR Owner.Name LIKE :keyValue)];
    }
}