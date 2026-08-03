/*
 * @Class Name  : BookingServiceTriggerHandler
 * @Summary     : Helper class for the 'BookingServiceTrigger' trigger 
 * @author      : Simplus
 * @Description : This class contains the logic when creating Service Records
 * @version     : $Revision: 1.0 $, $Date: 2022-02-28
 *                2.0 1/18/2023 - Commented out methods since VIP Booking will not be used anymore
*/
public class BookingServiceTriggerHandler extends TriggerHandlerBase { //extending the trigger framework
    //new method which is required when we extend the TriggerHandlerBase class
    public BookingServiceTriggerHandler (String triggerName) {
      super(triggerName);
    }

    static final String APEXCLASSNAME = 'BookingServiceTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';
    static final String FLIGHT_BOOKING = 'Flight_Booking';
    static final String HOTEL_BOOKING = 'Hotel_Booking';
    static final String LIMO_SERVICE_BOOKING = 'Limo_Service_Booking';
    static final String RESTAURANT_BOOKING = 'Restaurant_Booking';

    static Map<Id, RecordType> serviceRecTypeMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Service__c']);

    //public static void onBeforeInsert(List<Service__c> serviceList){
    public override void beforeInsert(List<SObject> newServiceList){
        List<Service__c> serviceList = (List<Service__c>)newServiceList;
        //Service Field upon insert
        setPatronNameField(serviceList);
        setService(serviceList);
        //Check Number of Nights or Departure Date
        updateNumOfNights(serviceList, null);
        //setMaximumPax(serviceList, null);
        setLimoBookingReference(serviceList);
        getFrequentFlyerNumber(serviceList);
        setStaticDateInsert(serviceList);
    }
    
    //public static void onBeforeUpdate(List<Service__c> serviceList, Map<Id, Service__c> oldServiceMap){
    public override void beforeUpdate(List<SObject> oldServiceList, List<SObject> newServiceList, Map<Id, SObject> tempOldServiceMap, Map<Id, SObject> tempNewServiceMap){
        List<Service__c> serviceList = (List<Service__c>)newServiceList;
        Map<Id, Service__c> oldServiceMap = (Map<Id, Service__c>)tempOldServiceMap;
        
        getFrequentFlyerNumber(serviceList);
        otherFieldChecker(serviceList, oldServiceMap);
        setServiceAmendment(serviceList, oldServiceMap);
        setPUTime(serviceList);
        updateNumOfNights(serviceList, oldServiceMap);
        setStaticDateUpdate(new Map<Id, Service__c>(serviceList), oldServiceMap);
    }
    
    /*public static void onAfterInsert(List<Service__c> serviceList){

        
    }
    
    public static void onAfterUpdate(List<Service__c> serviceList, Map<Id, Service__c> oldServiceMap){
        
    }*/

    //Method to update the Number of Nights Field
    public static void updateNumOfNights(List<Service__c> newService, Map<Id, Service__c> oldServiceMap){
        Id hotelRecordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByName().get('Hotel Booking').getRecordTypeId();
        Service__c oldServiceRec = new Service__c();
        
        try{
        if(oldServiceMap != NULL){
            for(Service__c serviceObj : newService){
                if(hotelRecordTypeId == serviceObj.RecordTypeId){
                    oldServiceRec = oldServiceMap.containsKey(serviceObj.Id) ? oldServiceMap.get(serviceObj.Id) : new Service__c();
                    if(serviceObj.Arrival_Date__c != oldServiceRec.Arrival_Date__c || serviceObj.Departure_Date__c != oldServiceRec.Arrival_Date__c){
                        serviceObj.Number_of_Nights__c = serviceObj.Arrival_Date__c.daysBetween(serviceObj.Departure_Date__c);
                    }
                }
            }
        }else{
            for(Service__c serviceObj : newService){
                if(hotelRecordTypeId == serviceObj.RecordTypeId){
                    serviceObj.Number_of_Nights__c = serviceObj.Arrival_Date__c.daysBetween(serviceObj.Departure_Date__c);
                }
            }
        }
        }catch(Exception e){
            ErrorLogger.createLog(APEXCLASSNAME, 'updateNumOfNights', e, null, COMPONENTTYPE);
        }
    }

