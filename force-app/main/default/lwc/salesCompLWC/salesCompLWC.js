import { LightningElement, api, wire } from 'lwc';
import getLoyaltyRecord from '@salesforce/apex/SalesCompController.getLoyaltyRecord';
import getSalesCompsTotal from '@salesforce/apex/SalesCompController.getSalesCompsTotal';

import CASINO_BALANCE from '@salesforce/schema/Loyalty__c.CasinoBalance__c';
import COMP_BALANCE from '@salesforce/schema/Loyalty__c.CompBalance__c';

export default class SalesCompLWC extends LightningElement {
    @api recordId;

    loyaltyRecord = {};
    @wire(getLoyaltyRecord, { contactId : '$recordId' })
    wiredLoyaltyRecord(loyaltyProp) {
        const { data, error } = loyaltyProp;
        if (data) {
            this.loyaltyRecord = data;
        }
    }

    get casinoBalance() {
        return (this.loyaltyRecord[CASINO_BALANCE.fieldApiName]) ? this.loyaltyRecord[CASINO_BALANCE.fieldApiName].toFixed(2) : 0;
    }

    get compBalance() {
        return (this.loyaltyRecord[COMP_BALANCE.fieldApiName]) ? this.loyaltyRecord[COMP_BALANCE.fieldApiName].toFixed(2) : 0;
    }

    contactWrapper = {};
    @wire(getSalesCompsTotal, { contactId : '$recordId' })
    wiredContactWrapper(wrapperProp) {
        const { data, error } = wrapperProp;
        if (data) {
            this.contactWrapper = data;
        }
    }

    get cdCPtotal() {
        return (this.contactWrapper['cdCPtotal']) ? Number((this.contactWrapper['cdCPtotal']).toFixed(2)) : 0;
    }

    get spvMPVtotal() {
        return (this.contactWrapper['spvMPVtotal']) ? Number((this.contactWrapper['spvMPVtotal']).toFixed(2)) : 0;
    }

    get giftTotal() {
        return (this.contactWrapper['giftTotal']) ? Number((this.contactWrapper['giftTotal']).toFixed(2)) : 0;
    }

    get totalSalesComp() {
        return (this.cdCPtotal + this.spvMPVtotal + this.giftTotal).toFixed(2);
    }
}