/**
 * Class Name  : ErrorEventTriggerHandler
 * Summary     : Helper class for the 'ErrorEventTrigger' trigger 
 * Method     :  createErrorLog     
 * @author       Simplus
   @Description: This class contains the logic for the insertion of record for ErroLog__c Object
 * @version      $Revision: 1.0 $, $Date: 20/July/2020 
 */
public class ErrorEventTriggerHandler
extends TriggerHandlerBase //extending the trigger framework
{
    public ErrorEventTriggerHandler(String triggerName) {
    	super(triggerName);
    }  

	public override void afterInsert(List<SObject> record, Map<ID, SObject> newRecordMap){
        //Check if the Custom Setting Enable Error Logging checkbox is checked
        ErrorLoggingSettings__c getCustSetting = ErrorLoggingSettings__c.getOrgDefaults();
        if(getCustSetting.Enable_Error_Logging__c == true){
            //Calls the Helper Class along with its method name
            ErrorEventTriggerHandler.createErrorLog(record);
        }        
    }    

    public static void createErrorLog(List<Error_Event__e> errEvents){
        try{
            //Holds the records to be inserted
            List<ErrorLog__c> errLogInsert = new List<ErrorLog__c>();
            //For each platform event (Error_Event__e) that is saved
            for(Error_Event__e evt : errEvents){
                //UserInfo.getName() = get the current user that triggered this
                errLogInsert.add(new ErrorLog__c(Apex_Class__c = evt.Apex_Class__c,
                                                Component_Type__c = evt.Component_Type__c,
                                                Error_Records__c = evt.Error_Records__c,
                                                Message__c = evt.Message__c,
                                                Method__c = evt.Method__c,
                                                Stack_Trace__c = evt.Stack_Trace__c,
                                                Type__c = evt.Type__c,
                                                User__c = evt.User__c,
                                                Record_ID__c = evt.Record_ID__c));
            }
            if(errLogInsert.size() > 0){
                insert errLogInsert;
            }
        } catch (Exception ex){
            System.debug('Error: ' + ex.getMessage());
        }
    }
}