    //Populate Maximum Pax
    /*public static void setMaximumPax(List<Service__c> serviceList, Map<Id, Service__c> oldServiceMap){

        //Get Vehicle Type Custom Setting
        List<Vehicle_Type__c> vehicleTpyeList = [SELECT Name, Limousine__c, Property__c, Seat_Capacity__c FROM Vehicle_Type__c];
        Map<String, Decimal> vehicleTypeMap = new Map<String, Decimal>();
        if(!vehicleTpyeList.isEmpty()){

            for(Vehicle_Type__c vt : vehicleTpyeList){
                
                vehicleTypeMap.put(vt.Property__c + '-' + vt.Limousine__c, vt.Seat_Capacity__c);
            }
        }

        for(Service__c serviceRec : serviceList){

            //LIMO_BOOKING
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){

                Decimal paxNum = serviceRec.Pax__c != null ? serviceRec.Pax__c : 0;

                if(serviceRec.Property__c != null && serviceRec.Car_Type__c != null){

                    if(vehicleTypeMap.containsKey(serviceRec.Property__c + '-' + serviceRec.Car_Type__c)){

                        if(paxNum > vehicleTypeMap.get(serviceRec.Property__c + '-' + serviceRec.Car_Type__c)){

                            serviceRec.addError('Pax cannot be more than Vehicle Maximum Pax');
                        }
                        else{
                            serviceRec.Maximum_Pax__c = vehicleTypeMap.get(serviceRec.Property__c + '-' + serviceRec.Car_Type__c);
                        }
                    }
                }
            }
        }
    }*/

