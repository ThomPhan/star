/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-20-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public without sharing class FinanceDataProvider {

    public static String getFinanceDataJSON(Id recordId) {
        List<FinanceObjectWrapper> financeObjWrapList = new List<FinanceObjectWrapper>();
        try{
            
            List<FinancialSummary__x> fdetails = getFinanceRecordsByContactId(recordId);
            FinanceObjectWrapper wrapperObj = new FinanceObjectWrapper();
            wrapperObj = initiliseFinanceUILabels(wrapperObj);

            if(fdetails.size() > 0){
                
                for(FinancialSummary__x detObj : fdetails){
                    wrapperObj = initialiseWrapperObject(wrapperObj,detObj); 
                }
            }      
            financeObjWrapList.add(wrapperObj);       
            return JSON.serialize(financeObjWrapList);
            
           
        }
        catch(Exception e){
            system.debug('cdsdsfds');
            system.debug('Exception happenned '+ e.getMessage() );
            ErrorLogger.createLog('FinanceDataProvider','getFinanceDataJSON',e,recordId,'Apex Class'); 
            return null;
        }
  
    }    

    public static List<FinancialSummary__x> getFinanceRecordsByContactId(Id contactId){
        if(Test.isRunningTest()){
            if( FinancialSummaryUIControllerTest.testException == true ){
                throw new FinanceDataProviderException();
            }
            FinancialSummary__x testFinData = new FinancialSummary__x(SalesforceContactId__c = FinancialSummaryUIControllerTest.ct.Id,ADT__c=2121,TotalTheo__c=129,TotalActual__c=3233,ADTTrend__c='Up',TheoTrend__c='Down',HeaderLabel__c = 'Performance Overview');
            List<FinancialSummary__x> finList= new List<FinancialSummary__x>();
            finList.add(testFinData);
            return finList;
            //return null;
        }
        else{
            FinanceObjectSelector selector = new FinanceObjectSelector();

            String field = '';
            for (Integer i = 0; i < selector.getExternalObjectFieldsList().size(); i++) {
                String currentField = String.valueOf(selector.getExternalObjectFieldsList()[i]);
                field = field + currentField + ',';
            }
            String fields = field.removeEnd(',');

            //String query = 'SELECT ' + fields + ' FROM ' + selector.getExternalObjectType() + ' WHERE SalesforceContactId__c = \'' + contactId + '\' LIMIT 1';
            Contact contRec = [SELECT Patron_ID__c FROM Contact WHERE Id =  :contactId LIMIT 1];
            String query = 'SELECT ' + fields + ' FROM ' + selector.getExternalObjectType() + ' WHERE SalesforceContactId__c LIKE \'%' + contactId + '%\' AND ExternalId = \'' + contRec.Patron_ID__c + '\' LIMIT 1';
            return Database.query(query);
        }
    }

    public static FinanceObjectWrapper initialiseWrapperObject( FinanceObjectWrapper wrapObjTemp,FinancialSummary__x fSummarydetailObj){
        if( wrapObjTemp.dataDetails == null ){
            wrapObjTemp.dataDetails = new FinanceObjectWrapper.Data();
        }
        wrapObjTemp.contactId = fSummarydetailObj.SalesforceContactId__c;
        wrapObjTemp.dataDetails.ADT = fSummarydetailObj.ADT__c;
        wrapObjTemp.dataDetails.theo = fSummarydetailObj.TotalTheo__c; 
        wrapObjTemp.dataDetails.trips = fSummarydetailObj.TotalTrips__c; 
        wrapObjTemp.dataDetails.actual = fSummarydetailObj.TotalActual__c;

        wrapObjTemp.dataDetails.createDt = fSummarydetailObj.CreateDt__c != null?fSummarydetailObj.CreateDt__c.format('dd/MM/yyyy, hh:mm a', + 'Pacific'):null;

        wrapObjTemp.dataDetails.adtTrend = fSummarydetailObj.ADTTrend__c != null?fSummarydetailObj.ADTTrend__c.toUpperCase():null ;
        wrapObjTemp.dataDetails.theoTrend = fSummarydetailObj.TheoTrend__c != null?fSummarydetailObj.TheoTrend__c.toUpperCase():null;
        wrapObjTemp.dataDetails.tripsTrend = fSummarydetailObj.TripsTrend__c != null?fSummarydetailObj.TripsTrend__c.toUpperCase():null;
        wrapObjTemp.dataDetails.headerLabel = fSummarydetailObj.HeaderLabel__c != null ?fSummarydetailObj.HeaderLabel__c.toUpperCase():null;
        wrapObjTemp.dataDetails.actualTrend = fSummarydetailObj.ActualTrend__c != null? fSummarydetailObj.ActualTrend__c.toUpperCase():null;
        return wrapObjTemp;
    }

    public static FinanceObjectWrapper initiliseFinanceUILabels(FinanceObjectWrapper wrapObjTemp){
        Map<String,String> fieldLabelMap = Utility.getFieldsMapByObject('FinancialSummary__x');
        if(wrapObjTemp.labelDetails == null){
            wrapObjTemp.labelDetails = new FinanceObjectWrapper.Labels();
        }
        wrapObjTemp.labelDetails.adtLabel = fieldLabelMap.get('ADT__c');
        wrapObjTemp.labelDetails.theoLabel = fieldLabelMap.get('TotalTheo__c');
        wrapObjTemp.labelDetails.tripsLabel = fieldLabelMap.get('TotalTrips__c');
        wrapObjTemp.labelDetails.actualLabel = fieldLabelMap.get('TotalActual__c');

        return wrapObjTemp;
    }

    public class FinanceDataProviderException extends Exception{}
}