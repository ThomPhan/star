import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowNavigationBackEvent , FlowNavigationNextEvent, FlowAttributeChangeEvent  } from 'lightning/flowSupport';
import getServiceRecord from '@salesforce/apex/BookingServiceTriggerHandler.getServiceRecord';

import VIPB_Edit_IsConfirmed from '@salesforce/label/c.VIPB_Edit_IsConfirmed';
import VIPB_Edit_IsNotConfirmed from '@salesforce/label/c.VIPB_Edit_IsNotConfirmed';

const NOROOMS = 'No available rooms';
const SELECTROOM = 'Please select a room type:';
const ENTERPAX = 'Please enter Adult and Children pax';
const roomTypes = [
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "SKN - Superior King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "STN - Superior Twin",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "WKP - Accessible King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "EKP - Executive King Pyrmont",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "PHKN - Harbour King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "PHTN - Harbour Twin",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "EKH - Executive King Harbour",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "PSK - Premium",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "SSC - Star Suite",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "SSH - Harbour Star",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "D1H - Deluxe 1 bedroom",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "D2H - Deluxe 2 bedroom",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "RSH - Royale",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Grand",
			"Room": "PSH - Penthouse",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "1BP - 1 Bedroom Pyrmont",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "1BC - 1 Bedroom City",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "1BH - 1 Bedroom Harbour",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "2BP - 2 Bedroom Pyrmont",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "2BC - 2 Bedroom City",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "2BH - 2 Bedroom Harbour",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "2BPE - 2 Bedroom Ent",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "2BCL - 2 Bedroom Loft",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "2BG - 2 Bedroom Gym",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Star Residences",
			"Room": "3BH - 3 Bedroom Harbour",
			"Adult": "6",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "DRCK - Darling King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "DRCT - Darling Twin",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "WDRL - Accessible King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "DRHK - Harbour King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "IDHT - Interconnecting",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "JSUI - Jewel",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "JSUH - Jewel City",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "JSPA - Jewel Spa",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "JSPH - Jewel Spa City",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "ASCN - Adored",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "SSUI - Stellar",
			"Adult": "2",
			"Child": "2"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "SSUH - Stellar Harbour",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "ASCD - Adored Deluxe",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "PSCN - Penthouse",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "PSCJ - Junior Penthouse",
			"Adult": "4",
			"Child": "1"
	},
	{
			"Property": "Sydney",
			"Hotel": "SYD - The Darling",
			"Room": "PSCD - Penthouse Deluxe",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "SUK - Superior Deluxe King Room",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "SUT - Superior Deluxe Twin Room",
			"Adult": "3",
			"Child": "1"
	},
	{
		"Property": "Gold Coast",
		"Hotel": "GC - The Star Grand",
		"Room": "ACK - Accessible King Room",
		"Adult": "2",
		"Child": "0"
	},
	//Insert new rooms - CRM2-2691
	{
		"Property": "Gold Coast",
		"Hotel": "GC - The Star Grand",
		"Room": "AEK - Accessible Executive Deluxe King Room",
		"Adult": "2",
		"Child": "0"
	},
	{
		"Property": "Gold Coast",
		"Hotel": "GC - The Star Grand",
		"Room": "AMT - Ambulant Twin Room",
		"Adult": "3",
		"Child": "1"
	},
	//
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "CBK - Corner Balcony King Room",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "CBT - Corner Balcony Twin Room",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "EXK - Executive King Room",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "EXT - Executive Twin Room",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "GKS - Club Grande Suite",//CRM2-2846 changed from GKS - Club Suite to GKS - Club Grande Suite
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "XKS - Club Suite",//CRM2-2846 changed from XKS - Club Grande Suite to XKS - Club Suite
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "KKS - King Terrace Suite",//CRM2-2846 changed from KKS - Pacific View Suite to KKS - King Terrace Suite
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "VKS - Pacific View Suite",//CRM2-2846 changed from VKS - King Terrace Suite to VKS - Pacific View Suite
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "OKWN - Ocean Terrace Suite",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "PLNS - North Penthouses",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "PTNS - North Penthouses",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Star Grand",
			"Room": "PKNS - North Penthouses",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "JTS - Stellar Twin Suite",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "JKA - Stellar Accessible King Suite",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "SKS - Stellar King Suite",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "DKS - Penthouse Suite",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "DSS - Penthouse Spa Suite",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "DKM - Media Penthouse Deluxe Suite",//CRM2-2846 change from DKM - Penthouse Deluxe Suites to DKM - Media Penthouse Deluxe Suite
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "DKB - Billard Penthouse Deluxe Suite",//CRM2-2846 change from DKB - Penthouse Deluxe Suites to DKB - Billard Penthouse Deluxe Suite
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Gold Coast",
			"Hotel": "GC - The Darling",
			"Room": "DKE - Exercise Penthouse Deluxe Suite",//CRM2-2846 change from DKE - Penthouse Deluxe Suites to DKE - Exercise Penthouse Deluxe Suite
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "DK - Deluxe King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "CK - Casino King (18+)",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "DT - Deluxe Twin",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "CT - Casino Twin (18+)",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "WT - Wheelchair access Twin",
			"Adult": "3",
			"Child": "1"
	},
	//Insert new rooms - CRM2-2691
	{
		"Property": "Brisbane",
		"Hotel": "BNE - Treasury",
		"Room": "WK - Wheelchair access King",
		"Adult": "2",
		"Child": "0"
	},
	//
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "CW - Casino Wheelchair access Twin (18+)",
			"Adult": "3",
			"Child": "1"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "DD - Deluxe Double",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "PK - Parlour King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "CP - Casino Parlour King (18+)",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "HS - Hotel Suite King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - Treasury",
			"Room": "CS - Casino Suite King (18+)",
			"Adult": "2",
			"Child": "0"
	},
	//Insert new rooms - CRM2-2694
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "CK - City King",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "CT - City Twin",
			"Adult": "4",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "CW - City Accessible",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "RK - River King",
			"Adult": "3",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "RW - River Accessible",
			"Adult": "2",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "CS - City Suite",
			"Adult": "3",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "RS - River Suite",
			"Adult": "3",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "SCS - Skyline City Suite",
			"Adult": "3",
			"Child": "0"
	},
	{
			"Property": "Brisbane",
			"Hotel": "BNE - The Star Grand",
			"Room": "PS - Skyline Penthouse Suite",
			"Adult": "5",
			"Child": "0"
	}
];

