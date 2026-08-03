/**
 * @description       : Class for providing data to be used in the GamingDataUI Lightning Component (called by GamingDataUI Aura Component)
 * @author            : dominicjasper.caberoy@simplus.com
 * @group             : 
 * @last modified on  : 08-20-2020
 * @last modified by  : dominicjasper.caberoy@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-17-2020   dominicjasper.caberoy@simplus.com   Initial Version
**/
public without sharing class GamingDataUIHandler {
    //GET THE LIST OF PROPERTIES (DESKTOP VIEW)
	@AuraEnabled
    public static Map<String, String> propertyList(){
        
        //Map<String, String> distinctProperties = new Map<String, String>();
        //for(Property__c properties: [SELECT Id, Name FROM Property__c]){
        //    distinctProperties.put(properties.Name, properties.Id);
        //}
        
        List<Property__c> tempPropList = [SELECT Id, Name FROM Property__c];
        tempPropList.sort();
        Map<String, String> distinctProperties = new Map<String, String>();
        for(Property__c properties: tempPropList){
            distinctProperties.put(properties.Name, properties.Id);
        }
        
        return distinctProperties;
    }
    //GET THE LIST OF GAMING DATA EXTERNAL OBJECT (DESKTOP VIEW)
    @AuraEnabled
    public static String gamingList(String patronId, String propertyID){
        String gameData = GamingDataProvider.getGamingDataJSON(patronId, propertyID);
        return gameData;
    }
    //GET THE LIST OF GAMING DATA EXTERNAL OBJECT (MOBILE VIEW)
    @AuraEnabled
    public static String gamingListTotal(String patronId, String type, String periodId){
        String gameData = GamingDataProvider.getGamingDataTotalJSON(patronId, type, periodId);
        return gameData;
    }
}