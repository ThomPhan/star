import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import submitForApproval from '@salesforce/apex/SendApproval.submitAndProcessApprovalRequest';
import getApprovers from '@salesforce/apex/SalesCompTriggerHandler.getAllUsers';
import approvers500 from '@salesforce/label/c.Sales_Comp_Approvers_500';
import approvers1000 from '@salesforce/label/c.Sales_Comp_Approvers_1000';
import approvers2000 from '@salesforce/label/c.Sales_Comp_Approvers_2000';
import approvers5000 from '@salesforce/label/c.Sales_Comp_Approvers_5000';
import approvers75000 from '@salesforce/label/c.Sales_Comp_Approvers_75000';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ERRORMSG = "Something went wrong. Please contact your Salesforce Administrator.";
const FIELDS = [
    'Sales_Comp__c.Name',
    'Sales_Comp__c.Amount__c'
];

export default class SalesCompApprovalProcess extends LightningElement {
    @api recordId;
    @api approvalProcessName;

    label={
      approvers500,
      approvers1000,
      approvers2000,
      approvers5000,
      approvers75000  
    };

    isReady = false;
    isLoading = false;
    confirmSave = true;
    showModal = false;
    hasUsers = true;
    isApproverRole = true;

    salesCompRecord;
    selectedApprover;
    salesCompName;
    salesCompAmount;
    selectedRole;
    approverUsername;

    listOfRoles = [];
    listOfUsers = [];
    listOfApproversRole = [];
    listOfApprovers = [];
    
    approverPlaceholder = 'Select Role: ';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.salesCompName = data.fields.Name.value;
            this.salesCompAmount = data.fields.Amount__c.value;
            console.log('this.salesCompAmount :', this.salesCompAmount);
            this.sortRoles();

        } else if (error) {
            console.log('error ', JSON.parse(JSON.stringify(error)));
        }
    }

    sortRoles(){
        if(this.salesCompAmount < 501){
            let approver500String = this.label.approvers500;
            let approver1000String = approver500String + ',' + this.label.approvers1000;
            let approver2000String = approver1000String + ',' + this.label.approvers2000;
            let approver5000String = approver2000String + ',' + this.label.approvers5000;
            let approver75000String = approver5000String + ',' + this.label.approvers75000;
            this.listOfRoles = approver75000String.split(',');
        }else if(this.salesCompAmount<1001){
            let approver1000String = this.label.approvers1000;
            let approver2000String = approver1000String + ',' + this.label.approvers2000;
            let approver5000String = approver2000String + ',' + this.label.approvers5000;
            let approver75000String = approver5000String + ',' + this.label.approvers75000;
            this.listOfRoles = approver75000String.split(',');
        }else if(this.salesCompAmount<2001){
            let approver2000String = this.label.approvers2000;
            let approver5000String = approver2000String + ',' + this.label.approvers5000;
            let approver75000String = approver5000String + ',' + this.label.approvers75000;
            this.listOfRoles = approver75000String.split(',');
        }else if(this.salesCompAmount<5001){
            let approver5000String = this.label.approvers5000;
            let approver75000String = approver5000String + ',' + this.label.approvers75000;
            this.listOfRoles = approver75000String.split(',');
        }else if(this.salesCompAmount<50001){
            console.log('let approver75000String :');
            let approver75000String = this.label.approvers75000;
            this.listOfRoles = approver75000String.split(',');
        }else{
            console.log('ELSE :');
            this.listOfRoles = [];
        }
        
        for(let i = 0; i<this.listOfRoles.length; i++){
            let approver = {label : this.listOfRoles[i], value : this.listOfRoles[i] };
            this.listOfApproversRole.push(approver);
        }

        this.isReady = true;
    }

    handleRoleChange(event){
        this.selectedRole = event.detail.value;
        if(this.selectedRole.includes('Paul')){
            this.isApproverRole = false;
        }else{
            this.isApproverRole = true;
        }

        this.getListOfApprovers();
    }

    handleApproverChange(event){
        this.selectedApprover = event.target.value;
        if(this.selectedApprover){
            this.confirmSave = false;
        }
    }

    getListOfApprovers(){
        getApprovers({ roleName : this.selectedRole, isRole : this.isApproverRole })
        .then(result=>{
            this.confirmSave = true; //disable submit button
            if(this.isApproverRole){
                this.listOfUsers = [];
                this.listOfApprovers = [];
                this.selectedApprover = null;
                this.listOfUsers = result;
                this.listOfUsers.forEach(user=>{
                    let userRec = { label : user.Name, value : user.Id };
                    this.listOfApprovers.push(userRec);
                });
                if(this.listOfApprovers.length>0){
                    this.approverPlaceholder = 'Select Approver:';
                }else{
                    this.approverPlaceholder = 'No Approvers available';
                }
            }else{
                let userRecord = result;
                if(userRecord.length > 0){
                    this.selectedApprover = userRecord[0].Id;
                    if(this.selectedApprover){
                        this.confirmSave = false;
                    }
                }
            }
        })
        .catch(error=>{
            let errMsg = JSON.parse(JSON.stringify(error));
            console.log('errMsg :', errMsg);
            this.notifyUser('', ERRORMSG, 'error', 'dismissible');
        })
    }

    saveClick(){
        this.confirmSave = true; //disable save once clicked
        submitForApproval({ checklistId : this.recordId , approverId : this.selectedApprover, approvalProcessName : this.approvalProcessName})
        .then(result=>{
            this.notifyUser('', 'Sent to Next Approver!', 'success', 'dismissible');
            this.closeModal();
        })
        .catch(error=>{
            let errMsg = JSON.parse(JSON.stringify(error));
            console.log('errMsg :', errMsg);
            this.notifyUser('Title', ERRORMSG, 'error', 'dismissible');
        })
    }

    notifyUser(title, message, variant, mode) {
		const toastEvent = new ShowToastEvent({ title, message, variant, mode });
		this.dispatchEvent(toastEvent);
    }

    closeModal() {
		const closeNewModal = new CustomEvent('close');
		this.dispatchEvent(closeNewModal);
	}
}