/*
 *Description       : 
 *Author            : Simplus
 *Created Date		: 15-08-2023
 *History:
 *15-08-2023		Created
*/
public without sharing class ExclusionsDetailsUIController {
    @AuraEnabled
    public static List<ExclusionsDetailsUIDataProvider.ExclusionsDetailsWrapper> getIDDetailsByContactId(String recordId){
        return ExclusionsDetailsUIDataProvider.getIDDetailsByContactId(recordId);
    }
}