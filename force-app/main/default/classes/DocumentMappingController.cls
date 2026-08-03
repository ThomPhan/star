/**
* Class Name  : DocumentMappingController
* Summary     : Apex class to Generate URL when the User clicks on the documents.  
* @author     : Capgemini
* @Description: This class contains the logic for user provisioning in Salesforce
* @version    : Version 4 : 31/10/2025
**/
public with sharing class DocumentMappingController {

    @AuraEnabled
    public static Map<String, String> getDocumentUrlMap(Id recordId, List<String> documentNames, String WOState, String deleteDocu) {
        Map<String, String> urlMap = new Map<String, String>();

        if (recordId == null || documentNames == null || documentNames.isEmpty() || String.isBlank(WOState)) {
            throw new AuraHandledException('Missing Case Id, document names, or WOState.');
        }

        try {
            //delete existing file
            if(deleteDocu != NULL || deleteDocu != ''){
                List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id = :deleteDocu ORDER BY CreatedDate DESC];
                delete cd;
            }

            List<Exl_Exclusion__c> exclusions = [
                SELECT Id, Contact__c 
                FROM Exl_Exclusion__c 
                WHERE ApplyCase__c = :recordId 
                AND Jurisdiction__c = :WOState
                LIMIT 1
            ];

            if (exclusions.isEmpty()) {
                throw new AuraHandledException('No Exclusion record found for this Case and Jurisdiction.');
            }

            Exl_Exclusion__c exclusion = exclusions[0];

            if (exclusion.Contact__c == null) {
                throw new AuraHandledException('No Contact linked to the Exclusion.');
            }

            Id exclusionId = exclusion.Id;
            Id contactId = exclusion.Contact__c;

            Map<String, Exl_ExclusionDocumentMapping__mdt> allMappings = Exl_ExclusionDocumentMapping__mdt.getAll();

            Set<String> normalizedNames = new Set<String>();
            for (String name : documentNames) {
                normalizedNames.add(name.trim().toLowerCase());
            }

            for (Exl_ExclusionDocumentMapping__mdt mapping : allMappings.values()) {
                String label = mapping.Label != null ? mapping.Label.trim().toLowerCase() : '';
                String rawUrl = mapping.Form_Assembly_Workflow_URL__c;

                if (normalizedNames.contains(label) && String.isNotBlank(rawUrl)) {
                    String fullUrl = rawUrl
                        .replace('{exclusionId}', exclusionId)
                        .replace('{contactId}', contactId);

                    System.debug('Resolved URL for ' + mapping.Label + ': ' + fullUrl);
                    urlMap.put(mapping.Label, fullUrl);
                }
            }

            return urlMap;

        } catch (Exception e) {
            throw new AuraHandledException('Server error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateWorkOrderLineItemStatus(Id caseId, String WOState) {
        if (caseId == null) {
            throw new AuraHandledException('Missing Case Id.');
        }

        try {
            List<WorkOrder> workOrders = [
                SELECT Id 
                FROM WorkOrder 
                WHERE CaseId = :caseId AND Status != 'Completed' AND Jurisdiction__c = :WOState
                LIMIT 1
            ];

            if (workOrders.isEmpty()) {
                throw new AuraHandledException('No Work Order found for this Case.');
            }

            Id workOrderId = workOrders[0].Id;

            List<WorkOrderLineItem> itemsToUpdate = [
                SELECT Id, Status, WorkOrderId 
                FROM WorkOrderLineItem 
                WHERE WorkOrderId = :workOrderId
                AND Line_Item_Type__c = 'Generate Document'
                AND Status != 'Completed'
            ];

            for (WorkOrderLineItem item : itemsToUpdate) {
                item.Status = 'In Progress';
            }

            update itemsToUpdate;

        } catch (Exception e) {
            System.debug('Error updating WorkOrderLineItem status: ' + e.getMessage());
            throw new AuraHandledException('Failed to update WorkOrderLineItem status.');
        }
    }

    @AuraEnabled
    public static void completeWorkOrderLineItems(Id caseId, String WOState) {
        if (caseId == null) {
            throw new AuraHandledException('Missing Case Id.');
        }
        
        try {
            List<WorkOrder> workOrders = [
                SELECT Id 
                FROM WorkOrder 
                WHERE CaseId = :caseId AND Status != 'Completed' AND Jurisdiction__c = :WOState
                LIMIT 1
            ];
            
            if (workOrders.isEmpty()) {
                throw new AuraHandledException('No Work Order found for this Case.');
            }
            
            Id workOrderId = workOrders[0].Id;
            
            List<WorkOrderLineItem> itemsToUpdate = [
                SELECT Id, Status, WorkOrderId 
                FROM WorkOrderLineItem 
                WHERE WorkOrderId = :workOrderId
                AND Line_Item_Type__c = 'Generate Document'
                AND Status != 'Completed'
            ];
            
            for (WorkOrderLineItem item : itemsToUpdate) {
                item.Status = 'Completed';
            }
            
            update itemsToUpdate;
            
            if (!itemsToUpdate.isEmpty()) {
                Map<Id, Id> workOrderToCase = new Map<Id, Id>();
                workOrderToCase.put(workOrderId, caseId);
                WOLIStatusUpdater.updateCasesUsingNextButton(itemsToUpdate, workOrderToCase);
            }
            
        } catch (Exception e) {
            System.debug('Error completing WorkOrderLineItem status: ' + e.getMessage());
            throw new AuraHandledException('Failed to complete WorkOrderLineItem status.');
        }
    }
    
    @AuraEnabled
    public static string validateDuplicateDocument(Id caseId, String WOState, String documentName) {
        Id excluId;
        String hasDuplicate;
        if (caseId == null) {
            throw new AuraHandledException('Missing Case Id.');
        }

        try {
            excluId = [SELECT Id,Jurisdiction__c FROM Exl_Exclusion__c WHERE ApplyCase__c = :caseId AND Jurisdiction__c = :WOState].Id;
            for(ContentVersion cv : [SELECT Id, PathOnClient, Title, ContentDocumentId FROM ContentVersion  WHERE FirstPublishLocationId = :excluId] ){
                if(documentName == cv.Title){
                    hasDuplicate = cv.ContentDocumentId;
                    break;
                }
            }
            return hasDuplicate;

        } catch (Exception e) {
            System.debug('Error validateDuplicateDocument: ' + e.getMessage());
            throw new AuraHandledException('Error validateDuplicateDocument.');
        }
    }
}