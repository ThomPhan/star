@isTest
public class VIPBookingDataProviderTest {
    @isTest
    public static void callVipBookingController(){
        Account accRec = new Account();
        accRec.Name = 'test';
        INSERT accRec;
        
        Contact contRec = new Contact();
        contRec.LastName = 'Test';
        contRec.FirstName = 'Sample';
        INSERT contRec;
        
        System.assertEquals(true, VIPBookingController.getIDDetailsByContactId(contRec.Id) != null, 'Return Value is Null');
    }
}