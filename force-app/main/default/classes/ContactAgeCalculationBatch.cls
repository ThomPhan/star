/**
* @File Name          : ContactAgeCalculationBatch.apxc
* @Description        : Contact Age Calculation Batch that runs everyday, and computes Age of Contact on the Age Field based on the DOB Field
* @Author             : Rhys Dela Cruz
* @Group              : Simplus
* @Last Modified By   : Rhys Dela Cruz
* @Last Modified On   : 11/03/21
**/
global class ContactAgeCalculationBatch implements Database.Batchable<sObject>, Schedulable {
    
    Set<String> adHocId = new Set<String>();

    global ContactAgeCalculationBatch(){

    }

    global ContactAgeCalculationBatch(Set<String> adHocId){

        this.adHocId = adHocId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        String query = 'SELECT Id, Date_of_Birth__c FROM Contact ';
        
        if(!adHocId.isEmpty()){

            query += ' WHERE Id IN: adHocId ';
        }

        //Check if it is leap year and 1st of March to include leap year birthdays
        // if(Date.isLeapYear(System.today.year()) && System.today().day() == 1 && System.today().month() == 3){

        //     query += ' AND Date_of_Birth__c = ';
        // }
        
        System.debug('query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(SchedulableContext SC){
        
        Database.executeBatch(new ContactAgeCalculationBatch());
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> contList){
        
        List<Contact> contListForUpdate = new List<Contact>();
        AgeCalculationSetting__c calcSetting = AgeCalculationSetting__c.getOrgDefaults();

        Integer systemDay = System.Today().Day();
        Integer systemMonth = System.Today().Month();
        Integer systemYear = System.Today().Year();
        
        for(Contact cont : contList){

            if(cont.Date_of_Birth__c != null){

                if((cont.Date_of_Birth__c.day() == systemDay && cont.Date_of_Birth__c.month() == systemMonth) || (Date.isLeapYear(systemYear) && systemDay == 1 && systemMonth == 3 && cont.Date_of_Birth__c.day() == 29 && cont.Date_of_Birth__c.month() == 2) || calcSetting.Disable_Date_Filter__c){ 
                    
                    //Added Custom Setting Month values so that it can be checked if the month is for this one
                    if(calcSetting.Month_to_Process__c != null && calcSetting.Disable_Date_Filter__c){

                        if(calcSetting.Month_to_Process__c == cont.Date_of_Birth__c.month()){

                            Contact contRec = new Contact();
                            contRec.Id = cont.Id;

                            Date tempBdate = Date.valueOf(System.today().year() + '-' + cont.Date_of_Birth__c.month() + '-' + cont.Date_of_Birth__c.day());
                            
                            //Added condition to check date if greater than today to have correct age
                            if(tempBdate > System.today()){
                                //contRec.Age__c = String.valueOf((System.today().year()-1) - cont.Date_of_Birth__c.year());
                            }
                            else{
                                //contRec.Age__c = String.valueOf(System.today().year() - cont.Date_of_Birth__c.year());
                            }

                            contListForUpdate.add(contRec);
                        }
                    }
                    else{

                        Contact contRec = new Contact();
                        contRec.Id = cont.Id;
                        Date tempBdate = Date.valueOf(System.today().year() + '-' + cont.Date_of_Birth__c.month() + '-' + cont.Date_of_Birth__c.day());
                            
                        //Added condition to check date if greater than today to have correct age
                        if(tempBdate > System.today()){
                            //contRec.Age__c = String.valueOf((System.today().year()-1) - cont.Date_of_Birth__c.year());
                        }
                        else{
                            //contRec.Age__c = String.valueOf(System.today().year() - cont.Date_of_Birth__c.year());
                        }
                        contListForUpdate.add(contRec);
                    }
                }
            }
        }
        
        if(!contListForUpdate.isEmpty()){

            Database.saveResult[] saveResults = Database.update(contListForUpdate, false);

            for (Integer i = 0; i < contListForUpdate.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                Contact origRecord = contListForUpdate[i];
                if (!sr.isSuccess()) {
                    
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred: Id: ' + origRecord.Id + ' ' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                } 
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}