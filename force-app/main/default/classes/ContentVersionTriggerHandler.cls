/**
* @File Name : ContentVersionTriggerHandler
* @Description : Helper Class
* @Author : Arth Sharma (Capgemini Contigent)
* @Last Modified By :
* @Last Modified On : Aug 01, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Aug 01, 2025 |   | Initial Version
**/

public class ContentVersionTriggerHandler extends TriggerHandlerBase {
    private static Boolean hasRun = false;
    
    public ContentVersionTriggerHandler(String triggerName) {
        super(triggerName);
    }
    
    // Before Insert
    public override void beforeInsert(List<SObject> newRecords) {
        handleFileUpload(newRecords);
    }
    
    // Before Update
    public override void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
    }
    
    // After Insert
    public override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
    }
    
    // After Update
    public override void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap) {
    }
	
    // Helper Methods
    public static void handleFileUpload(List<SObject> records) {
        Schema.SObjectType sType = ContentVersion.SObjectType;
        FileUploadService.ensureSettings();
        FileUploadService.validateManualUpload(records, sType);
        FileUploadService.validateFileType(records, sType);
    }
}