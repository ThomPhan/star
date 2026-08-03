import { LightningElement, track, api } from 'lwc';
import getAllPublicGroups from '@salesforce/apex/SendApproval.getAllPublicGroups';
import getAllPublicGroupMembers from '@salesforce/apex/SendApproval.getAllGroupMembers';
import submitForApproval from '@salesforce/apex/SendApproval.submitAndProcessApprovalRequest';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ERRORMSG = "Something went wrong. Please contact your Salesforce Administrator.";

export default class approvalProcessLWC extends LightningElement {
    @api recordId;
    @track groupMember;
    @track publicGroupId;
    @track isReady = false;
    @track groupOptions = [];
    @track userOptions = [];
    @track isLoading = false;
    @track confirmSave = true;

    showModal = false;

    connectedCallback(){
        this.getPublicGroups();
    }

    getPublicGroups(){
        getAllPublicGroups()
        .then(result=>{
            let listOfGroup = result;
            listOfGroup.forEach(groups=>{
                this.groupOptions.push({value: groups.Id, label: groups.Name});
            })
            this.isReady = true;
        })
        .catch(error=>{
            this.notifyUser('', ERRORMSG, 'error', 'dismissible');
        });
    }

    handleGroupChange(event) {
        // Get the string of the "value" attribute on the selected option
        this.publicGroupId = event.detail.value;
        this.userOptions = null;
        this.populateGroupMembers();
    }

    populateGroupMembers(){
        this.getGroupMembers();
    }

    getGroupMembers(){
        getAllPublicGroupMembers( { groupId : this.publicGroupId })
        .then(result=>{
            this.userOptions = [];
            let listOfMembers = result;
            listOfMembers.forEach(user=>{
                this.userOptions.push({value : user.Id , label : user.Name})
            })
        })
        .catch(error=>{
            this.notifyUser('', ERRORMSG, 'error', 'dismissible');
        });
    }

    handleChange(event){
        this.groupMember = event.detail.value;
    }

    handleConfirmChange(event){
        this.confirmSave = !(event.target.checked);
        console.log('event.target.checked :', event.target.checked);
    }

    saveClick(){
        submitForApproval({ checklistId : this.recordId , approverId : this.groupMember})
        .then(result=>{
            this.notifyUser('', 'Sent to Next Approver!', 'success', 'dismissible');
            this.closeModal();
        })
        .catch(error=>{
            let errMsg = JSON.parse(JSON.stringify(error));
            console.log('errMsg :', errMsg);
            this.notifyUser('', ERRORMSG, 'error', 'dismissible');
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