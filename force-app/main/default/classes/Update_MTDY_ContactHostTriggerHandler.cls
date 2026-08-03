/**
* @File Name          : Update_MTDY_ContactHostTriggerHandler
* @Description        : 
* @Author             : Lawrence Faith Abella
* @Group              : Simplus
* @Last Modified By   : Lawrence Faith Abella
* @Last Modified On   : 12/03/21
* @Description 		  : Field Mapping 
Update ContactId mapping from Contact Host fields into MTD YTD trend object everytime there is a change on the MTDYTD Records.
MTDYTD_Trend_Data__c.Contact__c  
MTDYTD_Trend_Data__c.Host_Brisbane__c
MTDYTD_Trend_Data__c.Host_GC__c
MTDYTD_Trend_Data__c.Host_International__c
MTDYTD_Trend_Data__c.Host_Sydney
FROM 
Contact.Contact__c  
Contact.Host_Brisbane__c
Contact.Host_GC__c
Contact.Host_International__c
Contact.Host_Sydney
*/
public class Update_MTDY_ContactHostTriggerHandler {
    
    public static void updatContactHostMapping(List<MTDYTD_Trend_Data__c>MTDYListNew)
    {
        
        Set<String> patronId = new Set<String>();
        Map<String, Contact> contactPatronMap = new Map<String, Contact>();
        
        for(MTDYTD_Trend_Data__c mt : MTDYListNew)
        {
            if(mt.Patron_ID__c !=null)
            {
                patronId.add(mt.Patron_ID__c);
            }
        }
         for(Contact c : [Select Id,Patron_ID__c,Host_Brisbane__c, Host_International__c,Host_GC__c,Host_Sydney__c 
                         From Contact 
                         Where Patron_ID__c in: patronId])
        {
            system.debug('CONTACTS : ----> ' +c);
            contactPatronMap.put(c.Patron_ID__c,c);
        }
        
        for(MTDYTD_Trend_Data__c mtdy :MTDYListNew )
        {
            if(mtdy.Patron_ID__c != Null)
            {
                if(contactPatronMap.containsKey(mtdy.Patron_ID__c))
                {
                    Contact con = contactPatronMap.get(mtdy.Patron_ID__c);
                    
                    System.debug('CONTACT INSIDE LOOP : -------------------> '+con);
                    if(con != Null)
                    {
                        mtdy.Contact__c 			= con.id;
                        mtdy.Host_Brisbane__c 		= con.Host_Brisbane__c ;
                        mtdy.Host_GC__c         	= con.Host_GC__c ;
                        mtdy.Host_International__c	= con.Host_International__c;
                        mtdy.Host_Sydney__c   		= con.Host_Sydney__c;
                        System.debug('MTDYTD CONTACT -------> '+ mtdy.Contact__c);
                    }
                }
            }
        }
        System.debug('1. Number of Queries used in this Apex code so far: ' + Limits.getQueries());
        System.debug('2. Number of rows queried in this Apex code so far: ' + Limits.getDmlRows());
        System.debug('3. Number of DML statements used so far: ' +  Limits.getDmlStatements());   
        System.debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
        system.debug('Contact PATRON ID MAP --------> '+contactPatronMap);
        System.debug('Patron ID SET : ---> '+patronId);
     }    
}