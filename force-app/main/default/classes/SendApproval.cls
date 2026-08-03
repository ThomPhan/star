/* Description:
 * Author:
 * History:
 * 
 */
public without sharing class SendApproval {
    private static final String GROUPTYPEREGULAR = 'Regular';
    private static final String USERIDPREFIX = '005';
    
    @AuraEnabled
    public static List<Group> getAllPublicGroups(){
        Set<String> groupNameSet = new Set<String>();
        groupNameSet.add(Label.QLD_Approvers);
        groupNameSet.add(Label.NSW_Approvers);
        List<Group> groupList = new List<Group>();
        
        try{
            for(Group groupObj : [SELECT Id, Name FROM Group WHERE Type =: GROUPTYPEREGULAR AND Name IN : groupNameSet]){
                groupList.add(groupObj);
            }
        }catch(QueryException qExcp){
            System.debug(qExcp.getStackTraceString());
            System.debug(qExcp.getMessage());            
        }
        
        return groupList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getAllGroupMembers(Id groupId){
        Set<Id> userIdSet = new Set<Id>();
        List<User> userList = new List<User>();
        
        try{
            for(GroupMember groupMemberObj : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: groupId]){
                if(String.valueOf(groupMemberObj.UserOrGroupId).startsWith(USERIDPREFIX)){
                    userIdSet.add(groupMemberObj.UserOrGroupId);
                }
            }
            
            if(userIdSet != NULL){
                for(User userObj : [SELECT Id, Name FROM User WHERE Id IN : userIdSet ORDER BY Name]){
                    userList.add(userObj);
                }
            }
        }catch(QueryException qExcp){
            System.debug(qExcp.getStackTraceString());
            System.debug(qExcp.getMessage());            
        }
        
        return userList;
    }
    
    @AuraEnabled
    public static void submitAndProcessApprovalRequest(Id checklistId, Id approverId, String approvalProcessName) {
        System.debug('@@@approvalProcessName ' + approvalProcessName);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(checklistId);
        req1.setProcessDefinitionNameOrId(approvalProcessName);
        req1.setNextApproverIds(new List<Id>{approverId});
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
    }
    
}