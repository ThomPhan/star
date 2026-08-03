import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationBackEvent , FlowNavigationNextEvent, FlowAttributeChangeEvent  } from 'lightning/flowSupport';
import getServiceRecord from '@salesforce/apex/BookingServiceTriggerHandler.getServiceRecord';

import VIPB_Edit_IsConfirmed from '@salesforce/label/c.VIPB_Edit_IsConfirmed';
import VIPB_Edit_IsNotConfirmed from '@salesforce/label/c.VIPB_Edit_IsNotConfirmed';

const carTypes = [
	//CRM2-3375
	//New Car Types Updated to Equity Fleet
	//SYDNEY CAR TYPES
	{
		"Property": "Sydney",
		"Limousine": "Sedan (3 seater)",
		"value": "Sedan (3 seater)"
	},
	{
		"Property": "Sydney",
		"Limousine": "Premium Sedan (3 seater)",
		"value": "Premium Sedan (3 seater)"
	},
	{
		"Property": "Sydney",
		"Limousine": "SUV (3 seater)",
		"value": "SUV (3 seater)"
	},
	{
		"Property": "Sydney",
		"Limousine": "Mini Van (7 seater)",
		"value": "Mini Van (7 seater)"
	},
	{
		"Property": "Sydney",
		"Limousine": "Sprinter (11 seater)",
		"value": "Sprinter (11 seater)"
	},
	{
		"Property": "Sydney",
		"Limousine": "Minibus (22 seater) – 24 hour notice",
		"value": "Minibus (22 seater) – 24 hour notice"
	},
	{
		"Property": "Sydney",
		"Limousine": "Coach (30 seater) – 48 hour notice",
		"value": "Coach (30 seater) – 48 hour notice"
	},
	{
		"Property": "Sydney",
		"Limousine": "Coach (42 seater) – 48 hour notice",
		"value": "Coach (42 seater) – 48 hour notice"
	},
	//GOLD COAST CAR TYPES
	{
		"Property": "Gold Coast",
		"Limousine": "Sedan (3 seater)",
		"value": "Sedan (3 seater)"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "Premium Sedan (3 seater)",
		"value": "Premium Sedan (3 seater)"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "SUV (3 seater)",
		"value": "SUV (3 seater)"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "Mini Van (7 seater)",
		"value": "Mini Van (7 seater)"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "Sprinter (11 seater)",
		"value": "Sprinter (11 seater)"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "Minibus (22 seater) – 48 hour notice",
		"value": "Minibus (22 seater) – 48 hour notice"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "Coach (30 seater) – 48 hour notice",
		"value": "Coach (30 seater) – 48 hour notice"
	},
	{
		"Property": "Gold Coast",
		"Limousine": "Coach (42 seater) – 48 hour notice",
		"value": "Coach (42 seater) – 48 hour notice"
	},
	//BRISBANE CAR TYPES
	{
		"Property": "Brisbane",
		"Limousine": "Sedan (3 seater)",
		"value": "Sedan (3 seater)"
	},
	{
		"Property": "Brisbane",
		"Limousine": "Premium Sedan (3 seater)",
		"value": "Premium Sedan (3 seater)"
	},
	{
		"Property": "Brisbane",
		"Limousine": "SUV (3 seater)",
		"value": "SUV (3 seater)"
	},
	{
		"Property": "Brisbane",
		"Limousine": "Mini Van (7 seater)",
		"value": "Mini Van (7 seater)"
	},
	{
		"Property": "Brisbane",
		"Limousine": "Sprinter (11 seater)",
		"value": "Sprinter (11 seater)"
	},
	{
		"Property": "Brisbane",
		"Limousine": "Minibus (22 seater) – 48 hour notice",
		"value": "Minibus (22 seater) – 48 hour notice"
	},
	{
		"Property": "Brisbane",
		"Limousine": "Coach (30 seater) – 48 hour notice",
		"value": "Coach (30 seater) – 48 hour notice"
	},
	{
		"Property": "Brisbane",
		"Limousine": "Coach (42 seater) – 48 hour notice",
		"value": "Coach (42 seater) – 48 hour notice"
	}
];

//CRM2-2909 - Added new values
const flightLocs = ['Sydney Airport Dom Terminal','Sydney Airport Intl Terminal', 'Gold Coast Airport', 'Brisbane Airport Dom Terminal','Brisbane Airport Intl Terminal', 'Gold Coast Airport Dom Terminal', 'Gold Coast Airport Intl Terminal'];


export default class CreateLimoBookingService extends LightningElement {
		@api recordId;
		@api vipBookingId;
		@api vipBookingProperty;
		@api serviceRecord;
		@api carTypePreference;
		@api recordTypeId;
		@api dmlResult;
		@api serviceRecId = '';
		@api costCentre;
		@api contactMobile;

