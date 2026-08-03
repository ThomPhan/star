public with sharing class powerBiReportController {
    @AuraEnabled(cacheable = true)
    public static List<Power_BI_Properties__mdt> getMetadataValue() {
        return [SELECT Id, Report_ID__c, Workspace_ID__c FROM Power_BI_Properties__mdt WHERE DeveloperName = 'Properties_Value'];
    }
}