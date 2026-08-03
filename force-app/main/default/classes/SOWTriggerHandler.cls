/*
Author  : CapGemini
Date    : 21/01/2025
Modified: 10/07/2025 (Arth)
Reason  : This trigger stops the updates from the FormAssembly.

*/
public class SOWTriggerHandler {
    
    public static void handleBeforeUpdate(List<Source_of_Wealth__c> newList, List<Source_of_Wealth__c> oldList) {
        Map<Id, Source_of_Wealth__c> oldMap = new Map<Id, Source_of_Wealth__c>();
        for (Source_of_Wealth__c oldSOW : oldList) {
            oldMap.put(oldSOW.Id, oldSOW);
        }
        
        for (Source_of_Wealth__c newSOW : newList) {
            Source_of_Wealth__c oldSOW = oldMap.get(newSOW.Id);
            try {
                if (shouldRaiseException(newSOW, oldSOW)) {
                    newSOW.addError(System.Label.SOW_Form_Reinsert_Error);
                    System.debug('SOW TRIGGER FAILURE : Record already submitted cannot be updated from Form Assembly');
                    throw new SOW_Reinsert_Exception(System.Label.SOW_Form_Reinsert_Error+' = '+oldSOW.Id);
                }
            }catch (Exception e) {
                ErrorLogger.createLog('SOWTriggerHandler','handleBeforeUpdate',e,'','Apex Class'); 
            }
        }
    }
    
    private static Boolean shouldRaiseException(Source_of_Wealth__c newSOW, Source_of_Wealth__c oldSOW) {
        Boolean wasSubmitted = oldSOW.isSubmitted__c;
        Boolean isSubmitted = newSOW.isSubmitted__c;
        
        Boolean fileUploadedOld = oldSOW.fileuploaded_to_trackvia__c;
        Boolean fileUploadedNew = newSOW.fileuploaded_to_trackvia__c;
        
        // If already submitted and still submitted, and not just uploading a file to trackvia, raise error
        if (wasSubmitted && isSubmitted) {
            if (!(fileUploadedOld == false && fileUploadedNew == true)) {
                return true;
            }
        }
        return false;
    }
    
    public class SOW_Reinsert_Exception extends Exception {}
}