export default class CreateHotelRoomTypeModal extends LightningElement {
		@api recordId;
		@api vipBookingId;
		@api vipBookingProperty;
		@api recordTypeId;
		@api dmlResult;
		@api serviceRecord;
		@api serviceRecId = '';
		@api costCentre;
		@api isDMLCreate = false;

		@track diffDays;
		@track arrivalDate;
		@track departureDate;

		selectedHotel;
		serviceOutputId;
		roomPlaceholder = ENTERPAX;
		roomTypeDisabled = true;
		adultPax;
		childPax;
		bookingStatus;
		isInvalid = false;
		statusIsInvalid = false;
		//showError = false;//CRM2-2694
		//errorMsg;//CRM2-2694
		selectedRoomType;
		listOfRooms = [];
		filteredRoomTypes = [];
		confirmationNum = '';
		confirmationNum2 = '';
		
		roomType;

		showOtherMop;
		showOtherSpecialRequest;

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
			this.adultPax = result.Adult_Pax__c;
			this.childPax = result.Children_Pax__c;
			this.selectedHotel = result.Hotel__c;
			this.vipBookingProperty = result.Property__c;
			this.selectedRoomType = result.Room_Type__c;
			this.roomType = result.Room_Type__c;
			if(result.Hotel_Confirmation_Number__c != null){
				this.confirmationNum2 = result.Hotel_Confirmation_Number__c;
			}
			

			this.arrivalDate = new Date(result.Arrival_Date__c);
			this.departureDate = new Date(result.Departure_Date__c);

			this.showOtherMop = result.MOP_Status__c == 'OTHER' ? true : false;

			this.showOtherSpecialRequest = result.Special_Request__c == 'OTHERS' ? true : false;

			if(result.Hotel_Booking_Status__c == 'Confirmed'){
				this.bookingStatusText1 = true;
			}
			else if(result.Hotel_Booking_Status__c == 'New Booking' ||
							result.Hotel_Booking_Status__c == 'Amendment' ||
							result.Hotel_Booking_Status__c == 'Request Cancellation'){
							
								this.bookingStatusText2 = true;
			}
			
