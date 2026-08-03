public with sharing class PicklistEntryValue {
    @AuraEnabled public String value { get; set; }
    @AuraEnabled public String label { get; set; }

    public PicklistEntryValue(String value, String label) {
        this.value = value;
        this.label = label;
    }
}