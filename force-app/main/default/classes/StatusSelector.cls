public With Sharing class StatusSelector {
    // Define the fields to be queried
    private static final List<String> FIELDS = new List<String>{
        'Id',
            'Name',
            'Type__c',
            'Type_Description__c',
            'Code__c',
            'Description__c',
            'Sub_Type_Description__c',
            'Issue_DateTime__c',
            'Expiry_DateTime__c',
            'Message__c',
            'Property_Id__c',
            'Patron_Id__c',
            'CreatedDate'
            };
                
                
                // Method to build the SOQL query string
                private static String buildQueryString(String objectAPI, String whereClause) {
                    return 'SELECT ' + String.join(FIELDS, ', ') + ' FROM ' + objectAPI + ' WHERE ' + whereClause;
                }
    
    // Method to get records using status, type, and stop code
    public static List<Status__c> getStatusUsingCode(Set<string> patronIdSet, String stopCodeStr, string typeStr) {
        if (patronIdSet.isEmpty()) return new List<Status__c>();
        
        String whereClause = 'Patron_Id__c IN: patronIdSet ';
        whereClause += buildWhereClause('Code__c', stopCodeStr);
        whereClause += buildWhereClause('Type__c', typeStr);
        whereClause += ' ORDER BY LastModifiedDate ';
        return executeQuery('Status__c', whereClause, patronIdSet);
    }


    // Method to get only applied records 
    public static List<Status__c> getStatusUsingCodeApplied(Set<string> patronIdSet, string typeStr, String codeStr, String descriptionStr) {
        if (patronIdSet.isEmpty()) return new List<Status__c>();
        
        String whereClause = 'Patron_Id__c IN: patronIdSet ';
        whereClause += buildWhereClause('Type__c', typeStr);
        whereClause += buildWhereClause('Code__c', codeStr);
        whereClause += buildWhereClause('Description__c', descriptionStr);          
        
        return executeQuery('Status__c', whereClause, patronIdSet);
    }
    
    // Method to get only revoked records
    public static List<Status__c> getStatusUsingCodeRevoked(Set<string> patronIdSet, string typeStr, String codeStr, String descriptionStr) {
        if (patronIdSet.isEmpty()) return new List<Status__c>();
        
        String whereClause = 'Patron_Id__c IN: patronIdSet ';
        whereClause += buildWhereClause('Type__c', typeStr);
        whereClause += buildWhereClause('Code__c', codeStr);
        whereClause += buildWhereClause('Description__c', descriptionStr);          
        
        return executeQuery('Status__c', whereClause, patronIdSet);
    }    
     
    // Helper method to construct WHERE clauses
    private static String buildWhereClause(String field, String value) {
        return value != null && !string.isBlank(value) ? ' AND ' + field + ' = \'' + String.escapeSingleQuotes(value) + '\'' : '';
    }
    
    // Method to execute the query
    private static List<Status__c> executeQuery(String objectAPI, String whereClause, Set<string> patronIdSet) {
        String queryString = buildQueryString(objectAPI, whereClause);
        system.debug('Final Query '+queryString);
        return Database.query(queryString);
    }
    
}