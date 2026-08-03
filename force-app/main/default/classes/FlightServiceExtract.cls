public class FlightServiceExtract {
    public Id RecordId {get;set;}
    private final List <Other_Traveller__c> OtherTraveller;
    private final List <Service__c> PatronDetails;
    
    public FlightServiceExtract(ApexPages.StandardController stdController){
        RecordId  = ApexPages.currentPage().getParameters().get('id');
        this.OtherTraveller = [SELECT Id, Passport_Number__c, DOB__c, Patron_ID__c, First_Name__c, Surname__c, Title__c FROM Other_Traveller__c Where Service__c = :RecordId ORDER BY CreatedDate ASC];
        //List <Service__c> vipBookingId = [SELECT Id,VIP_Booking__c FROM Service__c Where Id = :RecordId ORDER BY CreatedDate DESC];
        
        this.PatronDetails = [SELECT Id, Contact__r.LastName, Contact__r.FirstName, Contact__r.Title FROM Service__c Where Id = :RecordId ORDER BY CreatedDate DESC];
    }
    
    public List <Other_Traveller__c> getOtherTraveller() {
        return OtherTraveller;
    }
    
    public List <Service__c> getPatronDetails() {
        return PatronDetails;
    }
    
    public String getDevice() {
        String extension;
        Boolean isMobile = UserInfo.getUiTheme() == 'Theme4t';
        
        if(isMobile){
            extension = 'html';
        }else{
            extension = 'pdf';
        }
        
        return extension;
    }
}