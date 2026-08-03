public with sharing class Portal_FAQMetadataController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCodeTitleMap() {
        Map<String, String> codeTitleMap = new Map<String, String>();
        List<Portal_FAQ_Code_Title_Map__mdt> metadataList = [
            SELECT Code__c, Title__c FROM Portal_FAQ_Code_Title_Map__mdt
        ];
        
        for (Portal_FAQ_Code_Title_Map__mdt record : metadataList) {
            codeTitleMap.put(record.Code__c, record.Title__c);
        }
        
        return codeTitleMap;
    }
}