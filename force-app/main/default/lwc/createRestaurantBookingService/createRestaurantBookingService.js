import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationBackEvent , FlowNavigationNextEvent, FlowAttributeChangeEvent  } from 'lightning/flowSupport';
import getServiceRecord from '@salesforce/apex/BookingServiceTriggerHandler.getServiceRecord';

import VIPB_Edit_IsConfirmed from '@salesforce/label/c.VIPB_Edit_IsConfirmed';
import VIPB_Edit_IsNotConfirmed from '@salesforce/label/c.VIPB_Edit_IsNotConfirmed';

export default class CreateRestaurantBookingService extends LightningElement {
    @api recordId;
    @api vipBookingId;
    @api vipBookingProperty;
    @api recordTypeId;
    @api dmlResult;
    @api serviceRecId = '';
    @api bookingDietaryReq;
    @api bookingDiningNotes;
    @api serviceRecord;
    @api costCentre;

    bookingDateTime;
    bookingStatus;
    bookingVenue;
    bookingPax;
    bookingReference;
    bookingFollowUp;

    bookingStatusText1;
    bookingStatusText2;
    label = {
        VIPB_Edit_IsConfirmed,
        VIPB_Edit_IsNotConfirmed
    };

    connectedCallback(){
        if(this.serviceRecId){
          this.getServiceRec();
        }
    }

    getServiceRec(){
        getServiceRecord({serviceRecId : this.serviceRecId})
        .then(result=>{
    
          if(result.Restaurant_Booking_Status__c == 'Confirmed'){
            this.bookingStatusText1 = true;
          }
          else if(result.Restaurant_Booking_Status__c == 'New Booking' ||
                  result.Restaurant_Booking_Status__c == 'Amendment' ||
                  result.Restaurant_Booking_Status__c == 'Request Cancellation'){
                  
                    this.bookingStatusText2 = true;
          }
          
          this.handleSearchButton();
        })
        .catch(error=>{
          console.log('@@@Error Apex ', error);
        })
      }

    recordSuccess(event){
        this.serviceOutputId = event.detail.id;

        const attributeNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(attributeNextEvent);
    }
    
    recordError(event){
        this.dispatchEvent(
            new ShowToastEvent({
                message: 'There was an error in creating the record!',
                variant: 'error'
            })
        );
        console.log('@@@Error ', JSON.parse(JSON.stringify(event)));
        const attributeChangeEvent = new FlowAttributeChangeEvent('dmlResult', 'Error');
        this.dispatchEvent(attributeChangeEvent);

        const attributeNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(attributeNextEvent);
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting

        let fields = JSON.parse(JSON.stringify((event.detail.fields)));
        fields.Id = this.serviceRecId;
        const attributeChangeEvent = new FlowAttributeChangeEvent('serviceRecord', fields);
        this.dispatchEvent(attributeChangeEvent);

        const attributeNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(attributeNextEvent);
    }

    endFlow(){

        if(this.serviceRecId == ''){
            const navigateFinishEvent = new FlowNavigationBackEvent ();
            this.dispatchEvent(navigateFinishEvent);
        }
        else{
            window.open('/' + this.serviceRecId, "_self");
        }
    }
}