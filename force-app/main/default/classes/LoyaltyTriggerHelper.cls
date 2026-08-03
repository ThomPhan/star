/**
* Class Name  : LoyaltyTriggerHelper
* @author     : Capgemini
* @Description: Utility class to contain the business logic for the Loyalty object trigger
* @version    : Version 1 : 28/10/2025
**/

public class LoyaltyTriggerHelper {

    public static void reconcileRestrictionRecords(List<Loyalty__c> newLoyaltyList, Map<Id, Loyalty__c> oldLoyaltyMap){
        List<Exl_Restriction__c> restrictionUpdateList = new List<Exl_Restriction__c>();
        List<Id> loyaltyPointsList = new List<Id>();
        List<Id> loyaltyDiscountsList = new List<Id>();
        List<Id> loyaltyHotelList = new List<Id>();
        List<Id> loyaltyParkingList = new List<Id>();
        List<Id> loyaltyTierList = new List<Id>();
        List<Id> loyaltyPointsRevList = new List<Id>();
        List<Id> loyaltyDiscountsRevList = new List<Id>();
        List<Id> loyaltyHotelRevList = new List<Id>();
        List<Id> loyaltyParkingRevList = new List<Id>();
        List<Id> loyaltyTierRevList = new List<Id>();        
        
        for(Loyalty__c c : newLoyaltyList){
            
                       
            //Activate path - check if Loyalty CasinoBalance__c / Casino__c field is Less than 1	
            if((c.CasinoBalance__c < 1 && oldLoyaltyMap.get(c.Id).CasinoBalance__c != c.CasinoBalance__c) || (c.Casino__c < 1 &&  oldLoyaltyMap.get(c.Id).Casino__c != c.Casino__c)){
                loyaltyPointsList.add(c.Patron__c);
            }                
            //revoke path - check if Loyalty CasinoBalance__c / Casino__c field is greater than 1	
            else if ((c.CasinoBalance__c >= 1 && oldLoyaltyMap.get(c.Id).CasinoBalance__c != c.CasinoBalance__c) || (c.Casino__c >= 1 && oldLoyaltyMap.get(c.Id).Casino__c != c.Casino__c)) {
                loyaltyPointsRevList.add(c.Patron__c);
            }
            
            //disabling as part of POP-1436, POP-448
            /*
            //Activate path - check if Loyalty F_B_Discount_Entitlement__c or Hotel_Discount_Entitlement__c field is Less than 1
            if(c.F_B_Discount_Entitlement__c < 1 && c.Hotel_Discount_Entitlement__c < 1) {
                loyaltyDiscountsList.add(c.Patron__c);
            }
            //revoke path - check if Loyalty F_B_Discount_Entitlement__c or Hotel_Discount_Entitlement__c field is greater than 1
            else if(c.F_B_Discount_Entitlement__c >= 1 && c.Hotel_Discount_Entitlement__c >= 1){
                loyaltyDiscountsRevList.add(c.Patron__c);
            }
            //Activate path - check if Loyalty Hotel_Discount_Entitlement__c field is Less than 1
            if(c.Hotel_Discount_Entitlement__c < 1){
                loyaltyHotelList.add(c.Patron__c);
            }                 
            //revoke path - check if Loyalty Hotel_Discount_Entitlement__c field is greater than 1
            else if (c.Hotel_Discount_Entitlement__c >= 1){
                loyaltyHotelRevList.add(c.Patron__c);
            }
                
            //Activate path - check if Loyalty Comp_Parking_Entitlement__c field is changed and value is NULL
            if(c.Comp_Parking_Entitlement__c == null){
                loyaltyParkingList.add(c.Patron__c);
            }                
            //revoke path - check if Loyalty Comp_Parking_Entitlement__c field is changed and value is not NULL
            else if(c.Comp_Parking_Entitlement__c != null){
                loyaltyParkingRevList.add(c.Patron__c);
            }
            
            system.debug('%c.Tier__cc.Tier__cc.Tier__cc.Tier__c% '+c.Tier__c);
            system.debug('%c.Name.Name.Name.Name% '+c.Name);
			
			//Removing it based on the confirmation by business that "Tier" information need to be collected from Patron record, rather than Loyalty table
            //Activate path - check if Loyalty Tier__c field is changed and value is Bronze
            if(c.Name == 'Bronze'){
                loyaltyTierList.add(c.Patron__c);
            }
            //revoke path - check if Loyalty Tier__c field is changed and value is not Bronze
            else if(c.Name != 'Bronze' && c.Tier__c != null) {
                loyaltyTierRevList.add(c.Patron__c);
            }*/
        }
        
        if( !loyaltyPointsList.isEmpty() || !loyaltyDiscountsList.isEmpty() || !loyaltyHotelList.isEmpty() 
                 || !loyaltyParkingList.isEmpty() || !loyaltyTierList.isEmpty() ){
                    
            for(Exl_Restriction__c res : [SELECT Id, Restriction_Type__c, Enforcement_Status__c FROM Exl_Restriction__c 
                                          WHERE (
                                            //Restriction records that are for activation 
                                              Enforcement_Status__c != :ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE AND 
                                              ((Patron__c IN :loyaltyPointsList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_CASINO_POINTS ) 
                                            OR (Patron__c IN :loyaltyDiscountsList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_DISCOUNTS) 
                                            OR (Patron__c IN :loyaltyHotelList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_HOTEL) 
                                            OR (Patron__c IN :loyaltyParkingList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_PARKING)
                                            OR (Patron__c IN :loyaltyTierList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_TIER_LEVEL_LOST) ) ) ] ){
                //Update status to Active
                //Check Overridden scenario, if the loyalty values are changed to Active and our Restriction is Revoked, then mark it overridden
                if(res.Enforcement_Status__c == ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED){
                    res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_OVERRIDDEN;
                } else {
                    res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE;
                }
                restrictionUpdateList.add(res); 
        	}
        }
        
        if(!loyaltyPointsRevList.isEmpty() || !loyaltyDiscountsRevList.isEmpty() || !loyaltyHotelRevList.isEmpty() 
                 || !loyaltyParkingRevList.isEmpty() || !loyaltyTierRevList.isEmpty() ){
            for(Exl_Restriction__c res : [SELECT Id, Restriction_Type__c, Enforcement_Status__c FROM Exl_Restriction__c 
                                          WHERE (Enforcement_Status__c != :ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED AND 
                                              ((Patron__c IN :loyaltyPointsRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_CASINO_POINTS ) 
                                            OR (Patron__c IN :loyaltyDiscountsRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_DISCOUNTS) 
                                            OR (Patron__c IN :loyaltyHotelRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_HOTEL) 
                                            OR (Patron__c IN :loyaltyParkingRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_PARKING)
                                            OR (Patron__c IN :loyaltyTierRevList AND Restriction_Type__c =: ConstantHelper.STRING_RESTRICTION_TYPE_TIER_LEVEL_LOST) ) ) ] ){
                //Update status to Revoked
                //Check Overridden scenario, if the loyalty values are changed to revoked and our Restriction is Active, then mark it overridden
                if(res.Enforcement_Status__c == ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE){
                    res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_OVERRIDDEN;
                } else {
                    res.Enforcement_Status__c = ConstantHelper.STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED;
                }
                restrictionUpdateList.add(res);                                            
            }
        }

        //Update Restriction record 
        if(!restrictionUpdateList.isEmpty()){
            update restrictionUpdateList;
        }
        
    }
    
}