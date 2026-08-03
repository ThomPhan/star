import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationBackEvent , FlowNavigationNextEvent, FlowAttributeChangeEvent  } from 'lightning/flowSupport';
import getServiceRecord from '@salesforce/apex/BookingServiceTriggerHandler.getServiceRecord';

import VIPB_Edit_IsConfirmed from '@salesforce/label/c.VIPB_Edit_IsConfirmed';
import VIPB_Edit_IsNotConfirmed from '@salesforce/label/c.VIPB_Edit_IsNotConfirmed';

export default class CreateFlightBookingService extends LightningElement {

    @api recordId;
    @api vipBookingId;
    @api vipBookingProperty;
    @api recordTypeId;
    @api dmlResult;
    @api frequentFlyerNumber;
    @api serviceRecId = '';
    @api serviceRecord;
    @api costCentre;

    flightBookingStatus;
    oneWayOrReturn;
    flightRegion;
    passportNumber;
    departDateTIme;
    returnDateTime;
    flyingFrom;
    flyingTo;
    flyingFromOther;
    flyingToOther;
    classOfTravel;
    flightNumber;
    airlinePreference;
    flightBookingReference;
    flightCharge;
    bookingComments;
    followUp;
    
    showFromOtherField;
    showToOtherField;
    showPassportField;
    showReturnField;

    bookingStatusText1;
    bookingStatusText2;

    label = {
      VIPB_Edit_IsConfirmed,
      VIPB_Edit_IsNotConfirmed
    };

    recordSuccess(event){
        this.serviceOutputId = event.detail.id;
        this.dispatchEvent(
            new ShowToastEvent({
                message: 'Service created!',
                variant: 'success'
            })
        );

        //const attributeChangeEvent = new FlowAttributeChangeEvent('dmlResult', this.serviceOutputId);
        //this.dispatchEvent(attributeChangeEvent);

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
    }

    // @wire(getRecord, { recordId: '$serviceRecId', fields: ['Service__c.Flying_to__c', 'Service__c.Flying_from__c', 'Service__c.Flight_Region__c', 'Service__c.One_way_OR_Return__c'] })
    // testserviceRecord( { error, data } ){
    //   if(data){
        
    //     this.showToOtherField = data.fields.Flying_to__c.value == 'Other' ? true : false;
    //     this.showFromOtherField = data.fields.Flying_from__c.value  == 'Other' ? true : false;
    //     this.showPassportField = data.fields.Flight_Region__c.value == 'International' ? true : false;
    //     this.showReturnField = data.fields.One_way_OR_Return__c.value == 'Return' ? true : false;
    //   }else if(error){
    //     console.log('Error: ', error);
    //   }
    // }

    connectedCallback(){
        if(this.serviceRecId){
          this.getServiceRec();
        }
      }
    
      getServiceRec(){
        getServiceRecord({serviceRecId : this.serviceRecId})
        .then(result=>{
          
            this.showToOtherField = result.Flying_to__c == 'Other' ? true : false;
            this.showFromOtherField = result.Flying_from__c == 'Other' ? true : false;
            this.showPassportField = result.Flight_Region__c == 'International' ? true : false;
            this.showReturnField = result.One_way_OR_Return__c == 'Return' ? true : false;

            if(result.Flight_Booking_Status__c == 'Confirmed'){
                this.bookingStatusText1 = true;
            }
            else if(result.Flight_Booking_Status__c == 'New Booking' ||
                    result.Flight_Booking_Status__c == 'Amendment' ||
                    result.Flight_Booking_Status__c == 'Request Cancellation'){
                    
                    this.bookingStatusText2 = true;
            }
        })
        .catch(error=>{
          console.log('@@@Error Apex ', error);
        })
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
    
    fromOtherSelected(event){

        this.showFromOtherField = false;

        if(event.target.value == 'Other'){
            this.showFromOtherField = true;
        }
    }

    toOtherSelected(event){
        this.showToOtherField = false;

        if(event.target.value == 'Other'){
            this.showToOtherField = true;
        }
    }

    checkRegionField(event){

        this.showPassportField = false;

        if(event.target.value == 'International'){
            this.showPassportField = true;
        }
    }

    checkOneWayOrReturnField(event){

        this.showReturnField = false;

        if(event.target.value == 'Return'){

            this.showReturnField = true;
        }
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
}