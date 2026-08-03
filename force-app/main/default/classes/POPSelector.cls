public With Sharing class POPSelector {
    // Define the fields to be queried
    private static final List<String> FIELDS = new List<String>{
        'Id',
            'Name',
            'Patron_ID__c',
            'Contact__c',
            'Type__c',
            'Value__c',
            'Status__c'
            };
                
                // Method to build the SOQL query string
                private static String buildQueryString(String objectAPI, String whereClause) {
                    return 'SELECT ' + String.join(FIELDS, ', ') + ' FROM ' + objectAPI + ' WHERE ' + whereClause + ' ORDER BY CreatedDate DESC ';
                }
    
    // Method to select records by a set of IDs
    public static List<PoP__c> getPoPById(Set<ID> idSet) {
        if (idSet.isEmpty()) return new List<PoP__c>();
        
        String whereClause = 'Id IN :idSet';
        return executeQuery('PoP__c', whereClause, null);
    }

    // Method to select records by a set of contact IDs
    public static List<PoP__c> getPoPByContactId(Set<ID> idSet) {
        if (idSet.isEmpty()) return new List<PoP__c>();
        
        String whereClause = 'Contact__c IN :patronSFIdSet';
        return executeQuery('PoP__c', whereClause, idSet);
    }    
    
    // Method to select records by a custom where clause
    public static List<PoP__c> getPoPByCustomClause(String clauseStr) {
        if (String.isBlank(clauseStr)) return new List<PoP__c>();
        
        return executeQuery('PoP__c', clauseStr, null);
    }
    
    // Method to get records using status, type, and stop code
    public static List<PoP__c> getPoPUsingStatusTypeCode(Set<Id> patronSFIdSet, String statusStr, String typeStr, String stopCodeStr) {
        if (patronSFIdSet.isEmpty()) return new List<PoP__c>();
        system.debug('patronSFIdSet:: '+patronSFIdSet);
        String whereClause = 'Contact__c IN: patronSFIdSet ';
        // If statusStr contains multiple values, add an OR condition
        if (statusStr != null && !string.isBlank(statusStr)) {
            // Check if there are multiple values separated by commas
            List<String> statusList = statusStr.split(', ');
            if (statusList.size() > 1) {
                whereClause += ' AND (' + buildWhereClauseWithOR('Status__c', statusList) + ')';
            } else {
                // If there's just one value, use the buildWhereClause method
                whereClause += buildWhereClause('Status__c', statusStr);
            }
        }
        whereClause += buildWhereClause('Type__c', typeStr);
        whereClause += buildWhereClause('Value__c', stopCodeStr);
        return executeQuery('PoP__c', whereClause, patronSFIdSet);
    }
    
    // Helper method to construct WHERE clauses
    private static String buildWhereClause(String field, String value) {
        return value != null && !string.isBlank(value) ? ' AND ' + field + ' = \'' + String.escapeSingleQuotes(value) + '\'' : '';
    }
    
    // Helper method to build OR condition for multiple status values
    private static String buildWhereClauseWithOR(String field, List<String> values) {
        String condition = '';
        for (String value : values) {
            if (!string.isBlank(condition)) {
                condition += ' OR ';
            }
            condition += field + ' = \'' + String.escapeSingleQuotes(value.trim()) + '\'';
        }
        return condition;
    }
    
    // Method to execute the query
    private static List<PoP__c> executeQuery(String objectAPI, String whereClause, Set<Id> patronSFIdSet) {
        String queryString = buildQueryString(objectAPI, whereClause);
        system.debug('Final Query '+queryString);
        return Database.query(queryString);
    }
    
}