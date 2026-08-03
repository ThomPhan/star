import { LightningElement, api, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import SERVICE_OBJECT from '@salesforce/schema/Service__c';

import ID_FIELD from '@salesforce/schema/Service__c.Id';
import CARTYPEFIELD from '@salesforce/schema/Service__c.Car_Type__c';
import PAXFIELD from '@salesforce/schema/Service__c.Pax__c';
import PROPERTYFIELD from '@salesforce/schema/Service__c.Property__c';

const carTypes = [
    {
      "Limousine": "Sedan (2 Seater)",
      "SeatCapacity": 2
    },
    {
      "Limousine": "Mini Bus (7 Seater)",
      "SeatCapacity": 7
    },
    {
      "Limousine": "Sprinter (12 Seater)",
      "SeatCapacity": 12
    },
    {
      "Limousine": "Hiace (13 Seater)",
      "SeatCapacity": 13
    },
    {
      "Limousine": "Sprinter (14 Seater)",
      "SeatCapacity": 14
    },
    {
      "Limousine": "Coaster (21 Seater)",
      "SeatCapacity": 21
    },
    {
      "Limousine": "Coach (40 Seater)",
      "SeatCapacity": 40
    },
    {
      "Limousine": "Luxury ***5 DAYS NOTICE***",
      "SeatCapacity": 2
    }
   ];

const propertyLimoOptions = [
{
    "Property": "Sydney",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 9 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Toyota Hiace or similar - 12 seats",
    "Limousine": "Hiace (13 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 14 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 9 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Toyota Hiace or similar - 12 seats",
    "Limousine": "Hiace (13 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 14 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 9 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 9 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Toyota Hiace or similar - 12 seats",
    "Limousine": "Hiace (13 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Toyota Hiace or similar - 12 seats",
    "Limousine": "Hiace (13 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 14 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Mercedes Sprinter or similar - 14 seats",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coaster",
    "Limousine": "Coaster (21 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coaster",
    "Limousine": "Coaster (21 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coaster",
    "Limousine": "Coaster (21 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coaster",
    "Limousine": "Coaster (21 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Sydney",
    "CarType": "BENTLEY CONTINENTAL FLYING SPUR",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "BENTLEY CONTINENTAL FLYING SPUR",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "ROLLS ROYCE PHANTOM DROPHEAD **24hrs Notice**",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "ROLLS ROYCE PHANTOM DROPHEAD **24hrs Notice**",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "ROLLS ROYCE GHOST HARD TOP **24hrs Notice**",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Sydney",
    "CarType": "ROLLS ROYCE GHOST HARD TOP **24hrs Notice**",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Gold Coast",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes Sprinter or similar",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes Sprinter or similar",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Mercedes Sprinter or similar",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Gold Coast",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Sedan",
    "Limousine": "Sedan (2 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes V Class (Viano) or similar",
    "Limousine": "Luxury ***5 DAYS NOTICE***"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes Sprinter or similar",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes Sprinter or similar",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Mercedes Sprinter or similar",
    "Limousine": "Sprinter (14 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
},
{
    "Property": "Brisbane",
    "CarType": "Coach",
    "Limousine": "Coach (40 Seater)"
}
];

const FIELDS = [
    'Service__c.Name',
    'Service__c.Property__c',
];

export default class VehicleType extends LightningElement {
    @api recordId;

    carPax;
    showCars;
    selectedLimo;
    selectedCarType;
    showNA;
    serviceRecord;
    listOfCars = [];
    listOfLimo = [];
    filteredCarTypes = [];
    filteredLimoTypes = [];

    @wire(getRecord, { recordId: '$recordId', fields: [FIELDS] })
    serviceRecord({ error, data }){
        if(data){
            this.serviceRecord = data.data;
            console.log('this.serviceRecord :', this.serviceRecord);
        }else if(error){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    handlePaxChange(event){
        this.carPax = event.target.value;
        if(this.carPax){
            this.listOfLimo = [];
            this.filteredLimoTypes = carTypes
                .filter( r =>  this.carPax <= r.SeatCapacity);

            this.filteredLimoTypes.forEach(limo=>{
                let limoVar = { label : limo.Limousine, value : limo.Limousine };
                this.listOfLimo.push(limoVar);
            });
        }
    }

    handleLimoChange(event){
        this.selectedLimo = event.target.value;
    }
    
    handleSearchButton(){
        if(this.selectedLimo){
            this.listOfCars = [];
            this.filteredCarTypes = propertyLimoOptions
                .filter( r =>  r.Limousine === this.selectedLimo && r.Property == 'Sydney');

            this.filteredCarTypes.forEach(car=>{
                let carVar = { label : car.CarType, value : car.CarType };
                this.listOfCars.push(carVar);
            });

            if(this.listOfCars.length > 0){
                this.showCars = true;
                this.showNA = false;
            }else{
                this.showCars = false;
                this.showNA = true;
            }
        }
    }

    handleCarChange(event){
        this.selectedCarType = event.target.value;
    }

    updateRecord(){
        console.log('this.serviceRecord ', this.serviceRecord);
        const fields = {};
            fields[ID_FIELD.fieldApiName] = this.serviceRecord.Id;
            fields[CARTYPEFIELD.fieldApiName] = this.selectedCarType;
            fields[PAXFIELD.fieldApiName] = this.carPax;

            const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Service updated!',
                        variant: 'success'
                    })
                );
                this.listOfCars = [];
                this.showCars = false;
                this.carPax = '';
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