import { LightningElement, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class SelectRoomType extends LightningElement {
    @api recordId;
    @api objectApiName;

    @wire(getObjectInfo, { objectApiName: SERVICE_OBJECT })
    objectInfo;

    get recordTypeId() {
        // Returns a map of record type Ids 
        const rtis = this.objectInfo.data.recordTypeInfos;
        console.log('rtis :', rtis);
        //return Object.keys(rtis).find(rti => rtis[rti].name === 'Special Account');
    }
}