global class ScheduleTripsUpdate implements Schedulable {
   global void execute(SchedulableContext sc) {
      Update365CheckboxBatch updateTripCheckbox = new Update365CheckboxBatch(); 
      database.executebatch(updateTripCheckbox);
   }
}