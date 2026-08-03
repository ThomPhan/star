public class CustomPermissionUtils {
    public class Output {
        @InvocableVariable public List<String> customPermissions = new List<String>();
    }
    public class Input {
        @InvocableVariable public String userId;
    }
    
    @InvocableMethod(
        label='Get Custom Permissions'
        description='Returns list of custom permission names.'
    )
    
    public static List<Output> getChoices(List<Input> inputs) {
        List<Output> results = new List<Output>();
        
        for (Input i : inputs) {
            Output out = new Output();
            List<String> perms = getCustomPermissionsForUser(i.userId);
            
            for (String rec : perms) {
                out.customPermissions.add(rec);
            }
            results.add(out);
        }
        return results;
    }
    
    public static List<String> getCustomPermissionsForUser(Id userId) {
        Set<Id> permissionSetIds = new Set<Id>();

        // Step 1: Get Permission Sets assigned to the user
        for (PermissionSetAssignment psa : [
            SELECT PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId ]) {
            permissionSetIds.add(psa.PermissionSetId);
        }

        // Step 2: Get Custom Permissions linked to those Permission Sets
        Set<Id> customPermissionIds = new Set<Id>();
        for (SetupEntityAccess sea : [
            SELECT SetupEntityId 
            FROM SetupEntityAccess 
            WHERE SetupEntityType = 'CustomPermission' 
            AND ParentId IN :permissionSetIds ]) {
            customPermissionIds.add(sea.SetupEntityId);
        }

        // Step 3: Get DeveloperNames of Custom Permissions
        List<String> customPermissionNames = new List<String>();
        for (CustomPermission cp : [
            SELECT DeveloperName 
            FROM CustomPermission 
            WHERE Id IN :customPermissionIds]) {
            customPermissionNames.add(cp.DeveloperName);
        }

        return customPermissionNames;
    }
}