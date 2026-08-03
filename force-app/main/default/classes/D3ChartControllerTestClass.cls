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
@isTest
public class D3ChartControllerTestClass {

    public static Boolean testException = false;
    @isTest(SeeAllData='true')
    static void testGetReportsData(){
     
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ReportsDataFetchRestServiceMockImpl());
            D3ChartController.getReportsData();
            
        Test.stopTest();
        
    }


    @isTest
    static void testReportControllerException(){
       
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ReportsDataFetchRestServiceMockImpl());           
            try{
                testException = true;
                D3ChartController.getReportsData();
            }
            catch(Exception e){
                system.assert(e!=null);
            }            
        Test.stopTest();
        
    }

    @isTest
    static void testGetTrendName(){

        Test.startTest();
            
            String trend = D3ChartController.getTrendName(15.6);
            system.assertEquals(trend,D3ChartUtility.trendUp);
            trend = D3ChartController.getTrendName(-15.6);
            system.assertEquals(trend,D3ChartUtility.trendDown);
            trend = D3ChartController.getTrendName(-4);
            system.assertEquals(trend,D3ChartUtility.trendSame);
        Test.stopTest();
        
    }

    @isTest
    static void testReturnNumberInFormat(){
        
        Test.startTest();
           
            String format = D3ChartController.returnNumberInFormat(1230000.03);
            system.debug('format ' + format);
            system.assertEquals(format,'$1.23M');

            String format2 = D3ChartController.returnNumberInFormat(123000.03);
            system.debug('format2 ' + format2);
            system.assertEquals(format2,'$123.00K');
        
        Test.stopTest();
    }
    
    
}