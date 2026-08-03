/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public without sharing class FinancialSummaryUIController {
    
    @AuraEnabled
    public static string getFinancialData(String recordId){
        String str = FinanceDataProvider.getFinanceDataJSON((Id)recordId);
        return str;
        
    }
}