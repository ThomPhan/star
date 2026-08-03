/* Description: Helper class that returns the Loyalty record for the component
 * Author: Simplus
 * Date Created: 12/5/2022
 * History:
 * 12/5				JPalmero			Created
 */
public class LoyaltyHelper {
    @AuraEnabled(cacheable=true)
    public static Loyalty__c getLoyaltyInfo(Id contactId){
        try{
            Loyalty__c childLoyalty = [SELECT Id, Name, Tier_Review_Date__c, Tier_Balance__c, Points_to_Retain_Current_Tier__c, Points_To_Next_Tier__c, Tier_Points_Earned_Today__c, 
                                       Tier_Points_Earned_This_Week__c, Tier_Points_Earned_This_Month__c, CasinoBalance__c, 
                                       CompBalance__c, Last_Successful_Update__c   
                                       FROM Loyalty__c WHERE Patron__c =: contactId LIMIT 1];
            return childLoyalty;
        }catch(QueryException qExcp){
            throw new AuraHandledException('No Loyalty record returned');
        }
    }
}