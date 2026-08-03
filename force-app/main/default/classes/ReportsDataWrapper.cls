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
public with sharing class ReportsDataWrapper {
    public Decimal UniqueYTD {get; set;}    
    public Decimal ActualYTD {get; set;}
    public Decimal TripsYTD{get; set;}
    

    public Decimal UniqueMTD {get; set;}
    public Decimal ActualMTD {get; set;}
    public Decimal TripsMTD {get; set;}

    public Decimal TripsBaseYTD {get; set;}
    public Decimal UniqueBaseYTD {get; set;}

    public Decimal ActualMTDTop{ get;set;}
    public Decimal ActualMTDBase {get; set;}
    public Decimal ActualBaseYTD {get; set;}
    public Decimal TripsMTDTop {get; set;}
    public Decimal TripsMTDBase {get; set;}
    public Decimal UniqueMTDTop {get; set;}
    public Decimal UniqueMTDBase {get; set;}

    public Decimal MTDTheoCurrent {get; set;}
    public Decimal YTDTheoCurrent {get; set;}
    

    public ReportsDataWrapper(){
        UniqueYTD = 0;
        ActualYTD = 0;
        TripsYTD = 0;
        UniqueMTD=0;
        ActualMTD = 0;
        TripsMTD= 0;
        TripsBaseYTD=0;
        UniqueBaseYTD=0;
        ActualMTDTop=0;
        ActualMTDBase = 0;
        ActualBaseYTD = 0;
        TripsMTDTop = 0;
        TripsMTDBase = 0;

        UniqueMTDTop = 0;
        UniqueMTDBase = 0;

        MTDTheoCurrent = 0;
        YTDTheoCurrent = 0;
    }
}