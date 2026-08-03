/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public with sharing class ReportSDataFetchBatch implements Database.Batchable<sObject>, Database.Stateful {
    String query = 'SELECT Gaming_Days_YTD__c,Unique_Patrons_YTD__c, Actual_Win_YTD__c,Gaming_Days_YLTDComp__c, '
                    + 'Unique_Patrons_LYTDComp__c,Actual_Win_LYTDComp__c,'
                    + 'Gaming_Days_MTD__c,Unique_Patrons_MTD__c, Actual_Win_MTD__c, Actual_Win_M1to3__c, Actual_Win_M4to6__c, '
                    + 'Gaming_Days_M1to3__c,Gaming_Days_M4to6__c,'
                    + 'Unique_Patrons_M1to3__c,Unique_Patrons_M4to6__c, CashTheo_MTD__c, CashTheo_YTD__c'
                    + ' FROM MTDYTD_Trend_Data__c';
    Integer total = 0;
    ReportsDataWrapper dataWrap = new ReportsDataWrapper();
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
 
    public void execute( Database.BatchableContext BC,List<MTDYTD_Trend_Data__c> scope){
        try{
            
            total += scope.size();
            for( MTDYTD_Trend_Data__c loopVar: scope){
               
                dataWrap.UniqueYTD += loopVar.Unique_Patrons_YTD__c;
                dataWrap.ActualYTD += loopVar.Actual_Win_YTD__c;
                dataWrap.TripsYTD += loopVar.Gaming_Days_YTD__c;

                dataWrap.UniqueMTD += loopVar.Unique_Patrons_MTD__c;
                dataWrap.ActualMTD += loopVar.Actual_Win_MTD__c;
                dataWrap.TripsMTD += loopVar.Gaming_Days_MTD__c;

                dataWrap.TripsBaseYTD += loopVar.Gaming_Days_YLTDComp__c;
                dataWrap.UniqueBaseYTD += loopVar.Unique_Patrons_LYTDComp__c;
                

                dataWrap.ActualMTDTop += loopVar.Actual_Win_M1to3__c;
                dataWrap.ActualMTDBase += loopVar.Actual_Win_M4to6__c;

                dataWrap.ActualBaseYTD += loopVar.Actual_Win_LYTDComp__c;

                dataWrap.TripsMTDTop += loopVar.Gaming_Days_M1to3__c;
                dataWrap.TripsMTDBase += loopVar.Gaming_Days_M4to6__c;

                dataWrap.UniqueMTDTop += loopVar.Unique_Patrons_M1to3__c;
                dataWrap.UniqueMTDBase += loopVar.Unique_Patrons_M4to6__c;
                

                dataWrap.MTDTheoCurrent += loopVar.CashTheo_MTD__c;
                dataWrap.YTDTheoCurrent += loopVar.CashTheo_YTD__c;
                

            }
            
        }
        catch(Exception e){
            system.debug(e.getCause() + ' '+ e.getMessage() + ' '+ e.getStackTraceString());
        }
        
        
    }
 
    public void finish(Database.BatchableContext BC){
        system.debug(dataWrap);
        system.debug('total '+ total);
    }
}