			this.handleSearchButton();
		})
		.catch(error=>{
			console.log('@@@Error Apex ', error);
		})
	}

	/*@wire(getRecord, { recordId: '$serviceRecId', fields: ['Service__c.Adult_Pax__c', 'Service__c.Children_Pax__c', 'Service__c.Hotel__c', 'Service__c.Property__c', 'Service__c.Room_Type__c', 'Service__c.Arrival_Date__c','Service__c.Departure_Date__c', 'Service__c.MOP_Status__c', 'Service__c.Special_Request__c'] })
		serviceRecord( { error, data } ){
			if(data){
				this.adultPax = data.fields.Adult_Pax__c.value;
				this.childPax = data.fields.Children_Pax__c.value;
				this.selectedHotel = data.fields.Hotel__c.value;
				this.vipBookingProperty = data.fields.Property__c.value;
				this.selectedRoomType = data.fields.Room_Type__c.value;
				this.roomType = data.fields.Room_Type__c.value;

				this.arrivalDate = new Date(data.fields.Arrival_Date__c.value);
				this.departureDate = new Date(data.fields.Departure_Date__c.value);

				this.showOtherMop = data.fields.MOP_Status__c.value == 'OTHER' ? true : false;

				this.showOtherSpecialRequest = data.fields.Special_Request__c.value == 'OTHERS' ? true : false;
				
				this.handleSearchButton();
			}else if(error){
				console.log('Error: ', error);
			}
		}*/

	handleAdultChange(event){
		this.adultPax = event.target.value;
		this.handleSearchButton();
	}

	handleChildChange(event){
		this.childPax = event.target.value;
		this.handleSearchButton();
	}

	handleHotelChange(event){
		this.selectedHotel = event.target.value;
		this.isInvalid = true;
		this.handleSearchButton();
	}

	handleStatusChange(event){
		this.bookingStatus = event.target.value;
		this.validateStatus();
	}
	
	handleSearchButton(){
		if(this.adultPax >= 0 && this.childPax >= 0 && this.selectedHotel){
			this.roomTypeDisabled = false;
			this.listOfRooms = [];
			this.filteredRoomTypes = roomTypes
					.filter( r =>  this.adultPax <= r.Adult &&  this.childPax <= r.Child && r.Property == this.vipBookingProperty && r.Hotel == this.selectedHotel);

			this.filteredRoomTypes.forEach(room=>{
					let roomVar = { label : room.Room, value : room.Room };
					this.listOfRooms.push(roomVar);
			});

			if(this.listOfRooms.length > 0){
				this.roomPlaceholder = SELECTROOM;
			}else{
				this.roomPlaceholder = NOROOMS;
				this.roomType = null;
				this.selectedRoomType = null;
				this.isInvalid = true;
			}
		}else{
			this.roomTypeDisabled = true;
			this.roomPlaceholder = ENTERPAX;
			this.roomType = null;
			this.selectedRoomType = null;
			this.isInvalid = false;
		}
	}

	handleRoomChange(event){
		this.selectedRoomType = event.target.value;
		if(this.selectedRoomType != NOROOMS || this.selectedRoomType != SELECTROOM){
			this.isInvalid = false;
		}else{
			this.isInvalid = true;
		}
	}

	checkMopField(event){

		this.showOtherMop = false;

		if(event.target.value == 'OTHER'){
				this.showOtherMop = true;
		}
	}

	checkSpecialRequestField(event){

		this.showOtherSpecialRequest = false;

		if(event.target.value == 'OTHERS'){
				this.showOtherSpecialRequest = true;
		}
	}

	arrivalDateChange(event){
		this.arrivalDate = new Date(event.target.value);
		this.handleNumberOfNights();
	}

	departureDateChange(event){
		this.departureDate = new Date(event.target.value);
		this.handleNumberOfNights();
	}

	handleNumberOfNights(){

		if(this.arrivalDate != null && this.departureDate != null){
			this.difference = this.departureDate.getTime() - this.arrivalDate.getTime();
			this.diffDays = Math.ceil(this.difference / (1000 * 3600 * 24));
			if(this.diffDays == 0){
				this.diffDays = 1; //Same Day booking will be considered as 1 Days
			}
			else if(this.diffDays < 0){
				this.diffDays = 0;
			}
		}
	}

	handleConfNumChange(event){
		this.confirmationNum = event.target.value;
		this.validateStatus();
	}

	validateStatus(){ 
		if(this.bookingStatus == 'Confirmed' && !this.confirmationNum && this.confirmationNum2 == ''){
			this.isInvalid = true;
			this.statusIsInvalid = true;
		}else{
			this.isInvalid = false;
			this.statusIsInvalid = false;
		}
	}
	recordSuccess(event){
		this.serviceOutputId = event.detail.id;

		const attributeChangeEvent = new FlowAttributeChangeEvent('dmlResult', this.serviceOutputId);
		this.dispatchEvent(attributeChangeEvent);

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
		
		//CRM2-2724 - Deactivate rule post 28th of August
		//CRM2-2694, prevent arrival date earlier than 2024-08-29
		/*this.showError = false;
		this.errorMsg = '';
		if(fields.Hotel__c && fields.Hotel__c == 'BNE - The Star Grand'){
			let year = 2024;
			let month = 8;
			let day = 29;
			let arrivalDate = fields.Arrival_Date__c.split('-');
			if(arrivalDate[0] < year 
				|| (arrivalDate[0] <= year && arrivalDate[1] < month)
				|| (arrivalDate[0] <= year && arrivalDate[1] <= month && arrivalDate[2] < day)){
				this.showError = true;
				this.errorMsg = 'First physical stay date can\'t be before 29 Aug 2024!';
				return;
			}
		}*/
		//---

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