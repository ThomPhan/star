/**
* Class Name  : Exl_WO_NextButtonUtil
* @author     : Capgemini
* @Description: Utility class to contain logic to return the Next Button to be set on Work Order for Revocation processing
* @version    : Version 1 : 3/11/2025
**/

public class Exl_WO_NextButtonUtil {

    private static final String STATUS_COMPLETED = 'Completed';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REVOKED = 'Revoked';
    public class FlowInputWrapper {
        @InvocableVariable(required=true) public String woID;
    }
    public class FlowOutputWrapper {
        @InvocableVariable public String nextButton;
        @InvocableVariable public Boolean woCompleted;
        @InvocableVariable public String error; // set if any failure occurs
    }    
    private class NextResult {
        String  nextButton;
        Boolean woCompleted;
    }
    
    @InvocableMethod(label='Compute Next Button for WO')
    public static List<FlowOutputWrapper> getWOForUpdate(List<FlowInputWrapper> input) {        
        List<FlowOutputWrapper> outs = new List<FlowOutputWrapper>();
        FlowOutputWrapper out = new FlowOutputWrapper();
        Id woID;
        
        try {
            woID = (Id) input[0].woID;
            system.debug('WOId: ' + woID);
            NextResult result = computeNext(woID);
            if (result == null) {
                out.error = 'Computation returned no result.';
            } else {
                out.nextButton = result.nextButton;
                out.woCompleted = result.woCompleted;
            }
        } catch (Exception ex) {
            out.error = 'Error encountered: ' + ex.getMessage();
            outs.add(out);
            return outs;
        }      
        outs.add(out);
        return outs;
    }    
    
    private static NextResult computeNext(Id woID) {
        NextResult next = new NextResult();
        
        List<WorkOrderLineItem> nextWOLI = [
            SELECT Id, Line_Item_Type__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :woID
            AND IsButton__c = true
            AND Status != :STATUS_COMPLETED 
            AND Status != :STATUS_APPROVED
            AND Status != :STATUS_REVOKED
            ORDER BY CreatedDate ASC, Id ASC
            LIMIT 1 ];
        next.nextButton = nextWOLI.isEmpty() ? null : nextWOLI[0].Line_Item_Type__c;
        system.debug('nextButton: ' + next.nextButton);
        
        Integer count = [
                SELECT COUNT()
                FROM WorkOrderLineItem
                WHERE WorkOrderId = :woID
                AND Status != :STATUS_COMPLETED
                AND Status != :STATUS_APPROVED
                AND Status != :STATUS_REVOKED
                AND Line_Item_Type__c != :next.nextButton ];
        next.woCompleted = count > 0 ? false : true;
        system.debug('woCompleted: ' + next.woCompleted);
        return next;        
	}
}