		serviceOutputId;
		listOfCars = [];
		filteredCarTypes = [];
 
		@track showOtherPickUp;
		@track showOtherDropOff;

		@track showPickUpFlight = false;
		@track showDropoffFlight = false;

		@track mobileFieldError;
		

		bookingStatusText1;
		bookingStatusText2;
		carTypeDisabled = true;

		label = {
			VIPB_Edit_IsConfirmed,
			VIPB_Edit_IsNotConfirmed
		};

		connectedCallback(){
				if(this.serviceRecId){
					this.getServiceRec();
					this.handleCarSearch();
				}
			}

		getServiceRec(){

				getServiceRecord({serviceRecId : this.serviceRecId})
				.then(result=>{
						this.showOtherPickUp = result.Pick_Up_Location__c == 'Other' ? true : false;

						this.showOtherDropOff = result.Drop_Off_Location__c == 'Other' ? true : false;
						
						this.showPickUpFlight = flightLocs.includes(result.Pick_Up_Location__c) ? true : false;

						this.showDropoffFlight = flightLocs.includes(result.Drop_Off_Location__c ) ? true : false;

						if(result.Limo_Booking_Status__c == 'Confirmed'){
								this.bookingStatusText1 = true;
						}
						else if(result.Limo_Booking_Status__c == 'New Booking' ||
										result.Limo_Booking_Status__c == 'Amendment' ||
										result.Limo_Booking_Status__c == 'Request Cancellation'){
										
										this.bookingStatusText2 = true;
						}
				})
				.catch(error=>{
						console.log('@@@Error Apex ', error);
				})
		}

		checkPickUpField(event){
				this.handleCarSearch();
				let selectedPickup = event.target.value;
				console.log('selectedPickup :', selectedPickup);
				if(selectedPickup){
					this.carTypeDisabled = false;
				}else{
					this.carTypeDisabled = true;
				}
				this.showOtherPickUp = false;

				if(selectedPickup == 'Other'){  
						this.showOtherPickUp = true;
						this.showPickUpFlight = false;
				}

				if(flightLocs.includes(selectedPickup)){
					this.showPickUpFlight = true;
					this.showOtherPickUp = false;
				}
				else{
					this.showPickUpFlight = false;
				}
		}

		checkDropOffField(event){
				this.showOtherDropOff = false;
				let selectedDropOff = event.target.value;
				if(selectedDropOff == 'Other'){
						this.showOtherDropOff = true;
						this.showDropoffFlight = false;
				}

				if(flightLocs.includes(selectedDropOff)){
					this.showDropoffFlight = true;
					this.showOtherDropOff = false;
				}
				else{
					this.showDropoffFlight = false;
				}
		}

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
				const attributeChangeEvent = new FlowAttributeChangeEvent('dmlResult', 'Error');
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

		handleCarSearch(){
			console.log('@@@this.vipBookingProperty ', this.vipBookingProperty);
				if(this.vipBookingProperty){
						this.filteredCarTypes = carTypes
						.filter( r =>  r.Property == this.vipBookingProperty);

						this.listOfCars = [];
						this.filteredCarTypes.forEach(car=>{
								let carVar = { label : car.Limousine, value : car.value };
								this.listOfCars.push(carVar);
						})
				}

		}

		@track selectedCar;
		handleCarChange(event){
				this.selectedCar = event.target.value;

		}

		handleSubmit(event){
				event.preventDefault();       // stop the form from submitting

				let fields = JSON.parse(JSON.stringify((event.detail.fields)));
				fields.Id = this.serviceRecId;

				console.log('@@@ error ' + this.mobileFieldError);

				if(this.mobileFieldError == null || this.mobileFieldError == ''){

					const attributeChangeEvent = new FlowAttributeChangeEvent('serviceRecord', fields);
					this.dispatchEvent(attributeChangeEvent);

					const attributeNextEvent = new FlowNavigationNextEvent();
					this.dispatchEvent(attributeNextEvent);
				}
		}

		validateMobileField(event){

			let mobileInput = event.target.value;

			console.log('@@@ ' + mobileInput);
			//console.log('### ' + inputField);

			const regex = /^[0-9+ ]+$/;

			// An empty value is considered valid here, but you can add a required check if needed.
			if (mobileInput && !regex.test(mobileInput)) {
				// If the value is not empty and doesn't match the pattern, show an error.
				this.mobileFieldError = 'Only numbers, spaces and + are allowed';
			} else {
				// If the value is valid or empty, clear any existing error message.
				this.mobileFieldError = '';
			}
		}
}