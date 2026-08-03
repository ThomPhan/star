/**
* @File Name          : SOWBatchJob.apxc
* @Description        : Batch Job that runs everyday to update 'Bulk_Update_for_Data_Fix__c' field of up to 50 Contact records
* @Author             : Gil Panican
* @Group              : Simplus
* @Last Modified By   : Gil Panican
* @Last Modified On   : 03/08/22
**/
global class SOWBatchJob implements Database.Batchable<sObject>,Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,Source_of_Wealth__c,Who_do_they_work_for_employer_details__c,Their_role_in_that_business__c,Are_they_full_time_part_time_or_casual__c,'+
            'How_long_have_they_worked__c,Student_Present_means_of_support__c,Retired_Pre_retirement_employment__c,Other_employment_roles__c,Professional_qualifications__c,'+
            'If_Gov_Law_Enforcement_Dept_Location__c,Name_of_business_or_company__c,Their_role_Job_title_within_the_business__c,What_does_the_business_do__c,'+
            'Australian_Business_Number_ABN__c,Documents_that_prove_their_business__c,Business_card__c '+
            'FROM Contact WHERE (Source_of_Wealth__c <> NULL or Who_do_they_work_for_employer_details__c <> NULL or Their_role_in_that_business__c <> NULL '+ 
            'or Are_they_full_time_part_time_or_casual__c <> NULL or How_long_have_they_worked__c <> NULL or Student_Present_means_of_support__c <> NULL '+
            'or Retired_Pre_retirement_employment__c <> NULL or Other_employment_roles__c <> NULL or Professional_qualifications__c <> NULL '+
            'or If_Gov_Law_Enforcement_Dept_Location__c <> NULL or Name_of_business_or_company__c <> NULL or Their_role_Job_title_within_the_business__c <> NULL '+
            'or What_does_the_business_do__c <> NULL or Australian_Business_Number_ABN__c <> NULL or Documents_that_prove_their_business__c <> NULL or Business_card__c <> NULL) '+
            'AND (Refused_to_provide_SOW__c = false) AND (Bulk_Update_for_Data_Fix__c = false) limit 50';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> contList){
        System.debug('***Batch Started***');
        System.debug('Number of Records included: ' + contList.size());
        for (Contact contRec : contList){
            contRec.Bulk_Update_for_Data_Fix__c = true;
        }
        Database.update(contList, false);
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('***Batch Finished***');
    }
    
    global void execute(SchedulableContext sc) {
        SOWBatchJob b = new SOWBatchJob();
        Database.executebatch(b);
    }
}