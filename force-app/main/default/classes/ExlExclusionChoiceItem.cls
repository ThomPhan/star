public class ExlExclusionChoiceItem {
    @AuraEnabled public String label { get; set; }
    @AuraEnabled public String value { get; set; }

    public ExlExclusionChoiceItem() {}
    public ExlExclusionChoiceItem(String label, String value) {
        this.label = label;
        this.value = value;
    }
}