    //Autonumber For Limo Booking
    public static void setLimoBookingReference(List<Service__c> serviceList){

        List<Service__c> limoBookingList = [SELECT Id, Limo_Booking_Reference__c FROM Service__c WHERE RecordType.DeveloperName =: LIMO_SERVICE_BOOKING AND Limo_Booking_Reference__c != null ORDER BY Limo_Booking_Reference__c DESC LIMIT 1];
        //Starting number of 400000
        Integer tempLimoBookingNum = 400000;
        if(!limoBookingList.isEmpty()){
            String regex = '[a-zA-Z]{1,}|\\-';
            String tempNumber = limoBookingList[0].Limo_Booking_Reference__c.replaceAll(regex, '');
            tempLimoBookingNum = Integer.valueOf(tempNumber);
        }

        for(Service__c serviceRec : serviceList){

            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){

                tempLimoBookingNum++;
                String numToAdd = String.valueOf(tempLimoBookingNum).leftPad(7, '0');
                serviceRec.Limo_Booking_Reference__c = 'SOV-' + numToAdd;
            }
        }
    }

    //Set Service Picklist Field
    public static void setService(List<Service__c> serviceList){

        for(Service__c serviceRec : serviceList){

            //Flight Record Type
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == FLIGHT_BOOKING){
                
                serviceRec.Service__c = 'Flight';
            }
            //Hotel Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == HOTEL_BOOKING){

                serviceRec.Service__c = 'Hotel';
            }
            //Limo Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){

                serviceRec.Service__c = 'Limo';
            }
            //Restaurant Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == RESTAURANT_BOOKING){

                serviceRec.Service__c = 'Restaurant';
            }
        }
    }
    
    public static Id returnRecordTypeId(String recordTypeName){
        Id serviceRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        return serviceRTId;
    }

    //Primary patron only Existing patron only. 
    //Would be great to make this a free text field if an existing Patron does not have anything against this stored.
    public static void getFrequentFlyerNumber(List<Service__c> serviceList){
        Map<Id, VIP_Booking__c> vipBookingIdRecMap = new Map<Id, VIP_Booking__c>();
        Set<Id> contactIdSet = new Set<Id>();
       
        try{
            for(Service__c tempService : serviceList){
                tempService.Frequent_flyer_number__c = tempService.Contact__r.Frequent_flyer_number__c;
            }

        }catch(Exception e){
            System.debug('@@@Error ' + e.getMessage());
            System.debug('@@@Error ' + e.getStackTraceString());
        }
    }

    public static void otherFieldChecker(List<Service__c> serviceList, Map<Id, Service__c> oldServiceMap){
        
        List<String> flightLocs = new List<String>{'Sydney Airport Dom Terminal','Sydney Airport Intl Terminal','Gold Coast Airport','Brisbane Airport Dom Terminal','Brisbane Airport Intl Terminal', 'Gold Coast Airport Dom Terminal', 'Gold Coast Airport Intl Terminal'};

        for(Service__c serviceRec : serviceList){
            //Flight Record Type
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == FLIGHT_BOOKING){ 
                if(serviceRec.Flying_to__c != 'Other' && serviceRec.Flying_to__c != oldServiceMap.get(serviceRec.Id).Flying_to__c){
                    serviceRec.Flying_to_other_location__c = '';
                }
                if(serviceRec.Flying_from__c != 'Other' && serviceRec.Flying_from__c != oldServiceMap.get(serviceRec.Id).Flying_from__c){
                    serviceRec.Flying_from_other_location__c = '';
                }
                if(serviceRec.Flight_Region__c != 'International' && serviceRec.Flight_Region__c != oldServiceMap.get(serviceRec.Id).Flight_Region__c){
                    serviceRec.Passport_Number__c = '';
                }
                if(serviceRec.One_way_OR_Return__c != 'Return' && serviceRec.One_way_OR_Return__c != oldServiceMap.get(serviceRec.Id).One_way_OR_Return__c){
                    serviceRec.Returning_Date_and_Time__c = null;
                }
            }
            //Hotel Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == HOTEL_BOOKING){
                if(serviceRec.Special_Request__c != 'OTHERS' && serviceRec.Special_Request__c != oldServiceMap.get(serviceRec.Id).Special_Request__c){
                    serviceRec.Other_Special_Request__c = '';
                }
                if(serviceRec.MOP_Status__c != 'OTHER' && serviceRec.MOP_Status__c != oldServiceMap.get(serviceRec.Id).MOP_Status__c){
                    serviceRec.Other_MOP_Status__c = '';
                }
            }
            //Limo Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){
                if(serviceRec.Pick_Up_Location__c != 'Other' && serviceRec.Pick_Up_Location__c != oldServiceMap.get(serviceRec.Id).Pick_Up_Location__c){
                    serviceRec.Other_Pick_Up_Location__c = '';
                }
                if(serviceRec.Drop_Off_Location__c != 'Other' && serviceRec.Drop_Off_Location__c != oldServiceMap.get(serviceRec.Id).Drop_Off_Location__c){
                    serviceRec.Other_Drop_Off_Location__c = '';
                }
                if(!flightLocs.contains(serviceRec.Pick_Up_Location__c) && serviceRec.Pick_Up_Location__c != oldServiceMap.get(serviceRec.Id).Pick_Up_Location__c){
                    //Pick_Up_Flight_Details__c
                    serviceRec.Pick_Up_Flight_Details__c = '';
                }
                if(!flightLocs.contains(serviceRec.Drop_Off_Location__c) && serviceRec.Drop_Off_Location__c != oldServiceMap.get(serviceRec.Id).Drop_Off_Location__c){
                    //Drop_Off_Flight_Details__c
                    serviceRec.Drop_Off_Flight_Details__c = '';
                }
            }
            //Restaurant Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == RESTAURANT_BOOKING){
                //No OTHER fields as of now
            }
        }
    }

    public static void setServiceAmendment(List<Service__c> serviceList, Map<Id, Service__c> oldServiceMap){
        Map<String, String> flightFieldMap = getFieldSet('Flight_Field_Set');
        Map<String, String> hotelFieldMap = getFieldSet('Hotel_Field_Set');
        Map<String, String> limoFieldMap = getFieldSet('Limo_Field_Set');
        Map<String, String> restaurantFieldMap = getFieldSet('Restaurant_Field_Set');
        
        for(Service__c serviceRec : serviceList){
            //Set Flag to false for each Service Record
            Boolean hasChanged = false;
            //Flight Record Type
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == FLIGHT_BOOKING && serviceRec.Flight_Booking_Status__c != 'New Booking'){
                for(String field : flightFieldMap.values()){
                    if(serviceRec.get(field) != oldServiceMap.get(serviceRec.Id).get(field)){
                        hasChanged = true;
                    }
                }
                if(hasChanged){
                    serviceRec.Flight_Booking_Status__c = 'Amendment';
                }
            }
            //Hotel Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == HOTEL_BOOKING && serviceRec.Hotel_Booking_Status__c != 'New Booking'){
                for(String field : hotelFieldMap.values()){
                    if(serviceRec.get(field) != oldServiceMap.get(serviceRec.Id).get(field)){
                        hasChanged = true;
                    }
                }
                if(hasChanged){
                    serviceRec.Hotel_Booking_Status__c = 'Amendment';
                }
            }
            //Limo Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING && serviceRec.Limo_Booking_Status__c != 'New Booking'){
                for(String field : limoFieldMap.values()){
                    if(serviceRec.get(field) != oldServiceMap.get(serviceRec.Id).get(field)){
                        hasChanged = true;
                    }
                }
                if(hasChanged){
                    serviceRec.Limo_Booking_Status__c = 'Amendment';
                }
            }
            //Restaurant Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == RESTAURANT_BOOKING && serviceRec.Restaurant_Booking_Status__c != 'New Booking'){
                for(String field : restaurantFieldMap.values()){
                    if(serviceRec.get(field) != oldServiceMap.get(serviceRec.Id).get(field)){
                        hasChanged = true;
                    }
                }
                if(hasChanged){
                    serviceRec.Restaurant_Booking_Status__c = 'Amendment';
                }
            }
        }
    }
    
    public static Map<String, String> getFieldSet(String fieldSetApiName){
        List<Schema.FieldSetMember> fields = Schema.SObjectType.Service__c.fieldSets.getMap().get(fieldSetApiName).getFields();
        Map<String, String> fieldMap = new Map<String, String>();
        for(Schema.FieldSetMember f : fields){
            fieldMap.put(f.getFieldPath(), f.getFieldPath());
        }
        return fieldMap;
    }
    
    public static void setPUTime(List<Service__c> serviceList){
        for(Service__c serviceRec : serviceList){
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){  
                if(serviceRec.Pick_Up_Date_and_Time_Static__c != null){     

                    String[] timeSeparated = serviceRec.Pick_Up_Date_and_Time_Static__c.split(' ');
                    String tempHour = '';

                    String hourMinutes = timeSeparated[1];
                    String amPmIndicator = timeSeparated[2];
                    System.debug(hourMinutes + amPmIndicator);
                    Integer hour = Integer.valueOf(hourMinutes.split(':')[0]);
                    String minutes = hourMinutes.split(':')[1];

                    if (amPmIndicator.equalsIgnoreCase('PM') && hour != 12) {
                        hour += 12;
                    } else if (amPmIndicator.equalsIgnoreCase('AM') && hour == 12) {
                        hour = 0;
                    }
                    if(String.valueOf(hour).length() == 1){
                        tempHour = '0' + hour;
                    }
                    else{
                        tempHour = String.valueOF(hour);
                    }
                    serviceRec.PU_Time_Text__c = tempHour + ':' + minutes + ':00';
                }
            }
        }
    }

    public static void setPatronNameField(List<Service__c> serviceList){
        Set<Id> vipBookingSet = new Set<Id>();
        for(Service__c serv : serviceList){
            if(serv.Patron_Name_Text__c == null){
                serv.Patron_Name_Text__c = serv.Contact__r.FirstName + ' ' + serv.Contact__r.LastName;
            }
        }
    }
    
    @AuraEnabled
    public static Service__c getServiceRecord(Id serviceRecId){
        return [SELECT Id, Adult_Pax__c, Children_Pax__c, Hotel__c, Property__c, Room_Type__c, Arrival_Date__c, Departure_Date__c, MOP_Status__c, 
                Service__c.Special_Request__c, Hotel_Confirmation_Number__c, Pick_Up_Location__c, Drop_Off_Location__c, Flying_to__c, Flying_from__c, Flight_Region__c, One_way_OR_Return__c, Hotel_Booking_Status__c, Limo_Booking_Status__c, Flight_Booking_Status__c, Restaurant_Booking_Status__c, Pick_Up_Date_and_Time_Static__c, Depart_Date_and_Time_Static__c, Returning_Date_and_Time_Static__c, Booking_Date_and_Time_Static__c, Mobile__c FROM Service__c WHERE Id =: serviceRecId];
    }

    public static void setStaticDateInsert(List<Service__c> serviceList){
        
        string SYDNEY_TZ = ' (GMT+10:00) Canberra, Melbourne, Sydney';
        string GOLDCOAST_TZ = ' (GMT+10:00) Brisbane, Gold Coast';
        string BRISBANE_TZ = ' (GMT+10:00) Brisbane, Gold Coast';

        String timezone = '';
        for(Service__c serviceRec : serviceList){
            
            timezone = '';

            if(serviceRec.Property__c == 'Sydney'){
                
                timezone = SYDNEY_TZ;
            }
            else if(serviceRec.Property__c == 'Gold Coast'){

                timezone = GOLDCOAST_TZ;
            }
            else if(serviceRec.Property__c == 'Brisbane'){

                timezone = BRISBANE_TZ;
            }

            //Flight Record Type
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == FLIGHT_BOOKING){

                if(serviceRec.Depart_Date_and_Time__c != null){

                    serviceRec.Depart_Date_and_Time_Static__c = serviceRec.Depart_Date_and_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
                else{
                    serviceRec.Depart_Date_and_Time_Static__c = '';
                }

                if(serviceRec.Returning_Date_and_Time__c != null){

                    serviceRec.Returning_Date_and_Time_Static__c = serviceRec.Returning_Date_and_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
                else{

                    serviceRec.Returning_Date_and_Time_Static__c = '';
                }
            }
            //Limo Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){


                if(serviceRec.Pick_Up_Date_and_Time__c != null){

                    serviceRec.Pick_Up_Date_and_Time_Static__c = serviceRec.Pick_Up_Date_and_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
                else{
                    serviceRec.Pick_Up_Date_and_Time_Static__c = '';
                }
            }
            //Restaurant Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == RESTAURANT_BOOKING){

                if(serviceRec.Booking_Date_and_Time__c != null){

                    serviceRec.Booking_Date_and_Time_Static__c = serviceRec.Booking_Date_and_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
                else{

                    serviceRec.Booking_Date_and_Time_Static__c = '';
                }
            }
        }
    }

    public static void setStaticDateUpdate(Map<Id, Service__c> serviceMap, Map<Id, Service__c> oldServiceMap){
        
        string SYDNEY_TZ = '(GMT+10:00) Canberra, Melbourne, Sydney';
        string GOLDCOAST_TZ = '(GMT+10:00) Brisbane, Gold Coast';
        string BRISBANE_TZ = '(GMT+10:00) Brisbane, Gold Coast';

        String timezone = '';
        for(Service__c serviceRec: serviceMap.values()){
            
            timezone = '';

            if(serviceRec.Property__c == 'Sydney'){
                
                timezone = SYDNEY_TZ;
            }
            else if(serviceRec.Property__c == 'Gold Coast'){

                timezone = GOLDCOAST_TZ;
            }
            else if(serviceRec.Property__c == 'Brisbane'){

                timezone = BRISBANE_TZ;
            }

            //Flight Record Type
            if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == FLIGHT_BOOKING){
                    
                Datetime newStartDate = serviceMap.get(serviceRec.Id).Depart_Date_and_Time__c;
                Datetime newEndDate = serviceMap.get(serviceRec.Id).Returning_Date_and_Time__c;

                Datetime oldStartDate = oldServiceMap.get(serviceRec.Id).Depart_Date_and_Time__c;
                Datetime oldEndDate = oldServiceMap.get(serviceRec.Id).Returning_Date_and_Time__c;

                if(newStartDate != oldStartDate){
                    // serviceRec.Depart_Date_and_Time_Static__c = newStartDate.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                    // serviceRec.Returning_Date_and_Time_Static__c = newEndDate.format('dd/MM/yyyy h:mm a') + ' ' + timezone;

                    if(serviceRec.Depart_Date_and_Time__c != null){

                        serviceRec.Depart_Date_and_Time_Static__c = serviceRec.Depart_Date_and_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                    }
                    else{
                        serviceRec.Depart_Date_and_Time_Static__c = '';
                    }
                }

                if(newEndDate != oldEndDate){

                    if(serviceRec.Returning_Date_and_Time__c != null){
    
                        serviceRec.Returning_Date_and_Time_Static__c = serviceRec.Returning_Date_and_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                    }
                    else{
    
                        serviceRec.Returning_Date_and_Time_Static__c = '';
                    }
                }
            }
            //Limo Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == LIMO_SERVICE_BOOKING){

                Datetime newStartDate = serviceMap.get(serviceRec.Id).Pick_Up_Date_and_Time__c;

                Datetime oldStartDate = oldServiceMap.get(serviceRec.Id).Pick_Up_Date_and_Time__c;

                if(newStartDate != oldStartDate){

                    serviceRec.Pick_Up_Date_and_Time_Static__c = newStartDate.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
            }
            //Restaurant Record Type
            else if(serviceRecTypeMap.get(serviceRec.RecordTypeId).DeveloperName == RESTAURANT_BOOKING){

                Datetime newStartDate = serviceMap.get(serviceRec.Id).Booking_Date_and_Time__c;

                Datetime oldStartDate = oldServiceMap.get(serviceRec.Id).Booking_Date_and_Time__c;

                if(newStartDate != oldStartDate){

                    serviceRec.Booking_Date_and_Time_Static__c = newStartDate.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
            }
        }
    }
}