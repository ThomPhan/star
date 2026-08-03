public class GetQuestionnaireMdt {
	private final INT_Residency_Checklist_Question__mdt INTQuestions;
    private final DOM_Residency_Checklist_Question__mdt DOMQuestions;

    ProcessNode procNode;
    
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public GetQuestionnaireMdt(ApexPages.StandardController stdController) {
        this.INTQuestions = [SELECT Id, PartA_Q1__c, PartA_Q2__c, PartA_Q3__c, PartA_Q4__c, PartA_Q5__c, PartA_Q6__c, PartB_Q10__c, PartB_Q11__c, PartB_Q12__c, 
            PartB_Q13__c, PartB_Q14__c, PartB_Q7__c, PartB_Q8__c, PartB_Q9__c, PartC_Q15__c, PartC_Q16__c, PartC_Q17__c, PartC_Q18__c, PartC_Q19__c, PartC_Q20__c, 
            PartC_Q21__c, PartC_Q22__c, PartA_Q6_CB1__c, PartA_Q6_CB2__c, PartA_Q6_CB3__c, PartC_Q17_CB1__c, PartC_Q17_CB2__c, PartC_Q17_CB3__c, PartA_Q1_CB__c, 
            PartA_Q2_CB__c FROM INT_Residency_Checklist_Question__mdt];
        
        this.DOMQuestions = [SELECT Id, Q10__c, Q11__c, Q12__c, Q1__c, Q2__c, Q3__c, Q4__c, Q5__c, Q6__c, Q7__c, Q8__c, Q9__c, Q4_CB1__c, Q4_CB2__c, Q4_CB3__c, 
                             Q4_CB4__c, Q4_CB5__c, Q5_CB__c, Q4_CB6__c, Q2_CB__c FROM DOM_Residency_Checklist_Question__mdt];

        procNode = [SELECT Id FROM ProcessNode WHERE DeveloperName = 'Premium_Ops_Manager' AND ProcessDefinition.TableEnumOrId = 'Residency_Checklist__c' LIMIT 1];
    }

    public INT_Residency_Checklist_Question__mdt getQuestionInt() {
        return INTQuestions;
    }
    
    public DOM_Residency_Checklist_Question__mdt getQuestionDom() {
        return DOMQuestions;
    }
    
    public ProcessInstanceStep getApprovalStatus(){
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        
        ProcessInstanceStep currentApproval = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, Comments, ProcessInstance.CompletedDate, ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.LastModifiedDate
                                           FROM ProcessInstanceStep 
                                           WHERE ProcessInstance.TargetObjectId =: recordId AND StepNodeId =: procNode.Id AND StepStatus = 'Approved' ORDER BY CreatedDate DESC LIMIT 1];
        
        return currentApproval;
    }
    
    public String getApprovalDate(){
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        
        ProcessInstanceStep currentApproval = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, ProcessInstance.CompletedDate, ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.LastModifiedDate
                                           FROM ProcessInstanceStep 
                                           WHERE ProcessInstance.TargetObjectId =: recordId AND StepNodeId =: procNode.Id AND StepStatus = 'Approved' ORDER BY CreatedDate DESC LIMIT 1];
        Date approvedDate = Date.valueOf(currentApproval.ProcessInstance.LastModifiedDate);
        String stringDate = String.valueOf(approvedDate.day()) + '/' + String.valueOf(approvedDate.month() + '/' + String.valueOf(approvedDate.year()));
        return stringDate;
    }

    public ProcessInstanceStep getCompletedBy(){

        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        ProcessInstanceStep currentSubmitter = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, ProcessInstance.CompletedDate, OriginalActor.Name,
                                                ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.LastModifiedDate
                                           FROM ProcessInstanceStep 
                                           WHERE ProcessInstance.TargetObjectId =: recordId AND StepStatus = 'Started' ORDER BY CreatedDate DESC LIMIT 1];

        return currentSubmitter;
    }

    public String getCompletedByDate(){
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');

        ProcessInstanceStep currentSubmitter = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, ProcessInstance.CompletedDate, ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.CreatedDate
                                           FROM ProcessInstanceStep 
                                           WHERE ProcessInstance.TargetObjectId =: recordId AND StepStatus = 'Started' ORDER BY CreatedDate DESC LIMIT 1];
        Date approvedDate = Date.valueOf(currentSubmitter.ProcessInstance.CreatedDate);
        String stringDate = String.valueOf(approvedDate.day()) + '/' + String.valueOf(approvedDate.month() + '/' + String.valueOf(approvedDate.year()));
        return stringDate;
    }
    
    public Boolean getContactType(){
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        Boolean isInternational = TRUE;
        
        Residency_Checklist__c rcRecord = [SELECT Id, Trip__r.Type__c FROM Residency_Checklist__c WHERE Id =: recordId];
        if(rcRecord.Trip__r.Type__c.equalsIgnoreCase('Domestic')){
            isInternational = FALSE;
        }
        return isInternational;
    }
    
    public String getProgramCode(){
        
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        String programText = '';
        
        Residency_Checklist__c rcRecord = [SELECT Id, Program__c, Program__r.Program_ID__c, Program__r.Program_Code__c, Program_Text__c FROM Residency_Checklist__c WHERE Id =: recordId];
        if(rcRecord.Program__c != null){
            programText = rcRecord.Program__r.Program_ID__c;
        }
        else{
            programText = rcRecord.Program_Text__c;
        }
        
        return programText;
    }

    public Integer getDuration(){
        
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        Integer duration = 0;

        Residency_Checklist__c rcRecord = [SELECT Id, Trip__r.Trip_Duration__c, Trip__r.Contact__r.Total_Days_International_Patron__c, Trip__r.Contact__r.Total_NSW_Days__c, Trip__r.Contact__r.Total_QLD_Days__c, Trip__r.Contact__r.Residency_Type__c, Trip__r.Entry_State__c FROM Residency_Checklist__c WHERE Id =: recordId];

        if(rcRecord.Trip__r.Contact__r.Residency_Type__c == 'International'){
            duration = Integer.valueOf(rcRecord.Trip__r.Contact__r.Total_Days_International_Patron__c) - Integer.valueOf(rcRecord.Trip__r.Trip_Duration__c);
        }
        else{
            if(rcRecord.Trip__r.Entry_State__c == 'NSW'){
                duration = Integer.valueOf(rcRecord.Trip__r.Contact__r.Total_NSW_Days__c) - Integer.valueOf(rcRecord.Trip__r.Trip_Duration__c);
                if(duration < 0){
                    duration = 0;
                }
            }
            else{
                duration = Integer.valueOf(rcRecord.Trip__r.Contact__r.Total_QLD_Days__c) - Integer.valueOf(rcRecord.Trip__r.Trip_Duration__c);
                if(duration < 0){
                    duration = 0;
                }
            }
        }

        return duration;
    }
    
    public String getDevice() {
        String extension;
        Boolean isMobile = UserInfo.getUiTheme() == 'Theme4t';
        
        if(isMobile){
            extension = 'html';
        }else{
            extension = 'pdf';
        }
        
        return extension;
    }
}