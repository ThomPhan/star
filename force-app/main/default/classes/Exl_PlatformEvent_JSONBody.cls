public class Exl_PlatformEvent_JSONBody {
    
    @AuraEnabled public Boolean isExcluded { get; set; }
    
    @AuraEnabled public String surname { get; set; }
    @AuraEnabled public String firstName { get; set; }
    @AuraEnabled public Date dob { get; set; }
    
    @AuraEnabled public String exclusionNumber { get; set; }
    @AuraEnabled public String exclusionReason { get; set; }
    
    @AuraEnabled public String poeTypeID { get; set; }
    @AuraEnabled public String poeType { get; set; }
    @AuraEnabled public String poeLength { get; set; }
    
    @AuraEnabled public String excBySourceName { get; set; }
    @AuraEnabled public String sourceName { get; set; }
    
    @AuraEnabled public Datetime issuedDate { get; set; }
    @AuraEnabled public Datetime revocationDate { get; set; }
	
    @AuraEnabled public Datetime accountIssuedDate { get; set; }
    @AuraEnabled public Datetime accountRevocationDate { get; set; }
}