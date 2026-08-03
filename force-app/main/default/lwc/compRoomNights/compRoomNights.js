import { LightningElement, api, wire, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import runCallOut from '@salesforce/apex/CompRoomNightDataProvider.runCallOut';
import getLoyaltyRec from '@salesforce/apex/CompRoomNightDataProvider.getLoyaltyRec';
import ID_FIELD from '@salesforce/schema/Loyalty__c.Id';
import ENTITLEMENT_FIELD from '@salesforce/schema/Loyalty__c.Comp_Room_Night_Entitlement__c';
import USED_FIELD from '@salesforce/schema/Loyalty__c.Comp_Room_Night_Used__c';
import MONTH_FIELD from '@salesforce/schema/Loyalty__c.Comp_Room_night_remaining_for_the_Month__c';
import YEAR_FIELD from '@salesforce/schema/Loyalty__c.Comp_Room_Night_Remaining__c';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class CompRoomNights extends LightningElement {

    compRoomNightEntitlement;
    compRoomNightRemainingForTheYear;
    compRoomNightRemainingForTheMonth;
    compRoomMonthlyBalances = [];

    error;
    lastSuccessfulUpdate;
    @api recordId;

    get containerLarge() {
        switch(FORM_FACTOR) {
          case 'Large':
          return true;
          case 'Small':
          return false;
          default: return true
        }
      }
      get containerSmall() {
        switch(FORM_FACTOR) {
          case 'Large':
          return false;
          case 'Small':
          return true;
          default: return false
        }
      }
    
    
    @wire(getLoyaltyRec, {loyaltyId: '$recordId'}) 
    loyaltyRecord(returnVal, error){
        if(returnVal.data){
            console.log('loyaltyRecord data '+ returnVal.data);
            this.lastSuccessfulUpdate = returnVal.data;
        }else if(error){
            console.log('no data '+ this.lastSuccessfulUpdate );
            console.log(error);
       }
    };

    connectedCallback(){
        runCallOut({ loyaltyId: this.recordId })
            .then((result) => {
                this.compRoomNightEntitlement = result.entitlement;
                this.compRoomNightRemainingForTheYear = result.balance;
                this.compRoomMonthlyBalances = result.monthlyBalances;
    
                let rightNow = new Date();
                rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
                let yearToday = rightNow.toISOString().slice(0,4);
                let monthToday = rightNow.toISOString().slice(5,7);
                let currentRemaining = 0;
                let currentUsed = 0;
    
                this.compRoomMonthlyBalances.forEach(myFunction);
                function myFunction(item) {
                    if(item.year == yearToday && item.month == monthToday){ 
                        currentUsed = parseInt(item.used);
                        currentRemaining = parseInt(item.remaining);
    
                    }
                }
                this.compRoomNightRemainingForTheMonth = currentRemaining;

                let fields = {};
                    fields[ID_FIELD.fieldApiName] = this.recordId;
                    fields[ENTITLEMENT_FIELD.fieldApiName] = parseInt(this.compRoomNightEntitlement);
                    fields[USED_FIELD.fieldApiName] = currentUsed;
                    fields[MONTH_FIELD.fieldApiName] = currentRemaining;
                    fields[YEAR_FIELD.fieldApiName] = this.compRoomNightRemainingForTheYear;

                let recordInput = { fields };

                updateRecord(recordInput);
            })
            .catch((error) => {
                this.error = error;
                console.log(error);
            });
    }
}