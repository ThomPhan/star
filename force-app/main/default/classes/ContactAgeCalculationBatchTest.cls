/**
* @File Name          : ContactAgeCalculationBatchTest.apxc
* @Description        : Test Class for ContactAgeCalculationBatch
* @Author             : Rhys Dela Cruz
* @Group              : Simplus
* @Last Modified By   : Rhys Dela Cruz
* @Last Modified On   : 15/03/21
**/
@isTest public class ContactAgeCalculationBatchTest {

    @isTest static void ageCalcTestMethod1(){

        Contact cont = new Contact();
        cont.FirstName = 'First Name Test';
        cont.LastName = 'Last Name Test';
        cont.Date_of_Birth__c = Date.valueOf('1950-'+System.today().month() + '-' + System.today().day());

        insert cont;

        Test.startTest();
        Database.executeBatch(new ContactAgeCalculationBatch());
        Test.stopTest();
    }

    @isTest static void ageCalcTestMethod2(){

        Contact cont = new Contact();
        cont.FirstName = 'First Name Test';
        cont.LastName = 'Last Name Test';
        cont.Date_of_Birth__c = Date.valueOf('1950-'+System.today().month() + '-' + System.today().day());

        insert cont;

        Test.startTest();
        String sch = '0 48 * * * ?'; 
        System.schedule('Test Age Calc Batch', sch, new ContactAgeCalculationBatch());
        Test.stopTest();
    }

    @isTest static void ageCalcTestMethod3(){

        Contact cont = new Contact();
        cont.FirstName = 'First Name Test';
        cont.LastName = 'Last Name Test';
        cont.Date_of_Birth__c = Date.valueOf('1950-'+System.today().month() + '-' + System.today().day());

        insert cont;

        Test.startTest();
        String sch = '0 48 * * * ?'; 
        Database.executeBatch(new ContactAgeCalculationBatch(new Set<String>{cont.Id}));
        Test.stopTest();
    }

    @isTest static void ageCalcTestMethod4(){

        Contact cont = new Contact();
        cont.FirstName = 'First Name Test';
        cont.LastName = 'Last Name Test';
        cont.Date_of_Birth__c = Date.valueOf('1950-'+System.today().month() + '-' + System.today().day());

        insert cont;

        AgeCalculationSetting__c calcSetting = AgeCalculationSetting__c.getOrgDefaults();
        calcSetting.Disable_Date_Filter__c = true;
        calcSetting.Month_to_Process__c = 3;
        upsert calcSetting;

        Test.startTest();
        Database.executeBatch(new ContactAgeCalculationBatch(new Set<String>{cont.Id}));
        Test.stopTest();
    }

    @isTest static void ageCalcTestMethod5(){

        Contact cont = new Contact();
        cont.FirstName = 'First Name Test';
        cont.LastName = 'Last Name Test';
        cont.Date_of_Birth__c = Date.valueOf('1950-'+System.today().month() + '-' + System.today().day()).addDays(1);

        insert cont;

        AgeCalculationSetting__c calcSetting = AgeCalculationSetting__c.getOrgDefaults();
        calcSetting.Disable_Date_Filter__c = true;
        calcSetting.Month_to_Process__c = 3;
        upsert calcSetting;

        Test.startTest();
        Database.executeBatch(new ContactAgeCalculationBatch(new Set<String>{cont.Id}));
        Test.stopTest();
    }
}