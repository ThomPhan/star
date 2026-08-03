/**
 * @description       : Wrapper Class for setting up the data returned from the query of the Gaming Data External Object (called by GamingDataProvider.apxc)
 * @author            : dominicjasper.caberoy@simplus.com
 * @group             : 
 * @last modified on  : 08-17-2020
 * @last modified by  : dominicjasper.caberoy@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-17-2020   dominicjasper.caberoy@simplus.com   Initial Version
**/
public class GamingDataWrapper {
    @AuraEnabled public Decimal Actual{get;set;}
    @AuraEnabled public Decimal ADT{get;set;}
    @AuraEnabled public Decimal AverageBet{get;set;}
    @AuraEnabled public Decimal FreePlay{get;set;}
    @AuraEnabled public String Type_var{get;set;}
    @AuraEnabled public Decimal NetTheo{get;set;}
    @AuraEnabled public Decimal Trips{get;set;}
    @AuraEnabled public Decimal Turnover{get;set;}
    @AuraEnabled public String Period{get;set;}
    @AuraEnabled public String Contact_ID{get;set;}
    @AuraEnabled public String Property_ID{get;set;}
    @AuraEnabled public String Property_Name{get;set;}
    
    public GamingDataWrapper(Decimal Actual, Decimal ADT, Decimal AverageBet, Decimal FreePlay, String Type_var, Decimal NetTheo, Decimal Trips, Decimal Turnover, String Period, String Contact_ID, String Property_ID, String Property_Name){
        this.Actual = Actual;
        this.ADT = ADT;
        this.AverageBet = AverageBet;
        this.FreePlay = FreePlay;
        this.Type_var = Type_var;
        this.NetTheo = NetTheo;
        this.Trips = Trips;
        this.Turnover = Turnover;
        this.Period = Period ;
        this.Contact_ID = Contact_ID;
        this.Property_ID = Property_ID ;
        this.Property_Name = Property_Name;
    }
}