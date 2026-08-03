/*******************************************************************************************************
* Class Name        : ShareWithHostTriggerHandler
* Description       : Custom Logic for sharing MTDYTD_Trend_Data__c records with Hosts. 
*                     Invoked from MTDYTDTrigger
* Author            : Simplus   
* Created On        : 12-11-2020
* Modification Log  : 
* -----------------------------------------------------------------------------------------------------
* Developer             Date                Description
* -----------------------------------------------------------------------------------------------------
* Sourabh Singh      12-Nov-2020            Initial version 
******************************************************************************************************/
public class ShareWithHostTriggerHandler 
{
    public static void processSharing(List<MTDYTD_Trend_Data__c> myDataListNew, 
                                      List<MTDYTD_Trend_Data__c> myDataListOld, 
                                      Map<Id,MTDYTD_Trend_Data__c> myDataMapNew, 
                                      Map<Id,MTDYTD_Trend_Data__c> myDataMapOld)
    {
        List<MTDYTD_Trend_Data__Share> MTDYTDShares = new List<MTDYTD_Trend_Data__Share>();
        try
        {
            for(MTDYTD_Trend_Data__c t : myDataListNew)
            {
                if(t.Host_Sydney__c !=null || (trigger.isUpdate && t.Host_Sydney__c != myDataMapOld.get(t.id).Host_Sydney__c)) //if insert or if update and host value has changed
                {
                    MTDYTD_Trend_Data__Share MTDShareRecord = new MTDYTD_Trend_Data__Share();
                    MTDShareRecord.ParentId = t.Id;     
                    
                    MTDShareRecord.UserOrGroupId = t.Host_Sydney__c;
                    MTDShareRecord.AccessLevel = 'Read';
                    
                    MTDShareRecord.RowCause = Schema.MTDYTD_Trend_Data__Share.RowCause.Host_Access__c;
                    MTDYTDShares.add(MTDShareRecord);
                }
                if(t.Host_Brisbane__c !=null || (trigger.isUpdate && t.Host_Brisbane__c != myDataMapOld.get(t.id).Host_Brisbane__c))//if insert or if update and host value has changed
                {
                    MTDYTD_Trend_Data__Share MTDShareRecord = new MTDYTD_Trend_Data__Share();
                    MTDShareRecord.ParentId = t.Id;
                    
                    MTDShareRecord.UserOrGroupId = t.Host_Brisbane__c;
                    MTDShareRecord.AccessLevel = 'Read';
                    
                    MTDShareRecord.RowCause = Schema.MTDYTD_Trend_Data__Share.RowCause.Host_Access__c;
                    MTDYTDShares.add(MTDShareRecord);
                }
                if(t.Host_GC__c !=null || (trigger.isUpdate && t.Host_GC__c != myDataMapOld.get(t.id).Host_GC__c))//if insert or if update and host value has changed
                {
                    MTDYTD_Trend_Data__Share MTDShareRecord = new MTDYTD_Trend_Data__Share();
                    MTDShareRecord.ParentId = t.Id;
                    
                    
                    MTDShareRecord.UserOrGroupId = t.Host_GC__c;
                    MTDShareRecord.AccessLevel = 'Read';
                    
                    MTDShareRecord.RowCause = Schema.MTDYTD_Trend_Data__Share.RowCause.Host_Access__c;
                    MTDYTDShares.add(MTDShareRecord);
                }
                if(t.Host_International__c !=null || (trigger.isUpdate && t.Host_International__c != myDataMapOld.get(t.id).Host_International__c))//if insert or if update and host value has changed
                {
                    MTDYTD_Trend_Data__Share MTDShareRecord = new MTDYTD_Trend_Data__Share();
                    MTDShareRecord.ParentId = t.Id;
                    
                    MTDShareRecord.UserOrGroupId = t.Host_International__c;
                    MTDShareRecord.AccessLevel = 'Read';
                    
                    MTDShareRecord.RowCause = Schema.MTDYTD_Trend_Data__Share.RowCause.Host_Access__c;
                    MTDYTDShares.add(MTDShareRecord);
                }
            }
            if(!MTDYTDShares.isEmpty())
                Database.SaveResult[] jobShareInsertResult = Database.insert(MTDYTDShares,false);
            
        }
        catch(Exception e) 
        {
            System.debug('Exception: ' + e.getMessage());    
        }
        
        If(Trigger.IsUpdate)
        {
            try
            {
                Set <Id> parentSet = new Set<Id>(); 
                Set <Id> userSet = new Set<Id>(); 
                
                for (MTDYTD_Trend_Data__c t:myDataListOld)
                {
                    parentSet.add(t.id);
                    if(t.Host_Sydney__c !=null && t.Host_Sydney__c != myDataMapNew.get(t.id).Host_Sydney__c &&
                       t.Host_Sydney__c != myDataMapNew.get(t.id).Host_GC__c &&
                       t.Host_Sydney__c != myDataMapNew.get(t.id).Host_Brisbane__c &&
                       t.Host_Sydney__c != myDataMapNew.get(t.id).Host_International__c)      
                        userSet.add(t.Host_Sydney__c);
                    
                    if(t.Host_GC__c !=null && t.Host_GC__c != myDataMapNew.get(t.id).Host_GC__c &&
                       t.Host_GC__c != myDataMapNew.get(t.id).Host_Sydney__c &&
                       t.Host_GC__c!= myDataMapNew.get(t.id).Host_Brisbane__c &&
                       t.Host_GC__c != myDataMapNew.get(t.id).Host_International__c)   
                        userSet.add(t.Host_GC__c); 
                    
                    if(t.Host_Brisbane__c !=null && t.Host_Brisbane__c != myDataMapNew.get(t.id).Host_Brisbane__c &&
                       t.Host_Brisbane__c != myDataMapNew.get(t.id).Host_GC__c &&
                       t.Host_Brisbane__c != myDataMapNew.get(t.id).Host_Sydney__c &&
                       t.Host_Brisbane__c != myDataMapNew.get(t.id).Host_International__c)
                        userSet.add(t.Host_Brisbane__c);  
                    
                    if(t.Host_International__c !=null && t.Host_International__c != myDataMapNew.get(t.id).Host_International__c &&
                       t.Host_International__c != myDataMapNew.get(t.id).Host_GC__c &&
                       t.Host_International__c != myDataMapNew.get(t.id).Host_Brisbane__c &&
                       t.Host_International__c != myDataMapNew.get(t.id).Host_Sydney__c)
                       userSet.add(t.Host_International__c);    
                }
                
                List<MTDYTD_Trend_Data__Share > sharesToDelete = 
                    [Select UserOrGroupId, RowCause,ParentId From MTDYTD_Trend_Data__Share 
                     where RowCause=:Schema.MTDYTD_Trend_Data__Share.RowCause.Host_Access__c and  ParentId in:parentSet and UserOrGroupId in:userSet];
                
                if (!sharesToDelete.isEmpty()) 
                    delete sharesToDelete;
            }
            catch(Exception e) 
            {
                System.debug('Exception: ' + e.getMessage());    
            }
        }     
    }
}