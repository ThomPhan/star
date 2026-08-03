/**
 * @description       : 
 * @author            : rhysjohn.delacruz@simplus.com
 * @group             : 
 * @last modified on  : 02-03-2022
 * @last modified by  : rhysjohn.delacruz@simplus.com
 * Modifications Log 
 * Ver   Date         Author                          Modification
 * 1.0   02-03-2022   rhysjohn.delacruz@simplus.com   Initial Version
**/
public class VIPBookingController {
    
    @AuraEnabled
    public static List<VIPBookingDataProvider.VIPBookingWrapper> getIDDetailsByContactId(String recordId){

        return VIPBookingDataProvider.getIDDetailsByContactId(recordId);
    }
}