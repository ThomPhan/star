/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-12-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public with sharing class D3ChartController 
{
    
    /**
    * @description method to return data for Gauge chart in lightning component GaugeChartComponent
    * @return string Object
    **/
    @AuraEnabled
    public static ChartDataWrapper getReportsData(){
        
        try {
            if( D3ChartControllerTestClass.testException == true && Test.isRunningTest()){
                throw new D3ChartControllerException(); 
            }                       
            ChartDataWrapper dataWrapper = new ChartDataWrapper();
            User userObj = [ SELECT  MTD_Target__c,YTD_Target__c FROM  User WHERE ID =: System.UserInfo.getUserId()];
            dataWrapper.ytdTarget = userObj.YTD_Target__c;
            dataWrapper.mtdTarget = userObj.MTD_Target__c;
            dataWrapper = initialiseDefaultValues(dataWrapper);
            Set<String> reportsToQuery = constructReportSetToQuery();
            Map<Id,Report> reportMap = getReportsQuery(reportsToQuery,D3ChartUtility.reportsFolderName);
            system.debug('reportMap ' + reportMap);

            dataWrapper.ytdUniqueReportId = getReportId(reportMap,D3ChartUtility.ytdUniqueReportName);
            dataWrapper.ytdTripsReportId = getReportId(reportMap,D3ChartUtility.ytdTripsReportName);
            dataWrapper.ytdActualReportId = getReportId(reportMap,D3ChartUtility.ytdActualReportName);
            // ************* MTD Reports ******************
            dataWrapper.mtdUniqueReportId = getReportId(reportMap,D3ChartUtility.mtdUniqueReportName);
            dataWrapper.mtdActualReportId = getReportId(reportMap,D3ChartUtility.mtdActualReportName);
            dataWrapper.mtdTripsReportId = getReportId(reportMap,D3ChartUtility.mtdTripsReportName);

            // // ************* Theo Reports ******************
            dataWrapper.mtdTheoReportId = getReportId(reportMap,D3ChartUtility.mtdTheoReportName);
            dataWrapper.ytdTheoReportId = getReportId(reportMap,D3ChartUtility.ytdTheoReportName);

            //*****************Getting Aggregate values by REST Callout *************//
            // ************* YTD Reports ******************
            String sessionId = fetchUserSessionId();
            Decimal UniqueYTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Unique_Patrons_YTD__c',sessionId);
           
            Decimal ActualYTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Actual_Win_YTD__c',sessionId);
            
            Decimal TripsYTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Gaming_Days_YTD__c',sessionId);
            
          

            Decimal UniqueMTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Unique_Patrons_MTD__c',sessionId);
        
            Decimal ActualMTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Actual_Win_MTD__c',sessionId);
          
            Decimal TripsMTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Gaming_Days_MTD__c',sessionId);
     
            Decimal TripsBaseYTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Gaming_Days_YLTDComp__c',sessionId);

            Decimal UniqueBaseYTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Unique_Patrons_LYTDComp__c',sessionId);


            Decimal ActualMTDTop = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Actual_Win_M1to3__c',sessionId);
            Decimal ActualMTDBase = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Actual_Win_M4to6__c',sessionId);

            Decimal ActualBaseYTD = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Actual_Win_LYTDComp__c',sessionId);

            Decimal TripsMTDTop = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Gaming_Days_M1to3__c',sessionId);
            Decimal TripsMTDBase = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Gaming_Days_M4to6__c',sessionId);

            Decimal UniqueMTDTop = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Unique_Patrons_M1to3__c',sessionId);
            Decimal UniqueMTDBase = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('Unique_Patrons_M4to6__c',sessionId);
            

            Decimal MTDTheoCurrent = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('CashTheo_MTD__c',sessionId);
            Decimal YTDTheoCurrent = ReportsDataFetchRestService.getAggregateDataFromMTDYTDByField('CashTheo_YTD__c',sessionId);

            //Method that calls calculation of Target MTD
            Decimal mtdPercentageOverUnder = calculateMonthTarget(dataWrapper.mtdTarget, MTDTheoCurrent);
            dataWrapper.mtdPercentageOverUnder = String.valueOf(mtdPercentageOverUnder.setScale(1)) + '% ';

            String mtdStatus = '';
            String mtdText = ' ';
            if(mtdPercentageOverUnder.setScale(1) > 0){
                mtdStatus = 'limegreen';
                mtdText =+ Label.AheadOfMTDTarget;
            }
            else if(mtdPercentageOverUnder.setScale(1) < 0){
                mtdStatus = 'red';
                mtdText =+ Label.BehindMTDTarget;
            }
            else if(mtdPercentageOverUnder.setScale(1) == 0){
                mtdStatus = 'black';
                mtdText =+ Label.OnTarget;
            }
            dataWrapper.mtdPercColor = mtdStatus;
            dataWrapper.mtdText = mtdText;


            //Method that calls calculation of Target YTD
            Decimal ytdPercentageOverUnder = calculateYearTarget(dataWrapper.ytdTarget, YTDTheoCurrent);
            dataWrapper.ytdPercentageOverUnder = String.valueOf(ytdPercentageOverUnder.setScale(1)) + '% ';

            String ytdStatus = '';
            String ytdText = ' ';
            if(ytdPercentageOverUnder.setScale(1) > 0){
                ytdStatus = 'limegreen';
                ytdText =+ Label.AheadOfYTDTarget;
            }
            else if(ytdPercentageOverUnder.setScale(1) < 0){
                ytdStatus = 'red';
                ytdText =+ Label.BehindYTDTarget;
            }
            else if(ytdPercentageOverUnder.setScale(1) == 0){
                ytdStatus = 'black';
                ytdText =+ Label.OnTarget;
            }
            dataWrapper.ytdPercColor = ytdStatus;
            dataWrapper.ytdText = ytdText;

            // ****************  YTD Values **************** 
    
            dataWrapper.ytdUnique = String.valueOf(Integer.valueOf(UniqueYTD) );
            dataWrapper.ytdActual = returnNumberInFormat(  ActualYTD );
            dataWrapper.ytdTrips  = String.valueOf( Integer.valueOf(TripsYTD)  );
        
            system.debug('dataWrapper.ytdUnique ='+dataWrapper.ytdUnique);
            
            // **************** YTD Trend **************** //
            Decimal x = UniqueYTD!=null? UniqueYTD: 1 ; 
            Decimal y = UniqueBaseYTD!=null?UniqueBaseYTD : 1 ; 
           
            
                dataWrapper.ytdUniqueTrend = y!=0?getTrendName( (x-y)*100/y ):'0';
                    
                x = ActualYTD != null ? ActualYTD : 1 ; 
                y = ActualBaseYTD!=null ? ActualBaseYTD: 1 ; 

            
                dataWrapper.ytdActualTrend = y!=0?getTrendName((x-y)*100/y ):'0';
            
                x = TripsYTD!=null? TripsYTD : 1 ;
                y = TripsBaseYTD!=null? TripsBaseYTD : 1 ; 
            
           
                
                dataWrapper.ytdTripsTrend = y!=0?getTrendName((x-y)*100/y):'0';
            
                // ****************  MTD Values **************** 
                dataWrapper.mtdUnique = String.valueOf( Integer.valueOf(UniqueMTD) );
                dataWrapper.mtdActual = returnNumberInFormat(ActualMTD);
                dataWrapper.mtdTrips  = String.valueOf( Integer.valueOf(TripsMTD) );

                // ****************  MTD Trend **************** 
                
                x = UniqueMTDTop!=null? UniqueMTDTop : 1 ;  
                y = UniqueMTDBase!=null?UniqueMTDBase: 1 ;  

                dataWrapper.mtdUniqueTrend = y!=0?getTrendName((x-y)*100/y):'0';
                
                x =  ActualMTDTop !=null?  ActualMTDTop : 1 ;
                y =  ActualMTDBase !=null?  ActualMTDBase : 1 ;
            
                dataWrapper.mtdActualTrend = y!=0?getTrendName((x-y)*100/y):'0';
            
                x =  TripsMTDTop !=null? TripsMTDTop : 1 ; 
                y =  TripsMTDBase !=null? TripsMTDBase : 1 ; 
            
    
            
                dataWrapper.mtdTripsTrend = y!=0?getTrendName((x-y)*100/y):'0';
            
                dataWrapper.mtdCurrent =  MTDTheoCurrent!=null? MTDTheoCurrent : 0 ;  
            
                dataWrapper.ytdCurrent =  YTDTheoCurrent!=null? YTDTheoCurrent : 0 ;  
               
                if(dataWrapper.ytdTarget == null )
                    dataWrapper.ytdTarget = dataWrapper.ytdCurrent;
                
                if(dataWrapper.mtdTarget == null )
                    dataWrapper.mtdTarget = dataWrapper.mtdCurrent;
                 
            system.debug( dataWrapper );
            return dataWrapper;
            
        } catch (Exception e) {
            system.debug( e.getMessage() + ' '+ e.getCause() + ' ' + e.getStackTraceString());
            ErrorLogger.createLog('ChartDataWrapper','getReportsData',e,null,'Apex Class'); 
            throw new D3ChartControllerException(e);
        }
    }
    
    public static Set<String> constructReportSetToQuery(){
        Set<String> reportNameSet = new Set<String>();
        reportNameSet.add(D3ChartUtility.ytdUniqueReportName);
        reportNameSet.add(D3ChartUtility.ytdActualReportName);
        reportNameSet.add(D3ChartUtility.ytdTripsReportName);
        // reportNameSet.add(D3ChartUtility.ytdTripsTrendReportName);
        // reportNameSet.add(D3ChartUtility.ytdUniqueTrendReportName);
        // reportNameSet.add(D3ChartUtility.ytdActualTrendReportName);
        
        
        
        reportNameSet.add(D3ChartUtility.mtdUniqueReportName );
        reportNameSet.add(D3ChartUtility.mtdActualReportName);
        reportNameSet.add(D3ChartUtility.mtdTripsReportName);
        
        // reportNameSet.add(D3ChartUtility.mtdUniqueTrendReportName) ;
        // reportNameSet.add(D3ChartUtility.mtdActualTrendReportName);
        // reportNameSet.add(D3ChartUtility.mtdTripsTrendReportName );
        
        reportNameSet.add(D3ChartUtility.mtdTheoReportName) ;
        reportNameSet.add(D3ChartUtility.ytdTheoReportName );
        
        return reportNameSet;
    }
    
    public static Map<Id,Report> getReportsQuery( Set<String> reportsName,String folderName){
        return new Map<Id,Report>( [SELECT Id,Name,FolderName FROM Report WHERE Name IN :reportsName AND FolderName =: folderName]);
    }
    
    
    public static String getTrendName( Decimal variance){
        String trend;
        if( variance > D3ChartUtility.trendRangeNumber){
            trend =  D3ChartUtility.trendUp;
        }
        
        if( variance < (-D3ChartUtility.trendRangeNumber) ){
            trend = D3ChartUtility.trendDown;
        }
        
        if( variance < D3ChartUtility.trendRangeNumber && (variance > (-D3ChartUtility.trendRangeNumber)) ){
            trend = D3ChartUtility.trendSame;
        }
    	return trend;
    }

    public static String getReportId( Map<Id,Report> reportMap, String reportName){
        Id reportId ;
        for( Id reportIdLoopVar : reportMap.keyset()){

            // *********** YTD Reports ******************
            if(reportMap.get(reportIdLoopVar).Name == reportName){
                reportId = reportIdLoopVar;
            }
        }
        return reportId;
    }

    public static String returnNumberInFormat(Decimal numbertoBeFormatted){

        //Ensure that decimal is at scale 2
        System.debug('numbertoBeFormatted1: ' + numbertoBeFormatted);
        numbertoBeFormatted = numbertoBeFormatted.setScale(2);
        System.debug('numbertoBeFormatted2: ' + numbertoBeFormatted);

        Boolean isNegative = false;
        
        Integer intValue = Integer.valueOf(numbertoBeFormatted);
        system.debug('intValue' + intValue);

        if(numbertoBeFormatted < 0){
            isNegative = true;
            intValue = Math.abs(intValue);
            numbertoBeFormatted = Math.abs(numbertoBeFormatted);
        }

        Integer decimalIndex = 0;
        String displayValue;
        if( intValue != null ){
            if(String.valueOf(intValue).length()  >= 7){
                
                displayValue = String.valueOf(numbertoBeFormatted/1000000);
                System.debug(displayValue);
                decimalIndex = displayValue.indexOf('.');
                displayValue = displayValue.substring(0,decimalIndex) + displayValue.substring(decimalIndex,decimalIndex+3)+ 'M';
                if(isNegative){
                    displayValue = '-$' + displayValue;
                }
                else{
                    displayValue = '$' + displayValue;
                }
                return displayValue;
            }
            if(String.valueOf(intValue).length()  >= 4){
                
                displayValue = String.valueOf(numbertoBeFormatted/1000);
                decimalIndex = displayValue.indexOf('.');
                displayValue = displayValue.substring(0,decimalIndex) + displayValue.substring(decimalIndex,decimalIndex+3)+ 'K';
                if(isNegative){
                    displayValue = '-$' + displayValue;
                }
                else{
                    displayValue = '$' + displayValue;
                }
                return displayValue;
            }
        }

        String tempString = '';
        if(isNegative){
            tempString = '-$' + String.valueOf(numbertoBeFormatted);
        }
        else{
            tempString = '$' + String.valueOf(numbertoBeFormatted);
        }

        return tempString;
       
    }

    public static ChartDataWrapper initialiseDefaultValues(ChartDataWrapper dataWrapper){
        dataWrapper.ytdUnique = String.valueOf(0);
        dataWrapper.ytdActual = String.valueOf(0);
        dataWrapper.ytdTrips  = String.valueOf(0);
        dataWrapper.mtdTrips = String.valueOf(0);
        dataWrapper.mtdUnique = String.valueOf(0);
        dataWrapper.mtdActual = String.valueOf(0);
        dataWrapper.mtdCurrent = 0;
        dataWrapper.ytdCurrent = 0;
        
        dataWrapper.mtdPercentageOverUnder = '0';
        dataWrapper.ytdPercentageOverUnder = '0';

        dataWrapper.mtdPercColor = 'black';
        dataWrapper.ytdPercColor = 'black';
        
        dataWrapper.mtdText = '';
        dataWrapper.ytdText = '';

        return dataWrapper;
    }
    

 
    public class ChartDataWrapper{
        
        @AuraEnabled public String ytdTrips{get; set;}
        @AuraEnabled public String ytdUnique{get; set;}
        @AuraEnabled public String ytdActual{get; set;}
        
        @AuraEnabled public String ytdTripsTrend{get; set;}
        @AuraEnabled public String ytdUniqueTrend{get; set;}
        @AuraEnabled public String ytdActualTrend{get; set;}
        
        @AuraEnabled public String mtdTrips{get; set;}
        @AuraEnabled public String mtdUnique{get; set;}
        @AuraEnabled public String mtdActual{get; set;}
        
        @AuraEnabled public String mtdTripsTrend{get; set;}
        @AuraEnabled public String mtdUniqueTrend{get; set;}
        @AuraEnabled public String mtdActualTrend{get; set;}
        
        
        @AuraEnabled public Decimal mtdTarget{get; set;}
        @AuraEnabled public Decimal mtdCurrent{get; set;}
        
        @AuraEnabled public Decimal ytdTarget{get; set;}
        @AuraEnabled public Decimal ytdCurrent{get; set;}

        @AuraEnabled public string ytdTripsReportId{get; set;}
        @AuraEnabled public string ytdUniqueReportId{get; set;}
        @AuraEnabled public string ytdActualReportId{get; set;}

        @AuraEnabled public string mtdTripsReportId{get; set;}
        @AuraEnabled public string mtdUniqueReportId{get; set;}
        @AuraEnabled public string mtdActualReportId{get; set;}

        @AuraEnabled public string mtdTheoReportId{get; set;}
        @AuraEnabled public string ytdTheoReportId{get; set;}

        @AuraEnabled public string mtdPercentageOverUnder {get; set;}
        @AuraEnabled public string ytdPercentageOverUnder {get; set;}

        @AuraEnabled public string mtdPercColor {get; set;}
        @AuraEnabled public string ytdPercColor {get; set;}

        @AuraEnabled public string mtdText {get; set;}
        @AuraEnabled public string ytdText {get; set;}
        
        public ChartDataWrapper(){}
    }

    public class D3ChartControllerException extends Exception{
       
    }

    public static String fetchUserSessionId(){
        String sessionId = '';
        // Refer to the Page
        PageReference reportPage = Page.D3ChartVFPage;
        String vfContent;
        // Get the content of the VF page
       if(Test.isRunningTest()) { 
            vfContent = 'Start_Of_Session_Id435ergfg45g56h56h56End_Of_Session_Id';

       }
       else{
            vfContent = reportPage.getContent().toString();
       }
        System.debug('vfContent '+vfContent);
        // Find the position of Start_Of_Session_Id and End_Of_Session_Id
        Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
        endP = vfContent.indexOf('End_Of_Session_Id');
        // Get the Session Id
        sessionId = vfContent.substring(startP, endP);
        System.debug('sessionId '+sessionId);
        
        // Return Session Id
        return sessionId;
    }
        
    public static Decimal calculateMonthTarget(Decimal mtdTarget, Decimal MTDTheoCurrent){

        Decimal mtdPercentageOverUnder = 0;
        if(mtdTarget == null){
            mtdTarget = 0;
        }
        if(MTDTheoCurrent == null){
            MTDTheoCurrent = 0;
        }
        
        //If Else condition to check first day of the Month
        if(Date.today().day() == 1){

            mtdPercentageOverUnder = 0;
        }
        else{

            Decimal daysInCurrentMonth = Date.daysInMonth(Date.today().year(),Date.today().month());
            Decimal monthTargetTilToDate = (mtdTarget / daysInCurrentMonth) * (Date.today().day() - 1);
            System.debug('monthTargetTilToDate: ' + monthTargetTilToDate);
            
            //Checker to prevent divide by 0
            if(monthTargetTilToDate == 0){
                mtdPercentageOverUnder = 0;
            }
            else{

                mtdPercentageOverUnder = ((MTDTheoCurrent - monthTargetTilToDate)/ monthTargetTilToDate ) * 100;
                System.debug('mtdPercentageOverUnder ' + mtdPercentageOverUnder);
            }
        }

        return mtdPercentageOverUnder;
    }

    public static Decimal calculateYearTarget(Decimal ytdTarget, Decimal YTDTheoCurrent){

        Decimal ytdPercentageOverUnder = 0;
        if(ytdTarget == null){
            ytdTarget = 0;
        }
        if(YTDTheoCurrent == null){
            YTDTheoCurrent = 0;
        }

        //If Else condition to check first day of the Year
        if(Date.today().day() == 1 && Date.today().month() == 7){

            ytdPercentageOverUnder = 0;
        }
        else{

            //Checker for FY 
            Date startOfFinancialYear = Date.valueOf(System.today().year() + '-07-01');
            Date endOfFinancialYear = Date.valueOf(System.today().year() + '-06-30');
            if(System.today() < startOfFinancialYear){
                startOfFinancialYear = startOfFinancialYear.addYears(-1);
            }
            if(System.today() > endOfFinancialYear){
                endOfFinancialYear = endOfFinancialYear.addYears(1);
            }

            Integer tempDaysBetween = startOfFinancialYear.daysBetween(System.today());

            Decimal daysInCurrentYear = startOfFinancialYear.daysBetween(endOfFinancialYear)+1;
            Decimal yearTargetTilToDate = (ytdTarget / daysInCurrentYear) * (tempDaysBetween);

            System.debug('********YTD Calculation');
            System.debug('yearTargetTilToDate' + yearTargetTilToDate);
            System.debug('daysInCurrentYear' + daysInCurrentYear);
            System.debug('tempDaysBetween' + tempDaysBetween);
            //Checker to prevent divide by 0
            if(yearTargetTilToDate == 0){

                ytdPercentageOverUnder = 0;
            }
            else{

                ytdPercentageOverUnder = ((YTDTheoCurrent - yearTargetTilToDate)/ yearTargetTilToDate ) * 100;
            }
            System.debug('ytdPercentageOverUnder' + ytdPercentageOverUnder);
        }

        return ytdPercentageOverUnder;
    }
}