/**
 * Class Name  : ErrorLogger
 * Summary     : Apex Class for creating of new Platform Event (Error_Event__e) record upon calling createLog method 
 * Method     :  createLog     
 * @author       Simplus
   @Description: This class contains the logic for the insertion of record for Error_Event__e Platform Event
 * @version      $Revision: 1.0 $, $Date: 20/July/2020 
 */
public class ErrorLogger {
    //Main Method for Insert
    public static void createLog(String apexClass, String methodName, Exception ex, String recordId,String componentType){
        try{
            //Holds the list of events for insert
            List<Error_Event__e> errEvents = new List<Error_Event__e>();
            if(ex != null){
                //Create new record in Error_Event__e platform event
                errEvents.add(new Error_Event__e(Apex_Class__c = apexClass,
                                                 Component_Type__c = componentType,
                                                 Error_Records__c = 'Line ' + String.valueOf(ex.getLineNumber()),
                                                 Message__c = ex.getMessage(),
                                                 Method__c = methodName,
                                                 Stack_Trace__c = ex.getStackTraceString(),
                                                 Type__c = ex.getTypeName(),
                                                 User__c = UserInfo.getName(),
                                                 Record_ID__c = recordId));
            }else{
				errEvents.add(new Error_Event__e(Apex_Class__c = apexClass,
                                                 Component_Type__c = componentType,
                                                 Error_Records__c = 'No Lines',
                                                 Message__c = 'Error in Integration',
                                                 Method__c = methodName,
                                                 Stack_Trace__c = 'Integration',
                                                 Type__c = 'Integration',
                                                 User__c = UserInfo.getName(),
                                                 Record_ID__c = recordId));                
            }
            //Insert the event
            List<Database.SaveResult> results = Eventbus.publish(errEvents);
            //Check if the event is inserted
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }
            }
        } catch (Exception e){
            System.debug('Error: ' + e.getMessage());
        }
    }
}