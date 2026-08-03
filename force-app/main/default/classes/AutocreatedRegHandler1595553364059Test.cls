/**
 * @description       : 
 * @author            : sakshi.chauhan@simplus.com
 * @group             : 
 * @last modified on  : 09-03-2020
 * @last modified by  : sakshi.chauhan@simplus.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-03-2020   sakshi.chauhan@simplus.com   Initial Version
**/
@isTest
public class AutocreatedRegHandler1595553364059Test {
    
    @isTest
    public static void canCreateUserTestTrue(){

        Auth.UserData data = new Auth.UserData('ODATA','star1','loginLastName','star1 loginLastName','login@startest.com','','usernamea',null,null,null,null);
        Test.startTest();
            AutocreatedRegHandler1595553364059 registerHandler = new AutocreatedRegHandler1595553364059();
            Boolean createUser = registerHandler.canCreateUser(data);
        Test.stopTest();
        system.assert(createUser);
    }

    @isTest
    public static void canCreateUserTestFalse(){

        Auth.UserData data = new Auth.UserData('ODATA','star1','loginLastName','star1 loginLastName','login@startest.com','','usernamea2342',null,null,null,null);
        Test.startTest();
            AutocreatedRegHandler1595553364059 registerHandler = new AutocreatedRegHandler1595553364059();
            Boolean createUser = registerHandler.canCreateUser(data);
        Test.stopTest();
        system.assert(createUser == false);
    }

    @isTest
    public static void createUserTest(){

        Auth.UserData data = new Auth.UserData('ODATA','star1','loginLastName','star1 loginLastName','login@startest.com','','usernamea',null,null,null,null);
        Test.startTest();
            AutocreatedRegHandler1595553364059 registerHandler = new AutocreatedRegHandler1595553364059();
            User userDetails = registerHandler.createUser(null,data);
        Test.stopTest();
        system.debug('userDetails '+ userDetails);
        system.assert(userDetails != null);
        system.assert(userDetails.username == 'usernamea@myorg.com');
    }

    @isTest
    public static void createUserFalseTest(){

        Auth.UserData data = new Auth.UserData('ODATA','star1','loginLastName','star1 loginLastName','login@startest.com','','usernamea2121',null,null,null,null);
        Test.startTest();
            AutocreatedRegHandler1595553364059 registerHandler = new AutocreatedRegHandler1595553364059();
            User userDetails = registerHandler.createUser(null,data);
        Test.stopTest();
        system.debug('userDetails '+ userDetails);
        system.assert(userDetails == null);
    }

    @isTest
    public static void updateUserTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User userObj = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='StandardUserStar@startest.com');
        insert userObj;
        Auth.UserData data = new Auth.UserData('ODATA','star1','loginLastName','star1 loginLastName','login@startest.com','','usernamea',null,null,null,null);
        Test.startTest();
            AutocreatedRegHandler1595553364059 registerHandler = new AutocreatedRegHandler1595553364059();
            registerHandler.updateUser(userObj.Id,null,data);
        Test.stopTest();
        userObj = [ SELECT Email FROM User WHERE Id =: userObj.Id];
        system.assertEquals(userObj.Email,'login@startest.com');
    }
}