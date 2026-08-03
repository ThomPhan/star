public With Sharing class ContactSelector {
    // Define the fields to be queried
    private static final List<String> FIELDS = new List<String>{
        'Id',
            'Name',
            'Patron_ID__c',
            'Home_Property__r.Name',
            'Home_Property__c',
            'createdDate'
            };
                // Method to build the SOQL query string
                private static String buildQueryString(String objectAPI, String whereClause) {
                    return 'SELECT ' + String.join(FIELDS, ', ') + ' FROM ' + objectAPI + ' WHERE ' + whereClause;
                }
    
    public static List<Contact> getContactByIds(Set<Id> sFIdSet) {
        if (sFIdSet.isEmpty()) return new List<Contact>();
        String whereClause = 'Id IN: sFIdSet ';
        return executeQuery('Contact', whereClause, sFIdSet, null);
    }
    
    public static List<Contact> getContactByExtIds(Set<String> extIdSet) {
        if (extIdSet.isEmpty()) return new List<Contact>();
        String whereClause = 'Patron_ID__c IN: extIdSet ';
        return executeQuery('Contact', whereClause, null,extIdSet);
    }
    
    // Helper method to construct WHERE clauses
    private static String buildWhereClause(String field, String value) {
        return value != null && !string.isBlank(value) ? ' AND ' + field + ' = \'' + String.escapeSingleQuotes(value) + '\'' : '';
    }
    
    // Method to execute the query
    private static List<Contact> executeQuery(String objectAPI, String whereClause, Set<Id> sFIdSet, Set<String> extIdSet) {
        String queryString = buildQueryString(objectAPI, whereClause);
        system.debug('Final Query '+queryString);
        return Database.query(queryString);
    }
    
}