/**
* Class Name  : ExlNextButtonUtil
* Summary     : Helper invocable method for the 'WorkFlow' steps Screen flows   
* @author     : Capgemini
* @Description: This class contains the logic for user provisioning in Salesforce
* @version    : Version 1 : 08/11/2024
* Implements the agreed JSON mechanics using live WO/WOLI data:
* - CreatedDate, Id ordering
* - Common BOTH WorkOrder button precedence
* - Runtime origin/replicate from Case.Property__c
* - Replicate unlock via origin WOLI(StartReplicatedState__c = true, Status='Completed')
* - Each track goes null only when its own OPEN buttons are exhausted
* - Auto-close Case when everything is complete (no open common, no open WOLIs)
*
**/
public with sharing class ExlNextButtonUtil {
    
    
    
    // -----------------------------
    // Constants
    // -----------------------------
    private static final String STATUS_COMPLETED = 'Completed';
    private static final String STATUS_CLOSED    = 'Closed';
    private static final String NSW              = 'NSW'; // For comparison I am first convertingt the compared variable to upper case and then checking, so kept in Upper case here.
    private static final String QLD              = 'QLD'; // For comparison I am first convertingt the compared variable to upper case and then checking, so kept in Upper case here.
    private static final String BOTH             = 'BOTH'; // For comparison I am first convertingt the compared variable to upper case and then checking, so kept in Upper case here.
    
    // -----------------------------
    // Invocable I/O
    // -----------------------------
    public class FlowInputWrapper {
        @InvocableVariable(required=true) public String caseId;
        @InvocableVariable(required=true) public String wOLIId;
    }
    public class FlowOutputWrapper {
        @InvocableVariable public Boolean exclusionEnabledforReplicatedState;
        @InvocableVariable public String caseId;
        @InvocableVariable public String nextNSW;
        @InvocableVariable public String nextQLD;
        @InvocableVariable public Boolean caseClosed;
        @InvocableVariable public String error; // set if any failure occurs
    }
    
    // Internal compute DTO
    private class NextResult {
        String  nextNSW;
        String  nextQLD;
        Boolean closeCase;
        Boolean updateNSW;
        Boolean updateQLD;
        //Mark first-time replicate enable so we can assign owner just one time.
        Boolean replicateJustEnabled;
        String  replicateJurisdiction;
    }
    
    // -----------------------------
    // Public entry (single-record)
    // -----------------------------
    @InvocableMethod(
        label='Update Case Next Buttons (CreatedDate ordering)'
        description='Computes NSW/QLD next buttons from live WO/WOLI and updates Case; closes Case when all steps complete.'
    )
    public static List<FlowOutputWrapper> updateCaseAndReturn(List<FlowInputWrapper> reqs) {
        List<FlowOutputWrapper> outs = new List<FlowOutputWrapper>();
        FlowOutputWrapper out = new FlowOutputWrapper();
        
        try {
            // Validate input (single record expected)
            if (reqs == null || reqs.isEmpty() || reqs[0] == null || String.isBlank(reqs[0].caseId)) {
                out.error = 'Missing caseId.';
                outs.add(out);
                return outs;
            }
            Id caseId;
            Id wOLIId;
            
            try { 
                system.debug('***reqs[0] **'+reqs[0]);
                caseId = (Id) reqs[0].caseId; 
                wOLIId = reqs[0].wOLIId != null && reqs[0].wOLIId != 'null' ? (Id) reqs[0].wOLIId : null; 
            }
            catch (Exception e) {
                out.error = 'Invalid Case Id: ' + e.getMessage();
                outs.add(out);
                return outs;
            }
            
            out.caseId = (String)caseId;
            system.debug('caseId:: '+caseId);
            system.debug('wOLIId:: '+wOLIId);
            // Compute next values
            NextResult result = compute(caseId, wOLIId);
            if (result == null) {
                out.error = 'Computation returned no result.';
                outs.add(out);
                return outs;
            }
            system.debug('result '+result);
            if (result.replicateJustEnabled != null && result.replicateJustEnabled && !String.isBlank(result.replicateJurisdiction)) {
                try {
                        //Case updatedCase = new Case(Id = caseId, Exl_ReplicatedStateEnabled__c = result.replicateJustEnabled);
                        //update updatedCase; // single-field owner assignment
                        out.exclusionEnabledforReplicatedState = result.replicateJustEnabled;
                    
                } catch (DmlException d) {
                    out.error = 'Unexpected error: ' + d.getMessage();
                } catch (Exception e) {
                    out.error = 'Unexpected error: ' + e.getMessage();
                }
            }
            else{
                out.exclusionEnabledforReplicatedState = False;
            }
            
            // Success → return what we wrote
            out.nextNSW    = result.nextNSW;
            out.nextQLD    = result.nextQLD;
            out.caseClosed = result.closeCase;
            system.debug('Final ::--:: out '+out);
            
            
        } catch (Exception ex) {
            // Top-level safety net
            out.error = 'Unexpected error: ' + ex.getMessage();
            outs.add(out);
            return outs;
        }
        outs.add(out);
        return outs;
    }
    
    // -----------------------------
    // Core compute for a single Case
    // -----------------------------
    private static NextResult compute(Id caseId, Id wOLIId) {
        if (caseId == null) throw new AuraHandledException('caseId is required.');
        
        Case c;
        try {
            c = [
                SELECT Id, Property__c, Exl_Nextbutton_Qld__c, Exl_Nextbutton_NSW__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
        } catch (Exception qe) {
            throw new AuraHandledException('Case query failed: ' + qe.getMessage());
        }
        
        if (c == null) throw new AuraHandledException('Case not found: ' + (String)caseId);
        
        // 1) Determine origin vs replicate at runtime
        StatePair sp = determineStates(c.Property__c);
        
        String triggeringStateOfWOLI = wOLIId != null ? getTriggerStateWOLI(wOLIId) : sp.origin;
        String existingNSW = c.Exl_Nextbutton_NSW__c;
        String existingQld = c.Exl_Nextbutton_Qld__c;
        
        NextResult res = new NextResult();
        res.updateNSW = false;
        res.updateQLD = false;
        
        // 0) COMMON step → both fields show the common label if open
        String commonLabel = firstOpenCommonButton(caseId);
        if (commonLabel != null) {
            res.nextNSW   = commonLabel;
            res.nextQLD   = commonLabel;
            res.closeCase = false;
            return res;
        }
        
        
        
        // 2) Replicate unlock gate (origin completed a flagged WOLI)
        Boolean replicateUnlocked = isReplicateUnlocked(caseId, sp.origin);
        
        // 3) Per-state next
        String nextOrigin = nextForState(caseId, sp.origin);
        
        // allow replicate if unlocked OR origin has no next
        String nextReplicate = (replicateUnlocked || String.isBlank(nextOrigin))
            ? nextForState(caseId, sp.replicate)
            : null;
        System.debug('sp.origin ::----:: '+sp.origin);
        System.debug('triggeringStateOfWOLI ::----:: '+triggeringStateOfWOLI);
        System.debug('existingNSW ::----:: '+existingNSW);
        System.debug('existingQld ::----:: '+existingQld);
        System.debug('Case Origin ::----:: '+sp);
        System.debug('replicateUnlocked ::----:: '+replicateUnlocked);
        System.debug('nextOrigin ::----:: '+nextOrigin);
        System.debug('nextReplicate ::----:: '+nextReplicate);
        
        // Precompute flags for clarity
        Boolean woliIsNull   = (wOLIId == null);
        Boolean originIsNSW  = (sp.origin == NSW);
        Boolean woliIsQLD    = (wOLIId != null && triggeringStateOfWOLI == QLD);
        Boolean woliIsNSW    = (wOLIId != null && triggeringStateOfWOLI == NSW);
        
        if (originIsNSW) {
            if (woliIsNull) {
                // Origin NSW, new (no WOLI yet)
                res.nextNSW   = nextOrigin;
                res.updateNSW = true;
                
                res.nextQLD   = nextReplicate;
                res.updateQLD = true;
                
                // mark first-enable only if seeding replicate for the first time
                if (!String.isBlank(nextReplicate) && String.isBlank(existingQld)) {
                    res.replicateJustEnabled  = true;
                    res.replicateJurisdiction = QLD;
                }
                
            } else if (woliIsQLD) {
                // Origin NSW, but WOLI that fired is QLD (replicate path) → update replicate only
                res.nextQLD   = nextReplicate;
                res.updateQLD = true;
                
                res.nextNSW   = existingNSW; // No update to NSW
                
            } else {
                if (!woliIsNull) {
                    // Origin NSW, existing WOLI that was NSW
                    res.nextNSW   = nextOrigin;
                    res.updateNSW = true;
                    
                    // Update QLD only if we have a nextReplicate and QLD doesn't already have a value
                    if (!String.isBlank(nextReplicate) && String.isBlank(existingQld)) {
                        res.nextQLD   = nextReplicate;
                        res.updateQLD = true;
                        
                        // first-enable replicate (QLD)
                        res.replicateJustEnabled  = true;
                        res.replicateJurisdiction = QLD;
                        
                    } else {
                        res.nextQLD = existingQld;
                    }
                }
            }
            
        } else { // Origin is QLD
            if (woliIsNull) {
                // Origin QLD, new (no WOLI yet)
                res.nextQLD   = nextOrigin;
                res.updateQLD = true;
                
                res.nextNSW   = nextReplicate;
                res.updateNSW = true;
                
                // mark first-enable only if seeding replicate for the first time
                if (!String.isBlank(nextReplicate) && String.isBlank(existingNSW)) {
                    res.replicateJustEnabled  = true;
                    res.replicateJurisdiction = NSW;
                }
                
            } else if (woliIsNSW) {
                // Origin QLD, but WOLI that fired is NSW (replicate path) → update replicate only
                res.nextNSW   = nextReplicate;
                res.updateNSW = true;
                
                res.nextQLD   = existingQld; // No update to QLD
            } else {
                if (!woliIsNull) {
                    // Origin QLD, WOLI that fired is QLD
                    res.nextQLD   = nextOrigin;
                    res.updateQLD = true;
                    
                    // Update NSW only if we have a nextReplicate and NSW doesn't already have a value
                    if (!String.isBlank(nextReplicate) && String.isBlank(existingNSW)) {
                        res.nextNSW   = nextReplicate;
                        res.updateNSW = true;
                        // first-enable replicate (NSW)
                        res.replicateJustEnabled  = true;
                        res.replicateJurisdiction = NSW;
                        
                    } else {
                        res.nextNSW = existingNSW;
                    }
                }
                
            }
        }
        
        
        
        System.debug('nextNSW ::----:: '+res.nextNSW);
        System.debug('nextQLD ::----:: '+res.nextQLD);        
        
        Boolean noneLeft =
            (isBlankOrUnchanged(res.updateNSW, res.nextNSW, existingNSW) &&  // NSW shows no next
             isBlankOrUnchanged(res.updateQLD, res.nextQLD, existingQLD))    // QLD shows no next
            && noOpenCommonButton(caseId)
            && noOpenWoliAny(caseId);
        
        res.closeCase = noneLeft;
        return res;
    }
    
    // -----------------------------
    // Helper queries (single-shot, no loops)
    // -----------------------------
    
    private static Boolean isBlankOrUnchanged(Boolean willUpdate, String candidate, String existing) {
        if (willUpdate) return String.isBlank(candidate);
        // if we won’t update, treat existing value as “still has work” if it’s non-blank
        return String.isBlank(existing);
    }
    
    private static String getTriggerStateWOLI(Id wOLIId){
        if(wOLIId == null){
            return null;
        }
        try{
            WorkOrderLineItem wOLI = [SELECT Id, WorkOrder.Jurisdiction__c FROM WorkOrderLineItem WHERE Id =:  wOLIId];
            if(wOLI == null || wOLI.WorkOrder == null || String.isBlank(wOLI.WorkOrder.Jurisdiction__c)){
                return null;
            }
            String wOLI_State = (wOLI.WorkOrder.Jurisdiction__c).trim().toUpperCase();
            if(!String.isBlank(wOLI_State) && (wOLI_State == NSW || wOLI_State == QLD)){
                return wOLI_State;
            }
            return null;
        }
        Catch(Exception e){
            return null;
        }
    }
    
    // COMMON (BOTH/null/'') WO button still open?
    private static String firstOpenCommonButton(Id caseId) {
        try {
            List<WorkOrder> rows = [
                SELECT Id, WorkOrderType__c
                FROM WorkOrder
                WHERE CaseId = :caseId
                AND IsButton__c = true
                AND Status != :STATUS_COMPLETED
                AND (
                    Jurisdiction__c = :BOTH
                    OR Jurisdiction__c = null
                    OR Jurisdiction__c = ''
                )
                ORDER BY CreatedDate ASC, Id ASC
                LIMIT 1
            ];
            return rows.isEmpty() ? null : rows[0].WorkOrderType__c;
        } catch (Exception e) {
            // Treat errors as "no common button open"
            return null;
        }
    }
    
    // Replicate unlocked if any origin WOLI completed with StartReplicatedState__c = true
    private static Boolean isReplicateUnlocked(Id caseId, String originState) {
        if (String.isBlank(originState)) return false;
        try {
            // Existence check is cheaper than COUNT
            List<WorkOrderLineItem> gate = [
                SELECT Id
                FROM WorkOrderLineItem
                WHERE WorkOrder.CaseId = :caseId
                AND WorkOrder.Jurisdiction__c = :originState
                AND StartReplicatedState__c = true
                AND Status = :STATUS_COMPLETED
                LIMIT 1
            ];
            return !gate.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
    
    // Next label for a state: prefer WO-level button, else first WOLI button
    private static String nextForState(Id caseId, String state) {
        if (String.isBlank(state)) return null;
        
        // Prefer a state WorkOrder button
        try {
            List<WorkOrder> woBtn = [
                SELECT Id, WorkOrderType__c
                FROM WorkOrder
                WHERE CaseId = :caseId
                AND Jurisdiction__c = :state
                AND IsButton__c = true
                AND Status != :STATUS_COMPLETED
                ORDER BY CreatedDate ASC, Id ASC
                LIMIT 1
            ];
            if (!woBtn.isEmpty()) return woBtn[0].WorkOrderType__c;
        } catch (Exception e) {
            // Fall through to WOLI
        }
        
        // Else the first OPEN WOLI button
        try {
            List<WorkOrderLineItem> woli = [
                SELECT Id, Line_Item_Type__c
                FROM WorkOrderLineItem
                WHERE WorkOrder.CaseId = :caseId
                AND WorkOrder.Jurisdiction__c = :state
                AND IsButton__c = true
                AND Status != :STATUS_COMPLETED
                ORDER BY CreatedDate ASC, Id ASC
                LIMIT 1
            ];
            return woli.isEmpty() ? null : woli[0].Line_Item_Type__c;
        } catch (Exception e) {
            return null;
        }
    }
    
    // No open COMMON WO button?
    private static Boolean noOpenCommonButton(Id caseId) {
        try {
            Integer cnt = [
                SELECT COUNT()
                FROM WorkOrder
                WHERE CaseId = :caseId
                AND IsButton__c = true
                AND Status != :STATUS_COMPLETED
                AND (
                    Jurisdiction__c = :BOTH
                    OR Jurisdiction__c = null
                    OR Jurisdiction__c = ''
                )
            ];
            return cnt == 0;
        } catch (Exception e) {
            // Fail-safe: do not close case due to a query error
            return false;
        }
    }
    
    // No remaining WOLIs (button or non-button) left OPEN for the Case?
    private static Boolean noOpenWoliAny(Id caseId) {
        try {
            Integer cnt = [
                SELECT COUNT()
                FROM WorkOrderLineItem
                WHERE WorkOrder.CaseId = :caseId
                AND Status != :STATUS_COMPLETED
            ];
            return cnt == 0;
        } catch (Exception e) {
            // Fail-safe: do not close case due to a query error
            return false;
        }
    }
    
    // -----------------------------
    // Origin/Replicate resolution
    // -----------------------------
    private class StatePair { String origin; String replicate; }
    
    private static StatePair determineStates(String property) {
        StatePair sp = new StatePair();
        String p = (property == null) ? '' : property.trim().toLowerCase();
        
        if (p.contains('brisbane') || p.contains('gold coast') || p.contains('goldcoast') || p.contains('the star brisbane') || p.contains('the star gold coast') || p.contains('the star goldcoast')) {
            sp.origin = QLD; sp.replicate = NSW;
        } else if (p.contains('the star sydney') || p.contains('sydney') ) {
            sp.origin = NSW; sp.replicate = QLD;
        } else {
            // default
            sp.origin = NSW; sp.replicate = QLD;
        }
        return sp;
    }
    
}