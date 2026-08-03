/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-11-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-03-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class ChartPOCController {
    
    /**
    * @description method to return data for Gauge chart in lightning component GaugeChartComponent
    * @author sakshi.chauhan@simplus.com | 11-03-2020 
    * @return string JSON
    **/
    @AuraEnabled
    public static ChartDataWrapper getReportsData(){
        try {

            Set<String> reportsToQuery = constructReportSetToQuery();
            Map<Id,Report> reportMap = getReportsQuery(reportsToQuery,ChartPOCUtility.reportsFolderName);
            system.debug('reportMap ' + reportMap);

            ChartDataWrapper dataWrapper = new ChartDataWrapper();
            User userObj = [ SELECT  MTD_Target__c,YTD_Target__c FROM  User WHERE ID =: System.UserInfo.getUserId()];
            // dataWrapper.ytdTarget = String.valueOf(UserObj.YTD_Target__c);
            // dataWrapper.mtdTarget = String.valueOf(userObj.MTD_Target__c);
            dataWrapper.mtdTarget = '150043';
            dataWrapper.ytdTarget = '16054';

            

            for(Id reportId : reportMap.keyset()){
                system.debug('reportId '+ reportId);
                system.debug('Report Name ' + reportMap.get(reportId).Name);
                //run report

                // Reports.ReportInstance instance = Reports.ReportManager.runAsyncReport(reportId, true);

                // system.debug(Reports.ReportManager.getReportInstances(reportId));
                Reports.reportResults results = Reports.ReportManager.runReport(reportId, true);

                //get report metadata
                Reports.ReportMetadata rm = results.getReportMetadata();
                
                // Check report format
                if(  String.valueOf(rm.getReportFormat()) == 'SUMMARY'){
                   
                    Reports.ReportFactWithDetails factDetails1 = (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');

                    //get the aggregate values in the report, this includes the RowCount (Grand Total) and any columns that have been summarized.
                    List<Reports.SummaryValue> summVal = factDetails1.getAggregates();

                    // ****************  YTD Values **************** 
                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdUniqueReportName){
                        dataWrapper.ytdUnique = summVal.get(0).getlabel();
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdActualReportName){
                        dataWrapper.ytdActual = (Decimal)summVal.get(0).getvalue();
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdTripsReportName){
                        dataWrapper.ytdTrips = summVal.get(0).getlabel();
                    }

                    // **************** YTD Trend **************** 
                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdUniqueTrendReportName){
                        dataWrapper.ytdUniqueTrend = getTrendName((Decimal)summVal.get(2).getValue());
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdActualTrendReportName){
                        dataWrapper.ytdActualTrend = getTrendName((Decimal)summVal.get(2).getValue());
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdTripsTrendReportName){    
                        dataWrapper.ytdTripsTrend = getTrendName((Decimal)summVal.get(2).getValue());
                    }

                    // ****************  MTD Values **************** 
                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdUniqueReportName){
                        dataWrapper.mtdUnique = summVal.get(0).getlabel();
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdActualReportName){
                        dataWrapper.mtdActual = (Decimal)summVal.get(0).getvalue();
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdTripsReportName){
                        dataWrapper.mtdTrips = summVal.get(0).getlabel();
                    }

                    // ****************  MTD Trend **************** 
                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdUniqueTrendReportName){
                        dataWrapper.mtdUniqueTrend = getTrendName( (Decimal)summVal.get(2).getValue() );
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdActualTrendReportName){
                        dataWrapper.mtdActualTrend = getTrendName( (Decimal)summVal.get(2).getValue() );
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdTripsTrendReportName){
                        dataWrapper.mtdTripsTrend = getTrendName( (Decimal)summVal.get(2).getValue() );
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.mtdTheoReportName){
                        dataWrapper.mtdCurrent = summVal.get(0).getLabel() ;
                    }

                    if(reportMap.get(reportId).Name == ChartPOCUtility.ytdTheoReportName){
                        dataWrapper.ytdCurrent = summVal.get(0).getLabel() ;
                    }
                }
            }
            // return JSON.serialize(wrapperObj);
            system.debug( dataWrapper );
            return dataWrapper;

        } catch (Exception e) {
            system.debug( e.getMessage() + ' '+ e.getCause() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    public static Set<String> constructReportSetToQuery(){
        Set<String> reportNameSet = new Set<String>();
        reportNameSet.add(ChartPOCUtility.ytdUniqueReportName);
        reportNameSet.add(ChartPOCUtility.ytdActualReportName);
        reportNameSet.add(ChartPOCUtility.ytdTripsReportName);
        reportNameSet.add(ChartPOCUtility.ytdTripsTrendReportName);
        reportNameSet.add(ChartPOCUtility.ytdUniqueTrendReportName);
        reportNameSet.add(ChartPOCUtility.ytdActualTrendReportName);



        reportNameSet.add(ChartPOCUtility.mtdUniqueReportName );
        reportNameSet.add(ChartPOCUtility.mtdActualReportName);
        reportNameSet.add(ChartPOCUtility.mtdTripsReportName);

        reportNameSet.add(ChartPOCUtility.mtdUniqueTrendReportName) ;
        reportNameSet.add(ChartPOCUtility.mtdActualTrendReportName);
        reportNameSet.add(ChartPOCUtility.mtdTripsTrendReportName );

        reportNameSet.add(ChartPOCUtility.mtdTheoReportName) ;
        reportNameSet.add(ChartPOCUtility.ytdTheoReportName );

        return reportNameSet;
    }

    public static Map<Id,Report> getReportsQuery( Set<String> reportsName,String folderName){
        return new Map<Id,Report>( [SELECT Id,Name,FolderName FROM Report WHERE Name IN :reportsName AND FolderName =: folderName]);
    }
    

    public static String getTrendName( Decimal variance){
        if( variance > ChartPOCUtility.trendRangeNumber){
            return 'trendup';
        }

        if( variance < (-ChartPOCUtility.trendRangeNumber) ){
            return 'trenddown';
        }

        if( variance < ChartPOCUtility.trendRangeNumber && (variance > (-ChartPOCUtility.trendRangeNumber)) ){
            return 'trendsame';
        }
        return null;
    }


    public class ChartDataWrapper{

        @AuraEnabled public String ytdTrips{get; set;}
        @AuraEnabled public String ytdUnique{get; set;}
        @AuraEnabled public Decimal ytdActual{get; set;}

        @AuraEnabled public String ytdTripsTrend{get; set;}
        @AuraEnabled public String ytdUniqueTrend{get; set;}
        @AuraEnabled public String ytdActualTrend{get; set;}

        @AuraEnabled public String mtdTrips{get; set;}
        @AuraEnabled public String mtdUnique{get; set;}
        @AuraEnabled public Decimal mtdActual{get; set;}

        @AuraEnabled public String mtdTripsTrend{get; set;}
        @AuraEnabled public String mtdUniqueTrend{get; set;}
        @AuraEnabled public String mtdActualTrend{get; set;}
    
        
        @AuraEnabled public String mtdTarget{get; set;}
        @AuraEnabled public String mtdCurrent{get; set;}

        @AuraEnabled public String ytdTarget{get; set;}
        @AuraEnabled public String ytdCurrent{get; set;}

        public ChartDataWrapper(){}
    }
}