/**
 * @description       : Wrapper class to provide data to component controller
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-02-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class FinanceObjectWrapper {
    @AuraEnabled public String contactId{get; set;}
    @AuraEnabled public Labels labelDetails{get; set;}
    @AuraEnabled public Data dataDetails{get; set;}

    public class Labels{
        @AuraEnabled public String adtLabel{get; set;}
        @AuraEnabled public String theoLabel{get; set;}
        @AuraEnabled public String tripsLabel{get; set;}
        @AuraEnabled public String actualLabel{get; set;}
    }

    public class Data{
        @AuraEnabled public String headerLabel{get; set;}

        @AuraEnabled public Decimal ADT{get; set;}
        @AuraEnabled public Decimal theo{get; set;}
        @AuraEnabled public Decimal trips{get; set;}
        @AuraEnabled public Decimal actual{get; set;}

        @AuraEnabled public String createDt{get; set;}

        @AuraEnabled public String adtTrend{get; set;}
        @AuraEnabled public String theoTrend{get; set;}
        @AuraEnabled public String tripsTrend{get; set;}
        @AuraEnabled public String actualTrend{get; set;}
    }
}