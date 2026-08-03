/*
* Name: ResidencyChecklistTriggerHandler
* Description: Trigger Handler Class for Residency Checklist Object
* Author: Simplus
* 
*/
public class ResidencyChecklistTriggerHandler 
extends TriggerHandlerBase //extending the trigger framework
{
    
    static final String APEXCLASSNAME = 'ResidencyChecklistTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';

    public static Boolean runOnce = false;

    //new method which is required when we extend the TriggerHandlerBase class
    public ResidencyChecklistTriggerHandler(String triggerName) {
    	super(triggerName);
    }
    
    public override  void beforeUpdate(List<SObject> oldRecords, List<SObject> newResRec, Map<ID, SObject> oldResRecMap, Map<ID, SObject> newResRecMap){
        
        copyCommentFromApproval((Map<Id, Residency_Checklist__c>)newResRecMap, (Map<Id, Residency_Checklist__c>) oldResRecMap);
    }   
    
    public static void copyCommentFromApproval(Map<Id, Residency_Checklist__c> newResRecMap, Map<Id, Residency_Checklist__c> oldResRecMap){
        
        Set<Id> resRecIdSet = new Set<Id>();
        
        if(!runOnce){
            
            for(Residency_Checklist__c resRec : newResRecMap.values()){
                
                if(resRec.Approval_Status__c == 'Approved' && resRec.Copy_Comments_From_Approval__c == true && resRec.Copy_Comments_From_Approval__c != oldResRecMap.get(resRec.Id).Copy_Comments_From_Approval__c){
                    
                    resRecIdSet.add(resRec.Id);
                }
            }
        }
        
        if(!resRecIdSet.isEmpty()){
            
            Map<Id, Residency_Checklist__c> tempResMap = new Map<Id, Residency_Checklist__c>();
            Set<Id> tempIdSet = new Set<Id>();
            
            List<ProcessInstanceStep> approvalList = [SELECT Id, ProcessInstance.TargetObjectId, Comments, StepStatus FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId IN: resRecIdSet AND StepStatus = 'Approved' ORDER BY CreatedDate DESC];
            
            System.debug(approvalList);
            
            if(!approvalList.isEmpty()){
                
                for(ProcessInstanceStep approvalRec : approvalList){
                    
                    if(newResRecMap.containsKey(approvalRec.ProcessInstance.TargetObjectId)){
                        
                        if(approvalRec.Comments != null){
                            
                            //Check if the specific record has already been set with the Comment
                            if(!tempIdSet.contains(approvalRec.ProcessInstance.TargetObjectId)){
                                
                                if(approvalRec.Comments.length() > 300){
                                    newResRecMap.get(approvalRec.ProcessInstance.TargetObjectId).Justification__c = approvalRec.Comments.substring(0,300);
                                }
                                else{
                                	newResRecMap.get(approvalRec.ProcessInstance.TargetObjectId).Justification__c = approvalRec.Comments;
                                }
                                newResRecMap.get(approvalRec.ProcessInstance.TargetObjectId).Copy_Comments_From_Approval__c = false;
                                runOnce = true;
                                tempIdSet.add(approvalRec.ProcessInstance.TargetObjectId);
                            }
                        }
                    }
                }
            }
        }
    }
}