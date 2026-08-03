/**
 * @description       : Class for setting up the query for the external object (called by VIPBookingController.apxc)
 * @author            : rhysjohn.delacruz@simplus.com
 * @group             : 
 * @last modified on  : 02-03-2022
 * @last modified by  : rhysjohn.delacruz@simplus.com
 * Modifications Log 
 * Ver   Date         Author                          Modification
 * 1.0   02-03-2022   rhysjohn.delacruz@simplus.com   Initial Version
**/
public class VIPBookingDataProvider {
    
    public static List<VIPBookingDataProvider.VIPBookingWrapper> getIDDetailsByContactId(String recordId){
        
        List<VIPBookingWrapper> vipDetailsObjWrapList = new List<VIPBookingWrapper>();
        try{
            //List<vipbooking__x > vipData = getIdDetailsByContactQueryByContactId(recordId);

            //List<VIPBookingWrapper> ids = new List<VIPBookingWrapper>();
            vipDetailsObjWrapList.add(new VIPBookingWrapper((String)recordId,'000001','300.50','$1000','00835','5','a015O000000ygo0QAA','Bronze',System.today()+10,300.5,200,
                                                            500,1000,2000,'2',5));
  
            // if(idData.size() > 0){

            //     for(vipbooking__x  vipObj : vipData){
            //         vipDetailsObjWrapList.add(
            //             new VIPBookingWrapper(idObj.SalesforceContactId__c,idObj.IdType__c,idObj.IdNumber__c,idObj.IdExpiryDate__c,idObj.State__c,idObj.Country__c)
            //         ); 

            //     }
            
            // }            
            
        }
        catch(Exception e){
            system.debug('Exception happenned '+ e.getMessage() );
            ErrorLogger.createLog('VIPBookingDataProvider','getIDDetailsByContactId',e,recordId,'Apex Class'); 
            return null;
        }
        
        updateLoyaltyFields(recordId, vipDetailsObjWrapList);
        return vipDetailsObjWrapList;
    }
    
    //---------------------------------------------------------------------------------------//
    //---------------------------------------------------------------------------------------//
    //---------------------------------------------------------------------------------------//    //
 
    public static void updateLoyaltyFields(String recordId, List<VIPBookingWrapper> vipDetailsObjWrapList){
        Loyalty__c loyaltyRecUpdate = new Loyalty__c();
        Contact contactRecUpdate = new Contact();
        
        loyaltyRecUpdate.Id = 'a005O000002TUBaQAO';
        loyaltyRecUpdate.Loyalty_Program__c = vipDetailsObjWrapList[0].loyaltyProgram;
        loyaltyRecUpdate.Tier__c = vipDetailsObjWrapList[0].loyaltyTier;
        loyaltyRecUpdate.Tier_Review_Date__c = vipDetailsObjWrapList[0].tierReviewDate;
        loyaltyRecUpdate.Tier_Balance__c = vipDetailsObjWrapList[0].tierPointsBalance;
        loyaltyRecUpdate.Points_to_Retain_Current_Tier__c = vipDetailsObjWrapList[0].pointsToCurrentTier;
        loyaltyRecUpdate.Points_To_Next_Tier__c = vipDetailsObjWrapList[0].pointsToNextTier;
        loyaltyRecUpdate.CasinoBalance__c = vipDetailsObjWrapList[0].casinoBalance;
        loyaltyRecUpdate.CompBalance__c = vipDetailsObjWrapList[0].compBalance;
        loyaltyRecUpdate.Rank__c = vipDetailsObjWrapList[0].rankRec;
        loyaltyRecUpdate.Comp_Room_Night_Remaining__c = vipDetailsObjWrapList[0].compRoomNightRemaining;
        
        update loyaltyRecUpdate;
        
        contactRecUpdate.Id = recordId;
        contactRecUpdate.Loyalty_Program__c = 'Absolute Rewards';
        contactRecUpdate.Tier__c = vipDetailsObjWrapList[0].loyaltyTier;
        
        update contactRecUpdate;
        
    }

    // public static List<identification__x> getIdDetailsByContactQueryByContactId(Id contactId){
    //     IdentificationUIDataSelector selector = new IdentificationUIDataSelector();
    //     String externalFields = String.valueOf(selector.getExternalObjectFieldsList()).remove(')').remove('(');
    //     Schema.SObjectType externalObj = selector.getExternalObjectType();
    //     if(Test.isRunningTest()){
    //         if(IdentificationUIControllerTest.testException == true){
    //             throw new IdentificationDataProviderException();
    //         }
    //         List<identification__x> ids = new List<identification__x>();
    //         ids.add(new identification__x(SalesforceContactId__c=IdentificationUIControllerTest.ct.Id,IdType__c='Driving License',IdNumber__c='2323224',IdExpiryDate__c='2021-03-04',State__c='CA',Country__c='PH'));
    //         return ids;
    //     } else {
    //         String query = 'SELECT ' + externalFields + ' FROM ' + externalObj + ' WHERE SalesforceContactId__c = \'' + contactId + '\' LIMIT 50';
    //         system.debug('-----'+query);
    //         return Database.query(query);
    //     }
    // }
    
    
    public class VIPBookingWrapper{
        @AuraEnabled public String contactId {get;set;}
        @AuraEnabled public String idType {get;set;}
        @AuraEnabled public String idNumber {get;set;}
        @AuraEnabled public String idExpiryDate {get;set;}
        @AuraEnabled public String idState {get;set;}
        @AuraEnabled public String idCountry {get;set;}
        
        @AuraEnabled public Id loyaltyProgram {get;set;}
        @AuraEnabled public String loyaltyTier {get;set;}
        @AuraEnabled public Date tierReviewDate {get;set;}
        @AuraEnabled public Decimal tierPointsBalance {get;set;}
        @AuraEnabled public Decimal pointsToCurrentTier {get;set;}
        @AuraEnabled public Decimal pointsToNextTier {get;set;}
        @AuraEnabled public Decimal casinoBalance {get;set;}
        @AuraEnabled public Decimal compBalance {get;set;}
        @AuraEnabled public String rankRec {get;set;}
        @AuraEnabled public Decimal compRoomNightRemaining {get;set;}
        

        public VIPBookingWrapper(String contactId,String idType,String idNumber,String expiryDate, String idState, String idCountry,
                                Id loyaltyProgram, String loyaltyTier, Date tierReviewDate, Decimal tierPointsBalance, Decimal pointsToCurrentTier, 
                                 Decimal pointsToNextTier, Decimal casinoBalance, Decimal compBalance, String rankRec, Decimal compRoomNightRemaining){
                                     
            this.contactId = contactId;
            this.idType = idType;
            this.idNumber = idNumber;
            this.idExpiryDate = expiryDate;
            this.idState = idState;
            this.idCountry = idCountry;
                                       
            this.loyaltyProgram = loyaltyProgram;
            this.loyaltyTier = loyaltyTier;
            this.tierReviewDate = tierReviewDate;
            this.tierPointsBalance = tierPointsBalance;
            this.pointsToCurrentTier = pointsToCurrentTier;
            this.pointsToNextTier = pointsToNextTier;
            this.casinoBalance = casinoBalance;
            this.compBalance = compBalance;
            this.rankRec = rankRec;
            this.compRoomNightRemaining = compRoomNightRemaining;
        }
    }
    
    public class VIPBookingDataProviderProviderException extends Exception{}
}