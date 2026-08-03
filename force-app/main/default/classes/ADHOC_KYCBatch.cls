public class ADHOC_KYCBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String keyDateCategory = 'KYC';
        Boolean activeStatus = true;
        String nameCondition1 = ConstantHelper.STRING_KEYDATE_DUEDATE;
        String nameCondition2 = ConstantHelper.STRING_KEYDATE_ATTESTATION;
        string nameCondition3 = ConstantHelper.STRING_KEYDATE_DUEDATE_OVERRIDE;
        Integer lastNDays = 3;
        
        // Query to find eligible Key_Date__c records
        String query = 
			'SELECT Id, Patron__c, Name, Key_Date__c, Key_Date_Category__c ' +
            'FROM Key_Date__c ' +
            'WHERE Key_Date_Category__c = :keyDateCategory ' +
            'AND Active__c = :activeStatus ' +
            'AND (Name = :nameCondition1 OR Name = :nameCondition2 OR Name = :nameCondition3) ' +
            'AND ' + System.Label.ADHOC_DateLabel + ' ' +
            'AND Patron__c NOT IN (SELECT contact__c FROM pop__c) ';

        system.debug('query '+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        system.debug('scope:: '+scope);
        for(sobject s : scope){
            system.debug('s record:: '+s);
        }
        //Process the batch using KYCUtility
        KYCUtility.segregateKeyDates(scope);
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch process completed.');
    }

    // Schedule execution for nightly run
    public void execute(SchedulableContext SC) {
    }
}