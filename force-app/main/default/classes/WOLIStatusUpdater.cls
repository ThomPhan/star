/**
* Class Name  : WorkOrderLineItem Status Update
* Summary     : Apex class to update the Status of WorkOrderLineItem to Completed when all the Documents are inserted.  
* @author     : Capgemini
* @Description: This class contains the logic for user provisioning in Salesforce
* @version    : Version 3 : 22/10/2025
**/
public with sharing class WOLIStatusUpdater {
    
    public static void updateWOLIStatusBasedOnDocuments(Set<Id> exclusionIds) {
        system.debug('First:: Inside updateWOLIStatusBasedOnDocuments');
        if (exclusionIds == null || exclusionIds.isEmpty()) return;
        List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
        
        List<ContentDocumentLink> allLinks = [
            SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :exclusionIds
        ];

        Map<Id, Set<String>> exclusionToTitles = new Map<Id, Set<String>>();
        for (ContentDocumentLink link : allLinks) {
            if (link.ContentDocument.Title != null) {
                Id exclusionId = link.LinkedEntityId;
                if (!exclusionToTitles.containsKey(exclusionId)) {
                    exclusionToTitles.put(exclusionId, new Set<String>());
                }
                exclusionToTitles.get(exclusionId).add(link.ContentDocument.Title.trim().toLowerCase());
            }
        }
        
        List<Exl_Exclusion__c> exclusions = [
            SELECT Id, ApplyCase__c, Jurisdiction__c
            FROM Exl_Exclusion__c
            WHERE Id IN :exclusionIds
        ];
        
        Map<Id, Exl_Exclusion__c> caseToExclusion = new Map<Id, Exl_Exclusion__c>();
        for (Exl_Exclusion__c exc : exclusions) {
            if (exc.ApplyCase__c != null) {
                caseToExclusion.put(exc.ApplyCase__c, exc);
            }
        }

        List<WorkOrder> workOrders = [
            SELECT Id, CaseId, Jurisdiction__c
            FROM WorkOrder
            WHERE CaseId IN :caseToExclusion.keySet()
            AND Status != 'Completed' AND Jurisdiction__c != null
        ];
        
        Map<Id, Id> workOrderToCase = new Map<Id, Id>();
        for (WorkOrder wo : workOrders) {
            if (!caseToExclusion.containsKey(wo.CaseId)) {
                continue;
            }
            if (caseToExclusion.get(wo.CaseId).Jurisdiction__c != null &&
                caseToExclusion.get(wo.CaseId).Jurisdiction__c == wo.Jurisdiction__c) {
                workOrderToCase.put(wo.Id, wo.CaseId);
            }
        }
        
        List<WorkOrderLineItem> wolis = [
            SELECT Id, WorkOrderId, Documents_to_be_generated__c, Status
            FROM WorkOrderLineItem
            WHERE WorkOrderId IN :workOrderToCase.keySet()
            AND Line_Item_Type__c = 'Generate Document'
            AND Status != 'Completed'
        ];

        for (WorkOrderLineItem woli : wolis) {
            Id woId = woli.WorkOrderId;
            if (woId != null && workOrderToCase.containsKey(woId)) {
                Id excId = caseToExclusion.get(workOrderToCase.get(woId)).Id;
                if (exclusionToTitles.containsKey(excId)) {
                    Set<String> actualDocs = exclusionToTitles.get(excId);
                    Set<String> expectedDocs = new Set<String>();
                    
                    String rawDocs = woli.Documents_to_be_generated__c;
                    if (rawDocs != null) {
                        List<String> expectedList = rawDocs.split(';');
                        for (String doc : expectedList) {
                            String cleanDoc = doc.trim().toLowerCase();
                            if (String.isNotBlank(cleanDoc)) {
                                expectedDocs.add(cleanDoc);
                            }
                        }
                        system.debug('Second:: Inside updateWOLIStatusBasedOnDocuments:: ');
                        system.debug('actualDocs:: Inside updateWOLIStatusBasedOnDocuments:: '+actualDocs);
                        system.debug('expectedDocs:: Inside updateWOLIStatusBasedOnDocuments:: '+expectedDocs);
                        if (actualDocs != null && !expectedDocs.isEmpty() && actualDocs.containsAll(expectedDocs)) {
                            woli.Status = 'Completed';
                            wolisToUpdate.add(woli);
                        }
                    }
                }
            }
        }

        if (!wolisToUpdate.isEmpty()) {
            update wolisToUpdate;
            System.debug('@@wolisToUpdate: ' + wolisToUpdate);
            updateCasesUsingNextButton(wolisToUpdate, workOrderToCase);
        }
    }

    public static void updateCasesUsingNextButton(List<WorkOrderLineItem> wolisToUpdate, Map<Id, Id> workOrderToCase) {
        List<Case> casesToUpdate = new List<Case>();

        for (WorkOrderLineItem updatedWOLI : wolisToUpdate) {
            Id woId = updatedWOLI.WorkOrderId;
            Id caseId = workOrderToCase.containsKey(woId) ? workOrderToCase.get(woId) : null;

            if (caseId != null) {
                ExlNextButtonUtil.FlowInputWrapper input = new ExlNextButtonUtil.FlowInputWrapper();
                input.caseId = caseId;
                input.wOLIId = updatedWOLI.Id;

                List<ExlNextButtonUtil.FlowOutputWrapper> results =
                    ExlNextButtonUtil.updateCaseAndReturn(new List<ExlNextButtonUtil.FlowInputWrapper>{ input });

                if (!results.isEmpty()) {
                    ExlNextButtonUtil.FlowOutputWrapper result = results[0];

                    Case caseToUpdate = new Case(Id = caseId);
                    if (result.nextNSW != null) {
                        caseToUpdate.Exl_Nextbutton_NSW__c = result.nextNSW;
                    }
                    if (result.nextQLD != null) {
                        caseToUpdate.Exl_Nextbutton_Qld__c = result.nextQLD;
                    }
                    if (result.caseClosed) {
                        caseToUpdate.Status = 'Closed';
                    }
                    casesToUpdate.add(caseToUpdate);
                }
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
            System.debug('@@casesToUpdate: ' + casesToUpdate);
        }
    }
}