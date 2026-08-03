public class ConstantHelper {
    public static final String APEXCLASSNAME_KYCUTILITY = 'KYCUtility';
    public static final String APEXCLASSNAME_KEYDATE_TRIG_HANDLER = 'KeyDateTriggerHandler';
    public static final String COMPONENTTYPE = 'Apex Class';
    
    public static final String DEFAULT_RISK_RATING_HIGH = 'High';
    public static final String DEFAULT_RISK_RATING_MINIMUM = 'Minimum_due_days';
    // Static constants for Key Dates
   	public static final String STRING_KEYDATE_DUEDATE_OVERRIDE = 'Due Date Override';
    public static final String STRING_KEYDATE_DUEDATE = 'Due Date';
    public static final String STRING_KEYDATE_ATTESTATION = 'Attestation Date';
    public static final Boolean BOOLEAN_TRUE = True;
    public static final Boolean BOOLEAN_FALSE = False;
    public static final String STRING_KYC = 'KYC';
    // Static constant for Stop Code
    public static final String STRING_STOPCODEPICKLISTVALUE = 'Stop Code';           
    
    // Static constants for PoP Statuses
    public static final String STRING_POP_STATUS_PENDING_APPLICATION = 'Pending Application';
    public static final String STRING_POP_STATUS_SUCCESS_APPLICATION = 'Application Successful';
    public static final String STRING_POP_STATUS_PENDING_REVOCATION = 'Pending Revocation';
    public static final String STRING_POP_STATUS_SUCCESS_REVOCATION = 'Revocation Successful';
    
    // Static constant for KYC Status__c
    //public static final String STRING_STATUS_KYC_TYPE = 'KYC Details Control Status';
    public static final String STRING_STATUS_KYC_TYPE = 'KYC Details Control';
    public static final String STRING_STATUS_KYC_CODE_ACTIVE = 'KYCA';
    public static final String STRING_STATUS_KYC_CODE_INACTIVE = 'KYCIA';
    public static final String STRING_STATUS_KYC_DESCRIPTION_ACTIVE = 'Active';
    public static final String STRING_STATUS_KYC_DESCRIPTION_INACTIVE = 'Inactive';     

    // Static constant for "Anti-Money Laundering" Status__c
    public static final String STRING_STATUS_AML_TYPE = 'Anti-Money Laundering';
    
    // Static constant for PoP Command Label
    public static final String STRING_POP_CMD_LABEL = 'KYC_PoP';
    
    // Static constants for Property Codes and Values
    public static final String STRING_BRISBANE_PROPERTY_CODE = '1';
    public static final String STRING_BRISBANE_PROPERTY_VALUE = 'BRISBANE';
    public static final String STRING_GOLDCOAST_PROPERTY_CODE = '2';
    public static final String STRING_GOLDCOAST_PROPERTY_VALUE = 'GOLD COAST';
    public static final String STRING_SYDNEY_PROPERTY_CODE = '3';
    public static final String STRING_SYDNEY_PROPERTY_VALUE = 'SYDNEY';
    
    // Static constants for PoP Statuses (Applied and Revoked)
    public static final String STRING_PoP_NAME_APPLIED = 'KYC Details Control';
    public static final String STRING_PoP_NAME_REVOKED = 'KYC Details Control';
    public static final String STRING_PoP_STATUS_REVOCATION = 'revocation';
    
    
    public static final String STRING_DESCRIPTION_DEFAULT_DUE_DATE = 'This Due Date record is generated based on the creation date of the associated Contact.';
    //public static final String STRING_API_AZURE_PROFILE = 'StarAPIUserforAzure';
    public static final String STRING_API_AZURE_PROFILE = 'System Administrator';
    public static final String STRING_SKIP_VALIDATION_CP = 'Skip_Validations_Permission';

    //Static constants for Restriction object - Restriction fields
    public static final String STRING_RESTRICTION_TYPE_FUNDS = 'Funds';
    public static final String STRING_RESTRICTION_TYPE_MARKETING_COMMS = 'Receive Marketing Communications';
    public static final String STRING_RESTRICTION_TYPE_CASINO_POINTS = 'Casino Points';
    public static final String STRING_RESTRICTION_TYPE_DISCOUNTS = 'Discounts';
    public static final String STRING_RESTRICTION_TYPE_HOTEL = 'Hotel Bookings';
    public static final String STRING_RESTRICTION_TYPE_PARKING = 'Parking benefits';
    public static final String STRING_RESTRICTION_TYPE_TIER_LEVEL_LOST = 'Tier Level Lost';
    public static final String STRING_RESTRICTION_ENFORCEMENT_STATUS_ACTIVE = 'Active';
    public static final String STRING_RESTRICTION_ENFORCEMENT_STATUS_REVOKED = 'Revoked';
    public static final String STRING_RESTRICTION_ENFORCEMENT_STATUS_OVERRIDDEN = 'Overridden';
    public static final String STRING_CONTACT_PATRON_STATUS_EXCLUDED_ALL = 'Excluded All';
    
    //Static constants for Exclusion Management Flow Names
    public static final String STRING_APPLY_EXCLUSION_FLOW = 'Apply_Exclusion_Flow';
    public static final String STRING_APPLY_CONTRAVENTION_FLOW = 'Apply_Contravention';
    public static final String STRING_APPLY_TPOE_FLOW = 'Apply_TPOE';
    public static final String STRING_CASE_REVOCATION_OUTCOME = 'Exl_Case_Revocation_Outcome';

}