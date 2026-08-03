public With Sharing class KeyDateSelector {
    // Define the fields to be queried
    private static final List<String> FIELDS = new List<String>{
        'Id',
            'Name',
            'Patron__c',
            'Patron__r.Patron_ID__c',
            'Patron__r.Home_Property__c',
            'Patron__r.Home_Property__r.name',
            'Active__c', 
            'Key_Date_Category__c',
            'Key_Date_Description__c',
            'Key_Date__c',
            'CreatedDate',
            'Key_Date_Time__c'
            };
                // Method to build the SOQL query string
                private static String buildQueryString(String objectAPI, String whereClause) {
                    return 'SELECT ' + String.join(FIELDS, ', ') + ' FROM ' + objectAPI + ' WHERE ' + whereClause + ' ORDER BY CreatedDate DESC ';
                }
    
    // Method to get records using record Id
    public static List<Key_Date__c> getKeyDateByNewRecords(List<SObject> newRecords) {
        if (newRecords.isEmpty()) return new List<Key_Date__c>();
        String whereClause = 'Id IN: newRecords ';
        return executeQuery('Key_Date__c', whereClause, null, newRecords);
    }
    
    // Method to get records using record Id
    public static List<Key_Date__c> getKeyDateByIds(Set<Id> sFIdSet) {
        if (sFIdSet.isEmpty()) return new List<Key_Date__c>();
        String whereClause = 'Id IN: sFIdSet ';
        return executeQuery('Key_Date__c', whereClause, sFIdSet, null);
    }
    
    // Method to get records based on Contact Id
    public static List<Key_Date__c> getKeyDateByContactIds(Set<Id> patronId, string nameStr) {
        if (patronId.isEmpty()) return new List<Key_Date__c>();
        String whereClause = 'Patron__c IN: patronId ';
        whereClause += buildWhereClause('Name', nameStr);
        whereClause += ' AND Active__c = True';
        whereClause += ' AND Key_Date_Category__c = \'' + 'KYC' + '\'';
        return executeQuery('Key_Date__c', whereClause, patronId, null);
    }
    
    // Helper method to construct WHERE clauses
    private static String buildWhereClause(String field, String value) {
        return value != null && !string.isBlank(value) ? ' AND ' + field + ' = \'' + String.escapeSingleQuotes(value) + '\'' : '';
    }
    
    // Method to execute the query
    private static List<Key_Date__c> executeQuery(String objectAPI, String whereClause, Set<Id> patronId, List<SObject> newRecords) {
        String queryString = buildQueryString(objectAPI, whereClause);
        system.debug('Final Query '+queryString);
        return Database.query(queryString);
    }
    
    public static Map<Id, Integer> getContactDueDateCount(Set<Id> patronSFRecordIds, String keyDateName) {
        Map<Id, Integer> contactDueDateCount = new Map<Id, Integer>();
        
        if (!patronSFRecordIds.isEmpty()) {
            for (AggregateResult result : [
                SELECT Patron__c, COUNT(Id) keyDateCount
                FROM Key_Date__c
                WHERE Patron__c IN :patronSFRecordIds
                AND Name = :keyDateName
                AND Active__c = :ConstantHelper.BOOLEAN_TRUE
                AND Key_Date_Category__c = :ConstantHelper.STRING_KYC
                GROUP BY Patron__c
            ]) {
                contactDueDateCount.put((Id) result.get('Patron__c'), (Integer) result.get('keyDateCount'));
            }
        }
        
        return contactDueDateCount;
    }    
}