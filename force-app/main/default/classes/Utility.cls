/**
 * @description       : Utility Class to store all generic methods to be used by multiple classes
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 08-31-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-31-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class Utility {

    
    /**
    * @description Function to return field and its label Map
    * @author sakshi.chauhan@simplus.com | 08-31-2020 
    * @param objectName 
    * @return Map<String, String> 
    **/
    public static Map<String,String> getFieldsMapByObject( String objectName ){
        Map<String,String> fieldLabelMap = new Map<String,String>();
        SObjectType accountType = Schema.getGlobalDescribe().get(objectName);
        Map<String,Schema.SObjectField> fieldsMap = accountType.getDescribe().fields.getMap();
        for(String loopVar: fieldsMap.keyset()){
            String label = fieldsMap.get(loopVar).getDescribe().getLabel();
            fieldLabelMap.put(String.valueOf(fieldsMap.get(loopVar)),label);
        }
        return fieldLabelMap;
    }
}