/**
* Class Name  : UserTriggerHandler
* Summary     : Helper class for the 'User' trigger   
* @author     : Capgemini
* @Description: This class contains the logic for user provisioning in Salesforce
* @version    : Version 1 : 08/11/2024
              : Version 2 : 11/11/2024
              : Version 3 : 14/11/2024  
              : Version 4 : 20/3/2025 - Added logic to set UserPermissionsMarketingUser true for event marketing, premium guest, interstate, local telesales and loyalty marketing ops persona
			  : Version 5 : 17/11/2025 - Added logic for Exclusion Management app to support multiple public group assignments to Exclusion Personas.
**/
public class UserTriggerHandler extends TriggerHandlerBase {
    static final String APEXCLASSNAME = 'UserTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';
    
    private static Map<String, ID> allRolesMap;
    private static Map<String, Id> orgPermissionSetMap;
    private static Map<String, Id> orgPublicGroupMap;
    private static Map<String, String> rolesPersonaMap;
    private static Id baseProfileId;
    private static Boolean hasRun = false;

    //SVOC-499 defect fix added campaignAccess UserPermissions MarketingUser
    static final Map<String, boolean> personaVsCampaignAccessPermissionMap = new Map<String, boolean>{'Event Marketing' => true,'Premium Guest' => true, 'Interstate' => true, 'Local Telesales' => true, 'Loyalty Marketing Ops' => true};
    
    //Adding the provisioning step to grant flow access to Exclusions personas, ensuring they can perform Apply Exclusions, Apply Revocations, Apply Contraventions, and all related screen‑flow actions.
	static final Map<String, boolean> personaVsFlowAccessPermissionMap = new Map<String, boolean>
	{
	'CLM App' => true,
	'CLM App Rev' => true, 
	'SG WR' => true, 
	'AP WR' => true, 
	'Inv WR' => true,
	'Surv RD' => true,
    'FinCrime Tech' => true
	};
            
    public UserTriggerHandler(String triggerName) {
        super(triggerName);
        if (allRolesMap == null) allRolesMap = getAllRolesMap();
        if (orgPermissionSetMap == null) orgPermissionSetMap = getAllPermissionSetsMap();
        if (orgPublicGroupMap == null) orgPublicGroupMap = getAllPublicGroupMap();
        if (rolesPersonaMap == null) rolesPersonaMap = getRolePersonaMap();
        if (baseProfileId == null) baseProfileId = getBaseProfileId();
    }
    
    //before insert
    public override void beforeInsert(List<SObject> newRecords){
        if (!isAllowedUser()) return; //CRM2-4002

        List<User> newUsers = (List<User>)newRecords;
        for(User newUser: newUsers){
            if(newUser.ProfileId == baseProfileId){
                String primaryPersona = getPrimaryPersona(newUser.Personas__c);
                Id roleId = allRolesMap.get(rolesPersonaMap.get(primaryPersona));
                newUser.UserRoleId =  roleId;
                //SVOC-499 defect fix added campaignAccess UserPermissions MarketingUser
                if(newUser.Personas__c != null && newUser.Personas__c != ''){
                    List<String> existingPersonaSet = newUser.Personas__c.split(';');
                    for(String persona: existingPersonaSet){
                        if(personaVsCampaignAccessPermissionMap.containsKey(persona) || personaVsFlowAccessPermissionMap.containsKey(persona)){
                            if(personaVsCampaignAccessPermissionMap.containsKey(persona)){
                                newUser.UserPermissionsMarketingUser = personaVsCampaignAccessPermissionMap.get(persona);
                            }
                            //Adding the provisioning step to grant flow access to Exclusions personas, ensuring they can perform Apply Exclusions, Apply Revocations, Apply Contraventions, and all related screen‑flow actions.
                            if(personaVsFlowAccessPermissionMap.containsKey(persona)){
                                newUser.UserPermissionsInteractionUser = personaVsFlowAccessPermissionMap.get(persona);
                            }                            
                            break;
                        }
                    }
                }
            }
        }
    }
    
