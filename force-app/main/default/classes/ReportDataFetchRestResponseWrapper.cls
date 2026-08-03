/**
 * @description       : Class to store Rest response as part of report's data fetch operation
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 11-24-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-24-2020   sakshi.chauhan@simplus.com   Initial Version
**/
public class ReportDataFetchRestResponseWrapper {
   
    public Integer totalSize {get;set;} 
    public Boolean done {get;set;} 
    public List<Records> records {get;set;} 

    public class Attributes {
        public String type_Z {get;set;} // in json: type
    }
    
    public class Records {
        public Attributes attributes {get;set;} 
        public Double expr0 {get;set;} 
    }
}