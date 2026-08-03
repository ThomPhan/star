/**
* @File Name : FileUploadService
* @Description : Service Class
* @Author : Arth Sharma (Capgemini Contigent)
* @Last Modified By :
* @Last Modified On : Aug 01, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Aug 01, 2025 |   | Initial Version
**/
public with sharing class FileUploadService {
    // Cached CMDT & parsed sets
    private static final File_Upload_Setting__mdt SETTINGS = File_Upload_Setting__mdt.getInstance('GlobalSettings');
    private static final Set<String> ALLOWED_EXTENSIONS = new Set<String>();
    private static final Set<String> BLOCKED_SOBJECTS   = new Set<String>();
    private static final Set<String> EXEMPT_SOBJECTS   = new Set<String>();
    private static string BYPASS_C_P = 'Bypass_Manual_File_Upload_Control';
    
    static {
        // Parse extensions
        if (SETTINGS != null && String.isNotBlank(SETTINGS.Allowed_File_Types__c)) {
            for (String tok : SETTINGS.Allowed_File_Types__c.split('[,;]')) {
                ALLOWED_EXTENSIONS.add(tok.trim().toLowerCase());
            }
        }
        // Parse blocked parent sObjects
        if (SETTINGS != null && String.isNotBlank(SETTINGS.Manual_Upload_Applicable_Objects__c)) {
            for (String tok : SETTINGS.Manual_Upload_Applicable_Objects__c.split(',')) {
                BLOCKED_SOBJECTS.add(tok.trim().toLowerCase());
            }
        }
        
        if (SETTINGS != null && String.isNotBlank(SETTINGS.File_Type_Exempt_Objects__c)) {
            for (String tok : SETTINGS.File_Type_Exempt_Objects__c.split(',')) {
                EXEMPT_SOBJECTS.add(tok.trim().toLowerCase());
            }
        }
    }
    
    /** Ensure CMDT record exists */
    public static void ensureSettings() {
        if (SETTINGS == null) {
            throw new UploadFilesException(
                'Missing File_Upload_Setting__mdt record "GlobalSettings".'
            );
        }
    }
    
    /**
    * Requirement #1: Block manual uploads for configured parent objects,
    * unless user has the bypass Custom Permission.
    */
    public static void validateManualUpload(List<SObject> recs, Schema.SObjectType sType) {
        if (!SETTINGS.Manual_Upload_Control_Enabled__c || BLOCKED_SOBJECTS.isEmpty()) {
            return;
        }
        Boolean hasBypass = FeatureManagement.checkPermission(BYPASS_C_P);
        system.debug('hasBypass:*:: '+hasBypass);
        for (SObject sob : recs) {
            if (hasBypass) break;
            
            Id parentId;
            if (sType == Attachment.SObjectType) {
                parentId = ((Attachment)sob).ParentId;
            } else {
                parentId = ((ContentVersion)sob).FirstPublishLocationId;
            }
            if (parentId == null) continue;
            system.debug('parentId:*:: '+parentId);
            
            // Determine parent API name
            String parentApi = parentId.getSObjectType().getDescribe().getName().toLowerCase();
            system.debug('parentApi:*:: '+parentApi);
            if (BLOCKED_SOBJECTS.contains(parentApi)) {
                system.debug('BLOCKED_SOBJECTS:*:: '+BLOCKED_SOBJECTS);
                sob.addError(
                    'Manual uploads under ' +
                    parentId.getSObjectType().getDescribe().getLabel() +
                    ' are blocked. Use the integrated flow.'
                );
            }
        }
    }
    
    /**
    * Requirement #2: Enforce file-extension whitelist.
    */
    public static void validateFileType(List<SObject> recs, Schema.SObjectType sType) {
        if (!SETTINGS.File_Type_Validation_Enabled__c && !Test.isRunningTest()) return;
        String allowedList = String.join(new List<String>(ALLOWED_EXTENSIONS), ', ');
        try{
            
            List<SObject> invalidRecords = new List<SObject>();
            List<String> errorMessages = new List<String>();
            Id parentId = null;
            for (SObject sob : recs) {
                String filename = (sType == Attachment.SObjectType) ? ((Attachment)sob).Name : ((ContentVersion)sob).PathOnClient;
                parentId = (sType == Attachment.SObjectType) ? ((Attachment)sob).ParentId : ((ContentVersion)sob).FirstPublishLocationId;
                                
                if(parentId != null){
                    String parentApi = parentId.getSObjectType().getDescribe().getName().toLowerCase();
                    if(EXEMPT_SOBJECTS.contains(parentApi)){
                        continue;
                    }
                }
                else{
                    continue;
                }
                if (String.isBlank(filename)) {
                    String msg = 'File name/path missing; cannot validate file type.';
                    sob.addError(msg);
                    invalidRecords.add(sob);
                    errorMessages.add(msg);
                    continue;
                }
                
                if (FeatureManagement.checkPermission(BYPASS_C_P)) continue;
                
                String lc = filename.toLowerCase();
                Integer idx = lc.lastIndexOf('.');
                String ext = (idx >= 0 ? lc.substring(idx + 1) : '');
                
                if (!ALLOWED_EXTENSIONS.contains(ext)) {
                    String msg = 'Extension “‘' + ext + '”’ not allowed. Allowed types: ' + allowedList + '.';
                    sob.addError(msg);
                    invalidRecords.add(sob);
                    errorMessages.add(msg);
                }
            }
            
            if (!invalidRecords.isEmpty()) {
                system.debug('invalidRecords:*:: '+invalidRecords);
                throw new UploadFilesException(
                    'Validation failed for ' + invalidRecords.size() + ' record(s): ' + String.join(errorMessages, ' | ')
                );
            }
            
        } catch (Exception e) {
			system.debug('e ::: '+e);
            ErrorLogger.createLog('FileUploadService','validateFileType',e,'','Apex Class'); 
        }
    }
    
    
    Public Class UploadFilesException extends Exception {}
}