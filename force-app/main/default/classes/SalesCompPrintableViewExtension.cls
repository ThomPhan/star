/**
 * @description       : Controller extension for SalesCompPrintableView VFP
 * @author            : Simplus
 * @group             : Simplus
 * @last modified on  : 22-08-2022
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   22-08-2022   Simplus                      Initial Version
 */
public class SalesCompPrintableViewExtension {
    public Id recordId;
    public Sales_Comp__c salesComp;
    public ApprovalWrapper wrapper { get; set; }

    public class ApprovalWrapper {
        public String submitterName { get; set; }
        public String submissionDate { get; set; }
        public String authoriserName { get; set; }
        public String approvalDate { get; set; }
    }

    ApexPages.StandardController controller;
    public SalesCompPrintableViewExtension(ApexPages.StandardController stdController) {
        recordId = ApexPages.currentPage().getParameters().get('id');

        controller = stdController;
        salesComp = (Sales_Comp__c) controller.getRecord();

        wrapper = new ApprovalWrapper();
        getApprovalDetails();
    }

    public Boolean getRecordType() {
        Sales_Comp__c scRecord = [SELECT Id, RecordType.Name FROM Sales_Comp__c WHERE Id = :recordId];
        return (scRecord.RecordType.Name == 'CD/CP');
    }

    public Boolean getRecordStatus() {
        return (salesComp.Status__c == 'Approved');
    }

    public void getApprovalDetails() {
        List<ProcessInstanceStep> steps = [SELECT Id, CreatedBy.Name, CreatedDate, ProcessInstance.Status, ProcessInstance.LastActor.Name, ProcessInstance.CompletedDate, StepStatus
                                           FROM ProcessInstanceStep
                                           WHERE ProcessInstance.TargetObjectId = :recordId
                                           ORDER BY CreatedDate ASC];
        if (steps.size() > 0) {
            Integer lastIndex = steps.size() - 1;
            ProcessInstanceStep latestStep = steps[lastIndex];

            if (latestStep.StepStatus == 'Approved') {
                // Submitter - (last in sorted order) record with StepStatus = Started
                for (ProcessInstanceStep step: steps) {
                    if (step.StepStatus == 'Started') {
                        wrapper.submitterName = step.CreatedBy.Name;
                        wrapper.submissionDate = step.CreatedDate.format('dd/MM/yyyy', + 'Australia/Sydney');
                        break;
                    }
                }
                // Authoriser - latest record
                wrapper.authoriserName = latestStep.CreatedBy.Name;
                wrapper.approvalDate = latestStep.CreatedDate.format('dd/MM/yyyy', + 'Australia/Sydney');
            } else if (latestStep.StepStatus == 'Started') {
                // Submitter - original submitter
                for (ProcessInstanceStep step: steps) {
                    if (step.StepStatus == 'Started' && step.StepStatus != 'Rejected') {
                        wrapper.submitterName = step.CreatedBy.Name;
                        wrapper.submissionDate = step.CreatedDate.format('dd/MM/yyyy', + 'Australia/Sydney');
                        break;
                    }
                }
                // Authoriser - null
            } else {
                // Submitter - (last in sorted order) record with StepStatus = Started
                for (ProcessInstanceStep step: steps) {
                    if (step.StepStatus == 'Started') {
                        wrapper.submitterName = step.CreatedBy.Name;
                        wrapper.submissionDate = step.CreatedDate.format('dd/MM/yyyy', + 'Australia/Sydney');
                    }
                }
                // Authoriser - null
            }
        }
    }

    public Boolean getSubmitterName() {
        return (wrapper.submitterName != null);
    }

    public Boolean getAuthoriserName() {
        return (wrapper.authoriserName != null);
    }

    public String getDevice() {
        return (UserInfo.getUiTheme() == 'Theme4t') ? 'html' : 'pdf' ;
    }
}