    //Before update
    public override void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap){
        if (!isAllowedUser()) return; //CRM2-4002

        Map<Id, User> oldUsersMap = (Map<Id, User>)oldRecordMap;
        Map<Id, User> newUsersMap = (Map<Id, User>)newRecordMap;
        
        /*Map<String, ID> allRolesMap = getAllRolesMap();
        Map<String, String> rolesPersonaMap = getRolePersonaMap();*/
        for (Id userId : newUsersMap.keySet()) {
            User oldUser = oldUsersMap.get(userId);
            User newUser = newUsersMap.get(userId);
            if(newUser.ProfileId == baseProfileId && hasPersonasChanged(oldUser, newUser)){
                String newPrimaryPersona = getPrimaryPersona(newUser.Personas__c);
                String oldPrimaryPersona = getPrimaryPersona(oldUser.Personas__c);
                //System.debug('newPrimaryPersona --> '+newPrimaryPersona);
                //System.debug('oldPrimaryPersona --> '+oldPrimaryPersona);
                if(getRoleNameByPersona(newPrimaryPersona) != getRoleNameByPersona(oldPrimaryPersona)){
                    Id roleId = allRolesMap.get(rolesPersonaMap.get(newPrimaryPersona));
                	newUser.UserRoleId =  roleId;
                }
            }
        }
        //SVOC-499 defect fix added campaignAccess UserPermissions MarketingUser
        for(User newUserRec : (List<User>)newRecords){
            if(newUserRec.Personas__c != null && newUserRec.Personas__c != ''){
                List<String> existingPersonaSet = newUserRec.Personas__c.split(';');
                for(String persona: existingPersonaSet){
                    if(personaVsCampaignAccessPermissionMap.containsKey(persona) || personaVsFlowAccessPermissionMap.containsKey(persona)){
                        if(personaVsCampaignAccessPermissionMap.containsKey(persona)){
                            newUserRec.UserPermissionsMarketingUser = personaVsCampaignAccessPermissionMap.get(persona);
                        }
                        else{
                            newUserRec.UserPermissionsMarketingUser = false;
                        }
                        //Adding the provisioning step to grant flow access to Exclusions personas, ensuring they can perform Apply Exclusions, Apply Revocations, Apply Contraventions, and all related screen‑flow actions.
                        if(personaVsFlowAccessPermissionMap.containsKey(persona)){
                            newUserRec.UserPermissionsInteractionUser = personaVsFlowAccessPermissionMap.get(persona);
                        }
                        else{
                            newUserRec.UserPermissionsInteractionUser = false;
                        }
                        break;
                    }
                }
            }
        }
    }
    
    //After Insert
    public override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap){        
        List<User> newUsers = (List<User>)newRecords;
        List<User> updatedUsers = new List<User>(); 		        
        for (User newUser : newUsers) {
            if(newUser.ProfileId == baseProfileId){
                updatedUsers.add(newUser);
            }
        }
        if (!updatedUsers.isEmpty()) {
            assignPermissionsAndGroups(updatedUsers, null);
        }
        
    }
    
    //After Update
    public override void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap){
        Map<Id, User> oldUsersMap = (Map<Id, User>)oldRecordMap;
        Map<Id, User> newUsersMap = (Map<Id, User>)newRecordMap;
        List<User> updatedUsers = new List<User>();
		        
        for (Id userId : newUsersMap.keySet()) {
            User oldUser = oldUsersMap.get(userId);
            User newUser = newUsersMap.get(userId);
            
            if (hasPersonasChanged(oldUser, newUser) && newUser.ProfileId == baseProfileId) {
                updatedUsers.add(newUser);
            }          
        }
        if (!updatedUsers.isEmpty()) {
            assignPermissionsAndGroups(updatedUsers, oldUsersMap);
        }  
    }
    
    //CRM2-4002
	// Validates if user is allowed to run trigger logic
    private static Boolean isAllowedUser() {
        String fullName = UserInfo.getName();
        String allowedUsersLabel = System.Label.UserTrigger_Allowed_Users;
    
        Set<String> allowedUsers = new Set<String>();
    
        for (String name : allowedUsersLabel.split('\\n')){
            allowedUsers.add(name.trim().toLowerCase());
        }
    
        return allowedUsers.contains(fullName != null ? fullName.toLowerCase() : '');
    }
    
    private static void assignPermissionsAndGroups(List<User> users, Map<Id, User> oldUserMap) {
        System.debug('assignPermissionsAndGroups called');
        if(hasRun){
            return;
        }
        Set<Id> userIds = new Set<Id>();
        for (User user : users) {
            userIds.add(user.Id);
        }
        hasRun = true;
        //Get all Permission Sets in org
        //Map<String, Id> orgPermissionSetMap = getAllPermissionSetsMap();        
        // Query existing permissions, roles, and groups for these users                  
        Map<Id, Set<String>> currentPermissionSets = new Map<Id, Set<String>>();
        Map<Id, Set<Id>> currentGroups = new Map<Id, Set<Id>>();
        Map<Id, List<PermissionSetAssignment>> currentPermissionSetAssigmentMap = new Map<Id, List<PermissionSetAssignment>>();  
        
        //Get Map of Group Name and Group ID
        //Map<String, Id> orgPublicGroupMap = getAllPublicGroupMap();
        Set<GroupMember> groupMembersToRemove = new Set<GroupMember>();
        Map<Id, List<GroupMember>> currentUserGroupMap = new Map<Id, List<GroupMember>>();
        
        // Retrieve existing PermissionSetAssignments for users
        for (PermissionSetAssignment psa : [SELECT Id, AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId IN :userIds
                                            AND PermissionSet.IsOwnedByProfile = false]) {
                                                System.debug('PermissionSetAssignment query called -->');
              if (!currentPermissionSets.containsKey(psa.AssigneeId)) {
                    currentPermissionSets.put(psa.AssigneeId, new Set<String>());
                    currentPermissionSetAssigmentMap.put(psa.AssigneeId, new List<PermissionSetAssignment>());
                 }
                    currentPermissionSets.get(psa.AssigneeId).add(psa.PermissionSet.Name);
                    currentPermissionSetAssigmentMap.get(psa.AssigneeId).add(psa);
        }
        
        // Retrieve existing GroupMemberships for users
        for (GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE UserOrGroupId IN :userIds]) {
            if (!currentGroups.containsKey(gm.UserOrGroupId)) {
                currentGroups.put(gm.UserOrGroupId, new Set<Id>());
                currentUserGroupMap.put(gm.UserOrGroupId, new List<GroupMember>());
            }
            currentGroups.get(gm.UserOrGroupId).add(gm.GroupId);
            currentUserGroupMap.get(gm.UserOrGroupId).add(gm);
        }
        
        // Prepare new permissions, roles, and group assignments
        List<PermissionSetAssignment> permissionsToAdd = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> permissionsToRemove = new List<PermissionSetAssignment>();
        List<User> usersToUpdateRole = new List<User>();
        List<GroupMember> groupsToAdd = new List<GroupMember>();
        List<GroupMember> groupsToRemove = new List<GroupMember>();
        
        for (User user : users) {
            Set<String> requiredPermissionSets = getRequiredPermissionSets(user.Personas__c); 
            Set<String> currentPerms = currentPermissionSets.get(user.Id) != null ? currentPermissionSets.get(user.Id) : new Set<String>();
            if(requiredPermissionSets != null){
                for(String ps:requiredPermissionSets){
                    if(!currentPerms.contains(ps)){
                        permissionsToAdd.add(new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = orgPermissionSetMap.get(ps)));  
                    }
                }  
            }  
                List<PermissionSetAssignment> psaList = currentPermissionSetAssigmentMap.get(user.Id);
                for (String psName : currentPerms) {
                    if (psaList != null) {
                        for (PermissionSetAssignment psa : psaList) {
                            // Check if requiredPermissionSets is not null and does not contain psName
                            if (requiredPermissionSets == null || !requiredPermissionSets.contains(psName)) {
                                if (psa.PermissionSetId == orgPermissionSetMap.get(psName)) {
                                    permissionsToRemove.add(psa);
                                }
                            }
                        }
                    }
                    
                }
            
            // Group membership logic
            Set<Id> requiredGroupIds = getRequiredGroupIds(user); // Return a map of persona vs Set of Group IDs outside for loop
            //System.debug('requiredGroupIds --> '+requiredGroupIds);
            Set<Id> currentUserGroups = currentGroups.get(user.Id) != null ? currentGroups.get(user.Id) : new Set<Id>();
            //System.debug('currentUserGroups --> '+currentUserGroups);
            if(requiredGroupIds != null){
                for (Id groupId : requiredGroupIds) {
                    if (!currentUserGroups.contains(groupId)) {
                        groupsToAdd.add(new GroupMember(UserOrGroupId = user.Id, GroupId = groupId));
                    }
                }
            }
            Set<Id> groupsIdsToRemove = new Set<Id>();
            List<GroupMember> groupMemberList = currentUserGroupMap.get(user.Id);
            //System.debug('groupMemberList --> '+groupMemberList);
            if (groupMemberList != null) {
                for (GroupMember gm : groupMemberList) {
                    if (gm.UserOrGroupId == user.Id && (requiredGroupIds == null || !requiredGroupIds.contains(gm.GroupId))) {
                        groupsToRemove.add(gm);
                    }
                }
            }

        }
        
        try {
            if (!permissionsToAdd.isEmpty()) {
                System.debug('permissionsToAdd --> '+ permissionsToAdd);
                Database.insert(permissionsToAdd, false);  
            }
            
            if (!permissionsToRemove.isEmpty()) {
                Database.delete(permissionsToRemove, false); 
            }
            
            if (!groupsToAdd.isEmpty()) {
                System.debug('groupsToAdd --> '+ groupsToAdd);
                Database.insert(groupsToAdd, false);
            }
            
            if (!groupsToRemove.isEmpty()) {
                Database.delete(groupsToRemove, false);
            }
        } catch (DmlException ex) {
            System.debug('DML operation failed: ' + ex.getMessage());
            ErrorLogger.createLog('UserTriggerHandler', 'assignPermissionsAndGroups', ex, '', 'Apex Class');
            throw ex;
        }
        
        Integer usedQueries = Limits.getQueries();
        Integer maxQueries = Limits.getLimitQueries();
        System.debug('SOQL Queries used: ' + usedQueries + '/' + maxQueries);
    }
    
    private static Set<Id> getRequiredGroupIds(User user) {
        Set<Id> groupIds = new Set<Id>();
        Set<String> personaSet = new Set<String>();
        Boolean hasNSWLicense = false;
        Boolean hasQldLicense = false;
        if(user.Personas__c != null){
            personaSet.addAll(user.Personas__c.split(';'));
        }
        
        // Query custom metadata for the group based on Primary Persona
        List<String> groupNames = new List<String>();        
        Map<String, Persona_Permission_Mapping__mdt> getAllMetadataRecords = Persona_Permission_Mapping__mdt.getAll();
        List<String> pubgroupNames = new List<String>();
        
		//Added as part of https://thestar.atlassian.net/browse/POP-481 --> Assinging Safer Gambling state based Public group, only if License Exists.
        Map<String, Boolean> licenseCheckMap = new Map<String, Boolean>{
            'exclusion safer gam line 1 qld users' => (user.QLD_License_Number__c != null),
                'exclusion safer gam line 1 nsw users' => (user.NSW_License_Number__c != null)
                };

                    
        for (String key: getAllMetadataRecords.keySet()){
            Persona_Permission_Mapping__mdt metaRecord = getAllMetadataRecords.get(key);
            if(personaSet.contains(metaRecord.Persona__c)){
                pubgroupNames = metaRecord.Public_Group__c.split(',');
                for (String name : pubgroupNames) {
                    name = name.trim();
					String normalizedName = name.toLowerCase();
					// Check if name exists in map and license is missing
                    if (licenseCheckMap.containsKey(normalizedName) && !licenseCheckMap.get(normalizedName)) {
                        continue;
                    }
					groupNames.add(name);
                }
            }
        }
        // Query group records to get their IDs
        if (!groupNames.isEmpty()) {
            for(String key : groupNames){
                if(orgPublicGroupMap.containsKey(key)){
                    groupIds.add(orgPublicGroupMap.get(key));
                }
            }
        }
        return !groupIds.isEmpty() ? groupIds : null;        
    }
    
    private static Boolean hasPersonasChanged(User oldUser, User newUser) {
        String oldUserPrimaryPersona = getPrimaryPersona(oldUser.Personas__c);
        String newUserPrimaryPersona = getPrimaryPersona(newUser.Personas__c);
        Boolean secondaryPersonasChanged = false;
        List<String> oldUserPersonas = oldUser.Personas__c != null ? oldUser.Personas__c.split(';') : new List<String>();
        List<String> newUserPersonas = newUser.Personas__c != null ? newUser.Personas__c.split(';') : new List<String>();
        if (oldUserPersonas.size() > 1 && newUserPersonas.size() > 1) {
            // Remove the first element from each list to start comparison from the second position
            oldUserPersonas.remove(0);
            newUserPersonas.remove(0);
            
            // Convert the lists to sets to ignore the order of values
            Set<String> oldPersonaSet = new Set<String>(oldUserPersonas);
            Set<String> newPersonaSet = new Set<String>(newUserPersonas);
            // Compare the sets
            secondaryPersonasChanged = oldPersonaSet.equals(newPersonaSet);
            //System.debug('secondaryPersonasChanged --> '+secondaryPersonasChanged);
        }
        return oldUserPrimaryPersona != newUserPrimaryPersona || !secondaryPersonasChanged;
    }
    
    private static Set<String> getRequiredPermissionSets(String personas) {
        Set<String> personaSet = new Set<String>();
        if(personas != null){
            personaSet.addAll(personas.split(';'));
        }
        Map<String, Persona_Permission_Mapping__mdt> getAllMetadataRecords = Persona_Permission_Mapping__mdt.getAll();
        Set<String> permissionSets = new Set<String>();
        for (String key: getAllMetadataRecords.keySet()) {
            Persona_Permission_Mapping__mdt metaRecord = getAllMetadataRecords.get(key);
            if(personaSet.contains(metaRecord.Persona__c)){
                List<String> apiNames = metaRecord.Permission_Set_Api_Names__c.split(',');
                for (String apiName : apiNames) {
                    permissionSets.add(apiName.trim()); // Add trimmed name to the Set
                }
                permissionSets.add(System.label.CMTD_ERL_Permission_Set);
            }            
        }
        return !permissionSets.isEmpty() ? permissionSets : null;
    }
    private static String getRoleNameByPersona(String persona) {
        Map<String, Persona_Permission_Mapping__mdt> getAllMetadataRecords = Persona_Permission_Mapping__mdt.getAll();
        for (String key: getAllMetadataRecords.keySet()) {
            Persona_Permission_Mapping__mdt metaRecord = getAllMetadataRecords.get(key);
            if(metaRecord.Persona__c == persona){
                return metaRecord.Role__c;
            }
        }
        return null;
    }        
    private static Id getBaseProfileId(){
        String baseProfileName = System.label.TSEG_Base_Profile;
        List<Profile> baseProfile = [Select id, Name from Profile where name =: baseProfileName];
        return !baseProfile.isEmpty() ? baseProfile[0].Id : null;
    }
    private static String getPrimaryPersona(String personas){
        if(personas!=null && personas.contains(';')){
            return  personas.substringBefore(';');
        }else{
            return personas;
        }
    }    
    private static Map<String, Id> getAllPermissionSetsMap(){
        Set<String> uniquePermissionSetApiNames = new Set<String>();        
        Map<String, Id> orgPermissionSetMap = new Map<String, Id>();
        System.debug('getAllPermissionSetsMap -->');
        // Loop through each metadata record
        Map<String, Persona_Permission_Mapping__mdt> getAllMetadataRecords = Persona_Permission_Mapping__mdt.getAll();
        for (String key: getAllMetadataRecords.keySet()) {
            Persona_Permission_Mapping__mdt metaRecord = getAllMetadataRecords.get(key);
            if (metaRecord.Permission_Set_Api_Names__c != null) {
                // Split the Permission_Set_Api_Names__c by colon and trim each value
                List<String> apiNames = metaRecord.Permission_Set_Api_Names__c.split(',');
                for (String apiName : apiNames) {
                    uniquePermissionSetApiNames.add(apiName.trim()); // Add trimmed name to the Set
                }
                uniquePermissionSetApiNames.add(System.label.CMTD_ERL_Permission_Set);
            }
        }
        for (PermissionSet ps : [ SELECT Id, Name, Label FROM PermissionSet WHERE Name IN :uniquePermissionSetApiNames]) {
            orgPermissionSetMap.put(ps.Name, ps.Id);
        }
        return !orgPermissionSetMap.isEmpty() ? orgPermissionSetMap : null;
    }
    
    private static Map<String, Id> getAllPublicGroupMap(){
        Set<String> uniqueGroup = new Set<String>();        
        Map<String, Id> orgPublicGroupMap = new Map<String, Id>();
        Map<String, Persona_Permission_Mapping__mdt> getAllMetadataRecords = Persona_Permission_Mapping__mdt.getAll();
        List<String> pubgroupNames = new List<String>();
        for(String key: getAllMetadataRecords.keySet()){
            Persona_Permission_Mapping__mdt metaRecord = getAllMetadataRecords.get(key);
            pubgroupNames = metaRecord.Public_Group__c.split(',');
            for (String name : pubgroupNames) {
                uniqueGroup.add(name.trim());
            }
        }
        for(Group grp: [Select Id, Name from Group where Name IN:uniqueGroup]){
            orgPublicGroupMap.put(grp.Name, grp.Id);
        }
        System.debug('orgPublicGroupMap --> '+orgPublicGroupMap);
        return !orgPublicGroupMap.isEmpty() ? orgPublicGroupMap : null;
    }
    private static Map<String, ID> getAllRolesMap(){
        System.debug('getAllRolesMap -->');
        Map<String, ID> allRolesMap = new Map<String, ID>();
        for(UserRole userRole: [Select Id, Name from UserRole]){
            allRolesMap.put(userRole.Name, userRole.Id);
        }
        return !allRolesMap.isEmpty() ? allRolesMap : null;
    }

    private static Map<String, String> getRolePersonaMap() {
        System.debug('getRolePersonaMap -->');
        Map<String, String> rolesPersonaMap = new Map<String, String>();
        Map<String, Persona_Permission_Mapping__mdt> getAllMetadataRecords = Persona_Permission_Mapping__mdt.getAll();
        for(String key: getAllMetadataRecords.keySet()){
			Persona_Permission_Mapping__mdt metaRecord = getAllMetadataRecords.get(key);           
            rolesPersonaMap.put(metaRecord.Persona__c, metaRecord.Role__c);
        }
        return !rolesPersonaMap.isEmpty() ? rolesPersonaMap : null;
    }        
}