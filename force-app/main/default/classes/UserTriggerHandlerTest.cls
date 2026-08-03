/**
* Class Name  : UserTriggerHandler
* Summary     : Helper class for the 'User' trigger   
* @author     : Capgemini
* @Description: This class contains the logic for user provisioning in Salesforce
* @version    : Version 1 : 15/11/2024
**/
@isTest
public class UserTriggerHandlerTest {
    
    @testSetup
    static void setup() {        
        // Create the base profile
        Profile baseProfile = [SELECT Id FROM Profile WHERE Name = 'TSEG Base Profile' LIMIT 1];
        
        // Create test user
        User testUser = new User(
            Username = 'newtsegstaruser@tseg.com.au',
            Email = 'testuser@tseg.com.au',
            FirstName = 'Test',
            LastName = 'user',
            Alias = 'tuser',
            ProfileId = baseProfile.Id,
            Personas__c = 'Local Telesales;C-Level', // Multi-select personas
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }
    
    @isTest
    static void testUserCreate() {
        User testUser = new User(
            Username = 'newtseguser@tseg.com.au',
            FirstName = 'Steve',
            LastName = 'Smith',
            Email = 'newuser@example.com',
            Alias = 'nuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'TSEG Base Profile' LIMIT 1].Id,
            Personas__c = 'Premium Guest',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Validate that the user has the correct permission sets, public groups, and roles based on personas
        testUser = [SELECT Id, Name, Personas__c FROM User WHERE Username = 'newtseguser@tseg.com.au' LIMIT 1];
		
        // Check Permission Set Assignments
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id];
        Set<String> assignedPermissionSets = new Set<String>();
        for (PermissionSetAssignment psa : psaList) {
            assignedPermissionSets.add(psa.PermissionSet.Name);
        }
        
        // Assert that the correct permission sets are assigned
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Base_PS'), 'Permission set TSEG_Base_PS not assigned.');
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Premium_Guest_PS'), 'Permission set TSEG_Premium_Guest_PS not assigned.');
        
         // Check Public Group Memberships
        List<GroupMember> groupMembers = [SELECT Group.Name FROM GroupMember WHERE UserOrGroupId = :testUser.Id];
        Set<String> assignedPublicGroups = new Set<String>();
        for (GroupMember gm : groupMembers) {
            assignedPublicGroups.add(gm.Group.Name);
        }

        // Assert that the correct public groups are assigned
        Assert.isTrue(assignedPublicGroups.contains('TSEG Premium Guest'), 'Public Group TSEG_Premium_Guest_PS not assigned.');
    }
    
    @isTest
    static void testUserUpdate() {
        User testUser = [SELECT Id, Personas__c FROM User WHERE Username = 'newtsegstaruser@tseg.com.au' LIMIT 1];
        testUser.Personas__c = 'Interstate;Guest Feedback';  // Update personas
        update testUser;
        
        testUser = [SELECT Id, Personas__c FROM User WHERE Username = 'newtsegstaruser@tseg.com.au' LIMIT 1];
        
        // Check Permission Set Assignments
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id];
        Set<String> assignedPermissionSets = new Set<String>();
        for (PermissionSetAssignment psa : psaList) {
            assignedPermissionSets.add(psa.PermissionSet.Name);
        }
        
        // Assert that the correct permission sets are assigned
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Base_PS'), 'Permission set TSEG_Base_PS not assigned.');
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Premium_Guest_PS'), 'Permission set TSEG_Premium_Guest_PS not assigned.');
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Feedback_Ops_PS'), 'Permission set TSEG_Feedback_Ops_PS not assigned.');
        
         // Check Public Group Memberships
        List<GroupMember> groupMembers = [SELECT Group.Name FROM GroupMember WHERE UserOrGroupId = :testUser.Id];
        Set<String> assignedPublicGroups = new Set<String>();
        for (GroupMember gm : groupMembers) {
            assignedPublicGroups.add(gm.Group.Name);
        }

        // Assert that the correct public groups are assigned
        Assert.isTrue(assignedPublicGroups.contains('TSEG Interstate'), 'Public Group TSEG_Premium_Guest_PS not assigned.');
    }
    
    @isTest
    static void testUserRemovePersonaAndUpdate() {
        User testUser = [SELECT Id, Personas__c FROM User WHERE Username = 'newtsegstaruser@tseg.com.au' LIMIT 1];
        testUser.Personas__c = 'Fin Crime Operations';  // Remove one persona, change one
        update testUser;
        
        testUser = [SELECT Id, Personas__c FROM User WHERE Username = 'newtsegstaruser@tseg.com.au' LIMIT 1];
        
        // Check Permission Set Assignments
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id];
        Set<String> assignedPermissionSets = new Set<String>();
        for (PermissionSetAssignment psa : psaList) {
            assignedPermissionSets.add(psa.PermissionSet.Name);
        }
        
        // Assert that the correct permission sets are assigned
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Base_PS'), 'Permission set TSEG_Base_PS not assigned.');
        Assert.isTrue(assignedPermissionSets.contains('TSEG_Read_Only_PS'), 'Permission set TSEG_Read_Only_PS not assigned.');
        
         // Check Public Group Memberships
        List<GroupMember> groupMembers = [SELECT Group.Name FROM GroupMember WHERE UserOrGroupId = :testUser.Id];
        Set<String> assignedPublicGroups = new Set<String>();
        for (GroupMember gm : groupMembers) {
            assignedPublicGroups.add(gm.Group.Name);
        }

        // Assert that the correct public groups are assigned
        Assert.isTrue(assignedPublicGroups.contains('TSEG Fin Crime Operations'), 'Public Group TSEG Fin Crime Operations not assigned.');
    }
}