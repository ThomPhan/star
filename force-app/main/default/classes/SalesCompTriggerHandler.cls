/**
 * @description       : Trigger handler class for SalesCompTrigger
 * @author            : Simplus
 * @group             : Simplus
 * @last modified on  : 22-08-2022
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   22-08-2022   Simplus                      Initial Version
 */
public class SalesCompTriggerHandler
extends TriggerHandlerBase //extending the trigger framework
{
    static final String APEXCLASSNAME = 'SalesCompTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';
    static final String SALES_COMP_RECORD_TYPE_NAME_CD_CP = 'CD_CP';
    static final String SALES_COMP_RECORD_TYPE_NAME_SPV_MPV = 'SPV_MPV';
    static final String SALES_COMP_RECORD_TYPE_NAME_GIFT = 'GIFT';
    static final String SALES_COMP_STATUS_APPROVED = 'Approved';
    static final String SALES_COMP_STATUS_DECLINED = 'Declined';
    static final String SALES_COMP_STATUS_VOIDED = 'Voided';
    static final String SALES_COMP_STATUS_INVALID = 'Invalid';
    static final String SALES_COMP_STATUS_PENDING = 'Pending';
    static final String INITIAL_APPROVAL_PROCESS = 'Sales_Comp_Approval_Process_1';
    static final String FINAL_APPROVAL_PROCESS = 'Sales_Comp_Approval_Process_2';
    static final String FINAL_APPROVER = 'Paul Monaghan';

    static Map<Id, RecordType> salesCompRecTypeMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Sales_Comp__c']);

    //new method which is required when we extend the TriggerHandlerBase class
    public SalesCompTriggerHandler(String triggerName) {
    	super(triggerName);
    }    
    
    //codes below are commented to follow trigger framework requirement. see replacement code in next blocks
    /*
    public static void beforeInsert(List<Sales_Comp__c> newSalesComp){
        updateSCFields(newSalesComp);
    }
    public static void beforeUpdate(List<Sales_Comp__c> newSalesComp, Map<Id, Sales_Comp__c> oldSalesCompMap){
        validateApprover(newSalesComp, oldSalesCompMap);
        populateJustification(newSalesComp);
        calloutApprovedComp(newSalesComp, oldSalesCompMap);
    }
	*/
    
    //overriden methods from trigger framework base class
    public override void beforeInsert(List<SObject> newSalesComp){
        updateSCFields(newSalesComp);
    }
    public override  void beforeUpdate(List<SObject> oldRecords, List<SObject> newSalesComp, Map<ID, SObject> oldSalesCompMap, Map<ID, SObject> newRecordMap){
        validateApprover(newSalesComp, (Map<Id, Sales_Comp__c>) oldSalesCompMap);
        populateJustification(newSalesComp);
        calloutApprovedComp(newSalesComp, (Map<Id, Sales_Comp__c>) oldSalesCompMap);
    }    
    
    public static void updateSCFields(List<Sales_Comp__c> newSalesComp){
        for(Sales_Comp__c salesCompObj : newSalesComp){
            salesCompObj.Status__c = 'Draft';
            if(salesCompRecTypeMap.get(salesCompObj.RecordTypeID).DeveloperName == SALES_COMP_RECORD_TYPE_NAME_SPV_MPV){
                salesCompObj.Adjustment_Type__c = 'add';
                salesCompObj.Reason_Code__c = 'N/A';
            }
            if(salesCompRecTypeMap.get(salesCompObj.RecordTypeID).DeveloperName == SALES_COMP_RECORD_TYPE_NAME_GIFT){
                /* CRM2-1974 - Start */
                // salesCompObj.Adjustment_Type__c = 'N/A';
                salesCompObj.Adjustment_Type__c = 'add';
                /* CRM2-1974 - End */
                salesCompObj.Reason_Code__c = 'N/A';
                /* CRM-2536 - Start */
                salesCompObj.Comp_Type__c = 'Gift';
                /* CRM-2536 - End */
                /* CRM2-2316  - Start */
                //salesCompObj.Property__c = 'N/A';
                /* CRM2-2316  - End */
            }
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers(String roleName, Boolean isRole){
        List<User> approverList = new List<User>();
        List<String> filterString = roleName.split('-');
        
        if(String.isNotBlank(roleName)){
            if(isRole){
                approverList = [SELECT Id, Name FROM User WHERE UserRole.Name =: filterString[0] AND isActive = TRUE ORDER BY Name];
            }else{
                approverList = [SELECT Id, Name FROM User WHERE Name =: filterString[0] AND isActive = TRUE ORDER BY Name];
            }
        }
        
        return approverList;
    }
    
    public static void populateJustification(List<Sales_Comp__c> newSalesCompList){
        Set<Id> salesCompIdSet = new Set<Id>();
        Map<Id, String> recordCommentMap = new Map<Id, String>();
        try{
            for(Sales_Comp__c salesCompObj : newSalesCompList){
                if(SALES_COMP_STATUS_APPROVED.equalsIgnoreCase(salesCompObj.Status__c) ||
                   SALES_COMP_STATUS_DECLINED.equalsIgnoreCase(salesCompObj.Status__c) ||
                   SALES_COMP_STATUS_PENDING.equalsIgnoreCase(salesCompObj.Status__c) ||
                   SALES_COMP_STATUS_VOIDED.equalsIgnoreCase(salesCompObj.Status__c)){
                       salesCompIdSet.add(salesCompObj.Id);
                }
            }
            
            if(!salesCompIdSet.isEmpty()){

                List<ProcessInstanceStep> currentApproval = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, Comments, ProcessInstance.CompletedDate, ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.LastModifiedDate
                                                        FROM ProcessInstanceStep 
                                                        WHERE ProcessInstance.TargetObjectId IN : salesCompIdSet ORDER BY CreatedDate DESC LIMIT 1];
                if(!currentApproval.isEmpty()){
                    recordCommentMap.put(currentApproval[0].ProcessInstance.TargetObjectId, currentApproval[0].Comments);
                }
                
                for(Sales_Comp__c salesCompRec : newSalesCompList){
                    salesCompRec.Justification__c = recordCommentMap.get(salesCompRec.Id);
                }
            }
        }catch(Exception e){
            ErrorLogger.createLog(APEXCLASSNAME, 'populateJustification', e, null, COMPONENTTYPE);
        }
    }
    
    public static void validateApprover(List<Sales_Comp__c> newSalesCompList, Map<Id, Sales_Comp__c> oldSalesCompMap){
        String approvalsString;
        Sales_Comp__c oldSalesComp = new Sales_Comp__c();
        String userApproversString = System.Label.Sales_Comp_Approvers_75000;
        Set<Id> salesCompIdSet = new Set<Id>();
        Map<Id, Id> salesCompIdApproverMap = new Map<Id, Id>();
        Map<Id, String> userIdRoleMap = new Map<Id, String>();

        String invalidSalesCompId = '';

        try{
            for(Sales_Comp__c salesCompObj : newSalesCompList){
                oldSalesComp = oldSalesCompMap.containsKey(salesCompObj.Id) ? oldSalesCompMap.get(salesCompObj.Id) : new Sales_Comp__c();
                if((SALES_COMP_STATUS_APPROVED.equalsIgnoreCase(salesCompObj.Status__c) && salesCompObj.isForVoid__c == oldSalesComp.isForVoid__c) ||
                   SALES_COMP_STATUS_DECLINED.equalsIgnoreCase(salesCompObj.Status__c) ||
                   SALES_COMP_STATUS_VOIDED.equalsIgnoreCase(salesCompObj.Status__c) ||
                   (SALES_COMP_STATUS_PENDING.equalsIgnoreCase(salesCompObj.Status__c) && oldSalesComp.Status__c != 'Draft') 
                   ){
                       salesCompIdSet.add(salesCompObj.Id);
                   }
            }
            List<ProcessInstanceStep> currentApproval = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, Comments, ProcessInstance.CompletedDate, ProcessInstance.LastActorId, StepStatus, ActorId,
                                                       ProcessInstance.LastActor.Name, ProcessInstance.LastModifiedDate, OriginalActorId
                                                       FROM ProcessInstanceStep 
                                                       WHERE ProcessInstance.TargetObjectId IN : salesCompIdSet ORDER BY CreatedDate DESC LIMIT 1];

            if(!currentApproval.isEmpty()){
                Id tempId = null;

                salesCompIdApproverMap.put(currentApproval[0].ProcessInstance.TargetObjectId, currentApproval[0].ActorId);
            
                for(User userObj : [SELECT Id, Name, UserRole.Name FROM User WHERE Id IN : salesCompIdApproverMap.values()]){
                    if(userApproversString.contains(userObj.Name)){
                        userIdRoleMap.put(userObj.Id, userObj.Name);
                    }else{
                        userIdRoleMap.put(userObj.Id, userObj.UserRole.Name);
                    }
                }

                for(Sales_Comp__c salesCompBuff : newSalesCompList){
                    oldSalesComp = oldSalesCompMap.containsKey(salesCompBuff.Id) ? oldSalesCompMap.get(salesCompBuff.Id) : new Sales_Comp__c();
                    if(salesCompBuff.Amount__c < 501){
                        approvalsString = System.Label.Sales_Comp_Approvers_500 + ',' +
                            System.Label.Sales_Comp_Approvers_1000 + ',' +
                            System.Label.Sales_Comp_Approvers_2000 + ',' +
                            System.Label.Sales_Comp_Approvers_5000 + ',' +
                            System.Label.Sales_Comp_Approvers_75000;
                    }else if(salesCompBuff.Amount__c < 1001){
                        approvalsString = System.Label.Sales_Comp_Approvers_1000 + ',' +
                            System.Label.Sales_Comp_Approvers_2000 + ',' +
                            System.Label.Sales_Comp_Approvers_5000 + ',' +
                            System.Label.Sales_Comp_Approvers_75000;
                    }else if(salesCompBuff.Amount__c < 2001){
                        approvalsString = System.Label.Sales_Comp_Approvers_2000 + ',' +
                            System.Label.Sales_Comp_Approvers_5000 + ',' +
                            System.Label.Sales_Comp_Approvers_75000;
                    }else if(salesCompBuff.Amount__c < 5001){
                        approvalsString = System.Label.Sales_Comp_Approvers_5000 + ',' +
                            System.Label.Sales_Comp_Approvers_75000;
                    }else if(salesCompBuff.Amount__c < 75001){
                        approvalsString = System.Label.Sales_Comp_Approvers_75000;
                    }

                    if(!approvalsString.contains(userIdRoleMap.get(salesCompIdApproverMap.get(salesCompBuff.Id)))){
                        salesCompBuff.Status__c = SALES_COMP_STATUS_INVALID;
                        invalidSalesCompId = salesCompBuff.Id;
                    }
                    else{ //If 1st Approval and only for add adjustment type, is done and not invalid, send to next approval
                        if(currentApproval[0].ProcessInstance.LastActor.Name != FINAL_APPROVER && SALES_COMP_STATUS_APPROVED.equalsIgnoreCase(salesCompBuff.Status__c) 
                           && salesCompBuff.Adjustment_Type__c != 'deduct'){
                            salesCompBuff.Status__c = SALES_COMP_STATUS_PENDING; //Set Status to Approval, other methods will also be checked as Status = Pending
                            sendForSecondApproval(salesCompBuff.Id, null, FINAL_APPROVAL_PROCESS);
                        }
                    }
                }

                if (!String.isEmpty(invalidSalesCompId)) {
                    sendEmailToInvalidComp(invalidSalesCompId);
                }
            }
        }catch(Exception e){
            ErrorLogger.createLog(APEXCLASSNAME, 'validateApprover', e, null, COMPONENTTYPE);
        }
    }

    public static void sendEmailToInvalidComp(String invalidSalesCompId) {
        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();

        Sales_Comp__c sc = [SELECT Id, Contact__c, Owner.Name, Owner.Email FROM Sales_Comp__c WHERE Id = :invalidSalesCompId];
        msg.setTargetObjectId(sc.Contact__c);
        msg.setWhatId(sc.Id);
        msg.setToAddresses(new List<String>{ sc.Owner.Email });

        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Sales_Comp_Invalid_Approver_Email_Template'];
        msg.setTemplateId(et.Id);

        msg.setSenderDisplayName('The Star Entertainment Group');
        msg.setTreatTargetObjectAsRecipient(false);
        msg.setSaveAsActivity(false);

        msgs.add(msg);
        Messaging.sendEmail(msgs);
    }

    public static void calloutApprovedComp(List<Sales_Comp__c> newSalesCompList, Map<Id, Sales_Comp__c> oldSalesCompMap){
        Set<Id> salesCompIdSet = new Set<Id>();
        
        try{
            for(Sales_Comp__c salesComp : newSalesCompList){
                String salesCompRT = salesCompRecTypeMap.get(salesComp.RecordTypeID).DeveloperName;
                if((SALES_COMP_STATUS_APPROVED.equalsIgnoreCase(salesComp.Status__c) || SALES_COMP_STATUS_VOIDED.equalsIgnoreCase(salesComp.Status__c)) && 
                   salesComp.Status__c != oldSalesCompMap.get(salesComp.Id).Status__c && 
                   salesCompRT == SALES_COMP_RECORD_TYPE_NAME_CD_CP){
                       salesCompIdSet.add(salesComp.Id);
                   }
            }
            
            if(!salesCompIdSet.isEmpty()){
                doCallout(salesCompIdSet);
            }
        }catch (Exception e){
            ErrorLogger.createLog(APEXCLASSNAME, 'calloutApprovedComp', e, null, COMPONENTTYPE);
        }
    }
    
    @future(callout=true)
    public static void doCallout(Set<Id> salesCompIdSet){
        Sales_Comp_Setting__mdt salesCompMdt = Sales_Comp_Setting__mdt.getInstance('Sales_Comp');

        Sales_Comp__c salesComp = new Sales_Comp__c();
        
        try{
            salesComp = [SELECT Id, Contact__c, Status__c, Comp_Type__c, Description__c, Property__c, Amount__c, Adjustment_Type__c,
                                       Reason_Code__c, CreatedById, CreatedBy.Name, Justification__c, Contact__r.Patron_ID__c, Comments__c 
                                       FROM Sales_Comp__c 
                                       WHERE Id IN : salesCompIdSet LIMIT 1];
            
            Boolean isVoid = SALES_COMP_STATUS_APPROVED.equalsIgnoreCase(salesComp.Status__c) ? TRUE : FALSE;
            
            List<ProcessInstanceStep> currentApproval = [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.Status, Comments, ProcessInstance.CompletedDate, 
                                                         ProcessInstance.LastActorId, ProcessInstance.LastModifiedDate, ProcessInstance.SubmittedById
                                                         FROM ProcessInstanceStep 
                                                         WHERE ProcessInstance.TargetObjectId =: salesComp.Id ORDER BY CreatedDate DESC LIMIT 1];
            
            User approverUser = [SELECT Id, Name FROM User WHERE Id =: currentApproval[0].ProcessInstance.LastActorId];
            User submittedUser = [SELECT Id, Name FROM User WHERE Id =: currentApproval[0].ProcessInstance.SubmittedById];
            
            SalesCompDataProvider.SalesCompJSON scJson = new SalesCompDataProvider.SalesCompJSON();
            scJson.userId = salesComp.CreatedBy.Name;
            scJson.source = 'Salesforce';
            scJson.host = String.valueOf(URL.getSalesforceBaseUrl().toExternalForm());
            scJson.contextId = salesComp.Id;
            scJson.patronId = salesComp.Contact__r.Patron_ID__c;
            scJson.reasonCode = salesComp.Reason_Code__c;
            scjson.staffUser = submittedUser.Name;
            scJson.approverNotes = String.isBlank(salesComp.Justification__c) ? 'N/A' : salesComp.Justification__c;
            scjson.originalTransactionId = salesComp.Id;
            scJson.pointValue = String.valueOf(salesComp.Amount__c);
            scJson.pointTypeIndicator = salesComp.Comp_Type__c;
            scJson.pointValueType = salesComp.Adjustment_Type__c;
            scJson.propertyId = salesComp.Property__c;
            scJson.approverUserId = approverUser.Name;
            scJson.reasonDescription = salesComp.Description__c;
            scJson.comments = salesComp.Comments__c;

            String jsonBody = json.serialize(scJson);
            
            Httprequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(salesCompMdt.Sales_Comp_URL__c);
            req.setHeader('customer-subscription-key', salesCompMdt.Sales_Comp_Sub_Key__c);
            req.setBody(jsonBody);

            Http http = new Http();        
            HttpResponse response = http.send(req);
            System.debug(response.getBody());
            System.debug('Status Code: ' + response.getStatusCode());
			
            if(response.getStatusCode() != 200){
                ErrorLogger.createLog(APEXCLASSNAME, response.getStatusCode() + ' ' + response.getStatus(), null, salesComp.Id, COMPONENTTYPE);
            }
            
        }catch(Exception e){
            ErrorLogger.createLog(APEXCLASSNAME, 'doCallout', e, salesComp.Id, COMPONENTTYPE);
        }
    }

    @future
    public static void sendForSecondApproval(Id checklistId, Id approverId, String approvalProcessName){

        List<ProcessInstanceStep> initialApproval = [SELECT Id, ProcessInstance.ProcessDefinition.DeveloperName, OriginalActor.Id
                                                       FROM ProcessInstanceStep 
                                                       WHERE ProcessInstance.TargetObjectId =: checklistId AND ProcessInstance.ProcessDefinition.DeveloperName =: INITIAL_APPROVAL_PROCESS AND (ProcessInstance.Status = 'Approved' OR ProcessInstance.Status = 'Pending')  ORDER BY CreatedDate ASC LIMIT 1];

        try{
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(checklistId);
            req1.setProcessDefinitionNameOrId(approvalProcessName);
            req1.setNextApproverIds(new List<Id>{approverId});
            req1.setSkipEntryCriteria(false);
            req1.setSubmitterId(initialApproval[0].OriginalActor.Id);
            Approval.ProcessResult result = Approval.process(req1);
        }
        catch (Exception e){
            ErrorLogger.createLog(APEXCLASSNAME, 'sendForSecondApproval', e, null, COMPONENTTYPE);
        }
    }
}