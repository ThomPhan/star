import { LightningElement, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ID_FIELD from '@salesforce/schema/Service__c.Id';
import ROOMTYPEFIELD from '@salesforce/schema/Service__c.Room_Type__c';
import PROPERTYFIELD from '@salesforce/schema/Service__c.Property__c';

const roomTypes = [
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Superior King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Superior Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Accessible King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Executive King Pyrmont",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Harbour King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Harbour Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Executive King Harbour",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Premium ",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Star Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Harbour Star ",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Deluxe 1 bedroom",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Deluxe 2 bedroom",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Royale",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "Penthouse",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "1 Bedroom Pyrmont",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "1 Bedroom City",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "1 Bedroom Harbour",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "2 Bedroom Pyrmont",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "2 Bedroom City",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "2 Bedroom Harbour",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "2 Bedroom Ent",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "2 Bedroom Loft",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "2 Bedroom Gym",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Star Residences",
    "Room": "3 Bedroom Harbour",
    "Adult": 6,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Darling King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Darling Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Accessible King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Harbour King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Interconnecting",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Jewel",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Jewel City",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Jewel Spa",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Jewel Spa City",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Adored",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Stellar",
    "Adult": 2,
    "Child": 2
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Stellar Harbour",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Adored Deluxe",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Penthouse",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Junior Penthouse",
    "Adult": 4,
    "Child": 1
  },
  {
    "Property": "Sydney",
    "Hotel": "SYD - The Darling",
    "Room": "Penthouse Deluxe",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Superior Deluxe King Room",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Superior Deluxe Twin Room",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Corner Balcony Deluxe King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Corner Balcony Deluxe Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Executive Deluxe  King Room",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Executive Deluxe  Twin Room",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Club Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Club Grande Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Pacific View Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "King Terrace Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "Ocean Terrace Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "North Penthouse Lounge",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "North Penthouse Interconnecting Twin Room",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Star Grand",
    "Room": "North Penthouse Interconnecting King Room",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Stellar Twin Suite",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Stellar Accessible Suite",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Stellar Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Penthouse Suite (2 Bedroom King)",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Penthouse Spa Suite (2 Bedroom King)",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Penthouse Deluxe Suite (Media 2 Bedroom King)",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Penthouse Deluxe Suite (Billiard 2 Bedroom King)",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Gold Coast",
    "Hotel": "GC - The Darling",
    "Room": "Penthouse Deluxe Suite (Exercise 2 Bedroom King)",
    "Adult": 4,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Deluxe King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Casino King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Deluxe Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Casino Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Wheelchair Access Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Wheelchair Access King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Cas W Chair Access Twin",
    "Adult": 3,
    "Child": 1
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Deluxe Double (Not a twin)",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Parlour King",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Casino Parlour",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Hotel Suite",
    "Adult": 2,
    "Child": 0
  },
  {
    "Property": "Brisbane",
    "Hotel": "BNE - Treasury",
    "Room": "Casino Suite",
    "Adult": 2,
    "Child": 0
  }
 ];

export default class HotelRoomType extends LightningElement {
    @api recordId;

    selectedHotel;
    serviceRecord
    serviceProperty;
    hotelrtid;
    adultPax;
    childPax;
    showRooms;
    selectedRoomType;
    showNA;
    listOfRooms = [];
    filteredRoomTypes = [];

    @wire(getRecord, { recordId: '$recordId', fields: ['Service__c.Property__c', 'Service__c.Hotel__c'] })
    serviceRecord( { error, data } ){
      if(data){
        this.serviceProperty = data.fields.Property__c.value;
        this.selectedHotel = data.fields.Hotel__c.value;
      }else if(error){
        console.log('Error: ', error);
      }
    }

    get numberOfAdult() {
        return [
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' },
        ];
    }

    get numberOfChild() {
        return [
            { label: '0', value: '0' },
            { label: '1', value: '1' },
            { label: '2', value: '2' },
        ];
    }

    handleAdultChange(event){
        this.adultPax = event.target.value;
        this.showRooms = false;
    }

    handleChildChange(event){
        this.childPax = event.target.value;
        this.showRooms = false;
    }
    
    handleSearchButton(){
        if(this.adultPax && this.childPax){
            this.listOfRooms = [];
            this.filteredRoomTypes = roomTypes
                .filter( r =>  this.adultPax <= r.Adult &&  this.childPax <= r.Child && r.Property == this.serviceProperty && r.Hotel == this.selectedHotel);

            this.filteredRoomTypes.forEach(room=>{
                let roomVar = { label : room.Room, value : room.Room };
                this.listOfRooms.push(roomVar);
            });

            if(this.listOfRooms.length > 0){
                this.showRooms = true;
                this.showNA = false;
            }else{
                this.showRooms = false;
                this.showNA = true;
            }
        }
    }

    handleRoomChange(event){
        this.selectedRoomType = event.target.value;
    }

    updateRecord(){
        const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[ROOMTYPEFIELD.fieldApiName] = this.selectedRoomType;

            const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Service updated!',
                        variant: 'success'
                    })
                );
                this.listOfRooms = [];
                this.showRooms = false;
                this.adultPax = '';
                this.childPax = ''
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}