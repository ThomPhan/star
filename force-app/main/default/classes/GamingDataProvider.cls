/**
 * @description       : Class for setting up the query for the external object (called by GamingDataUIHandler.apxc)
 * @author            : dominicjasper.caberoy@simplus.com
 * @group             : 
 * @last modified on  : 08-17-2020
 * @last modified by  : dominicjasper.caberoy@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-17-2020   dominicjasper.caberoy@simplus.com   Initial Version
 * 1.1   01-28-2021   rhysjohn.delacruz@simplus.com	 Changes to GamingData Enhancement, Property_Name added to query
**/
public without sharing class GamingDataProvider {
    public static List<GamingData__x> getGamingDataRecordsByPatronId(String patronId, String propertyID){
        GamingDataObjectSelector obj = new GamingDataObjectSelector();
        String fields = String.valueOf(obj.getExternalObjectFieldsList()).remove(')').remove('(');
        
        String allProperties = System.label.All_Properties;
        
        //TEST CLASS IS CURRENTLY RUNNING
        if(Test.isRunningTest()){
            if( GamingDataUIHandlerTest.isException == true ){
                throw new GamingDataProviderException();
            }
            GamingData__x testGameData = new GamingData__x(SalesforceContactId__c = GamingDataUIHandlerTest.ct.Id, SalesforcePropertyID__c = GamingDataUIHandlerTest.prop.Id, Actual__c = 123, ADT__c = 123, AverageBet__c = 123, FreePlay__c = 123, Type__c = 'SLOT', NetTheo__c = 123, Trips__c = 123, Turnover__c = 123, Period__c = 'Month To Date');
            List<GamingData__x> gameData= new List<GamingData__x>();
            gameData.add(testGameData);
            return gameData;
        } else {
            //RJCDC 2021-02-01
            //Check name and property

            //String includeProperty = (!String.isBlank(propertyID)) ? ' AND SalesforcePropertyID__c = :propertyID LIMIT 100' : ' LIMIT 100';
            String includeProperty;
            if(String.isBlank(propertyID)){
                includeProperty = ' AND SalesforcePropertyID__r.Name =: allProperties LIMIT 100';
            }
            else if(!String.isBlank(propertyID)){
                includeProperty = ' AND SalesforcePropertyID__c = :propertyID LIMIT 100';
            }
            else{
                includeProperty = ' LIMIT 100';
            }
                
            //String query = 'SELECT Actual__c, ADT__c, AverageBet__c, FreePlay__c, Type__c, NetTheo__c, Trips__c, Turnover__c, Period__c, SalesforceContactID__c, SalesforcePropertyID__c, SalesforcePropertyID__r.Name FROM ' + obj.getExternalObjectType() + ' WHERE SalesforceContactID__c = :patronId' + includeProperty;

            
            //Temp Gaming Data code to be used in Dev only
            String query = 'SELECT Actual__c, ADT__c, AverageBet__c, FreePlay__c, Type__c, NetTheo__c, Trips__c, Turnover__c, Period__c, SalesforceContactID__c, SalesforcePropertyID__c, SalesforcePropertyID__r.Name FROM Temp_GamingData__c WHERE SalesforceContactID__c = :patronId' + includeProperty;

            List<GamingData__x> testGamingDataList = new List<GamingData__x>();
            for(Temp_GamingData__c tempGData : Database.query(query)){

                GamingData__x testGameData = new  GamingData__x();
                testGameData.Actual__c = tempGData.Actual__c;
                testGameData.ADT__c = tempGData.ADT__c;
                testGameData.AverageBet__c = tempGData.AverageBet__c;
                testGameData.FreePlay__c = tempGData.FreePlay__c;
                testGameData.Type__c = tempGData.Type__c;
                testGameData.NetTheo__c = tempGData.NetTheo__c;
                testGameData.Trips__c = tempGData.Trips__c;
                testGameData.Turnover__c = tempGData.Turnover__c;
                testGameData.Period__c = tempGData.Period__c;
                testGameData.SalesforceContactID__c = tempGData.SalesforceContactID__c;
                testGameData.SalesforcePropertyID__c = tempGData.SalesforcePropertyID__c;
                //testGameData.SalesforcePropertyID__r.Name = tempGData.SalesforcePropertyID__r.Name;
                testGamingDataList.add(testGameData);
            }
            return testGamingDataList; 

            //return Database.query(query);
        }
    }
    public static String getGamingDataJSON(String patronId, String propertyID){
        List<GamingDataWrapper> gdataWrapper = new List<GamingDataWrapper>();
        try{
            List<GamingData__x> gamingDetails = getGamingDataRecordsByPatronId(patronId, propertyID);
            if(gamingDetails.size() > 0){
                for(GamingData__x gdata : gamingDetails){
                    gdataWrapper.add(
                        new GamingDataWrapper(gdata.Actual__c, gdata.ADT__c, gdata.AverageBet__c, gdata.FreePlay__c, gdata.Type__c, gdata.NetTheo__c, gdata.Trips__c, gdata.Turnover__c, gdata.Period__c, gdata.SalesforceContactID__c, gdata.SalesforcePropertyID__c, gdata.SalesforcePropertyID__r.Name)
                    );
                }
            } else {
                System.debug('No records Found');
            }
        } catch (Exception e){
            System.debug(e.getMessage());
            ErrorLogger.createLog('GamingDataProvider','getGamingDataJSON',e,patronId,'Apex Class'); 
        }
        return JSON.serialize(gDataWrapper);
    }
    
    public static String getGamingDataTotalJSON(String patronId, String type, String periodId) {
        List<GamingDataWrapper> gdataWrapper = new List<GamingDataWrapper>();
        try{
            List<GamingData__x> gamingDetails = getGamingDataTotalRecordsByPatronId(patronId, type, periodId);
            if(gamingDetails.size() > 0){
                for(GamingData__x gdata : gamingDetails){
                    gdataWrapper.add(
                        new GamingDataWrapper(gdata.Actual__c, gdata.ADT__c, gdata.AverageBet__c, gdata.FreePlay__c, gdata.Type__c, gdata.NetTheo__c, gdata.Trips__c, gdata.Turnover__c, gdata.Period__c, gdata.SalesforceContactID__c, gdata.SalesforcePropertyID__c, gdata.SalesforcePropertyID__r.Name)
                    );
                }
            } else {
                System.debug('No records Found');
            }
        } catch (Exception e){
            System.debug(e.getMessage());
            ErrorLogger.createLog('GamingDataProvider','getGamingDataJSON',e,patronId,'Apex Class'); 
        }
        return JSON.serialize(gDataWrapper);
    }
    
     public static List<GamingData__x> getGamingDataTotalRecordsByPatronId(String patronId, String type, String periodId){
        GamingDataObjectSelector obj = new GamingDataObjectSelector();
        List<GamingData__x> gamingTotalList = new List<GamingData__x>();
        String fields = String.valueOf(obj.getExternalObjectFieldsList()).remove(')').remove('(');
        String allProperties = System.label.All_Properties;
         
        //TEST CLASS IS CURRENTLY RUNNING
        if(Test.isRunningTest()){
            if( GamingDataUIHandlerTest.isException == true ){
                throw new GamingDataProviderException();
            }
            GamingData__x testGameData = new GamingData__x(SalesforceContactId__c = GamingDataUIHandlerTest.ct.Id, Actual__c = 123, ADT__c = 123, AverageBet__c = 123, FreePlay__c = 123, Type__c = 'SLOT', NetTheo__c = 123, Trips__c = 123, Turnover__c = 123, Period__c = 'Month To Date');
            List<GamingData__x> gameData= new List<GamingData__x>();
            gameData.add(testGameData);
            return gameData;
        } else {
            String includeType = (!String.isBlank(type)) ? ' AND Type__c = :type' : ' AND (Type__c = \'SLOT\' OR Type__c = \'ETG\' OR Type__c = \'Table\')';
            String includePeriod = (!String.isBlank(periodId)) ? ' AND Period__c = :periodId' : '';
            String includeProperty = ' AND SalesforcePropertyID__r.Name =: allProperties ';
            System.debug('Test '+ includeProperty);

            //gamingTotalList = Database.query('SELECT Actual__c, ADT__c, AverageBet__c, FreePlay__c, Type__c, NetTheo__c, Trips__c, Turnover__c, Period__c, SalesforceContactID__c, SalesforcePropertyID__c, SalesforcePropertyID__r.Name FROM ' + obj.getExternalObjectType() + ' WHERE SalesforceContactID__c = :patronId ' + includeType + ' ' + includePeriod + includeProperty + ' Limit 100');

            
            //Temp Gaming Data code to be used in Dev only
            List<Temp_GamingData__c> tempGamingTotalList = new List<Temp_GamingData__c>();
            //tempGamingTotalList = Database.query('SELECT Actual__c, ADT__c, AverageBet__c, FreePlay__c, Type__c, NetTheo__c, Trips__c, Turnover__c, Period__c, SalesforceContactID__c, SalesforcePropertyID__c, SalesforcePropertyID__r.Name FROM Temp_GamingData__c WHERE SalesforceContactID__c = :patronId ' + includeType + ' ' + includePeriod + includeProperty + ' Limit 100');
            
            patronId = '%'+patronId+'%';
            tempGamingTotalList = Database.query('SELECT Actual__c, ADT__c, AverageBet__c, FreePlay__c, Type__c, NetTheo__c, Trips__c, Turnover__c, Period__c, SalesforceContactID__c, SalesforcePropertyID__c, SalesforcePropertyID__r.Name FROM Temp_GamingData__c WHERE SalesforceContactID__c LIKE :patronId ' + includeType + ' ' + includePeriod + includeProperty + ' Limit 100');
            
            for(Temp_GamingData__c tempGData : tempGamingTotalList){

                GamingData__x testGameData = new GamingData__x();
                testGameData.Actual__c = tempGData.Actual__c;
                testGameData.ADT__c = tempGData.ADT__c;
                testGameData.AverageBet__c = tempGData.FreePlay__c;
                testGameData.FreePlay__c = tempGData.FreePlay__c;
                testGameData.Type__c = tempGData.Type__c;
                testGameData.NetTheo__c = tempGData.NetTheo__c;
                testGameData.Trips__c = tempGData.Trips__c;
                testGameData.Turnover__c = tempGData.Turnover__c;
                testGameData.Period__c = tempGData.Period__c;
                testGameData.SalesforceContactID__c = tempGData.SalesforceContactID__c;
                testGameData.SalesforcePropertyID__c = tempGData.SalesforcePropertyID__c;
                gamingTotalList.add(testGameData);
            } 

            System.debug(gamingTotalList);
            return gamingTotalList;
        }
    }
    //FOR EXCEPTION IN TEST CLASS
    public class GamingDataProviderException extends Exception{}
}