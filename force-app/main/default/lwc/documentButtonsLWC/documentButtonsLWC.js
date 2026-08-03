import { LightningElement, api, track } from 'lwc';
import getDocumentUrlMap from '@salesforce/apex/DocumentMappingController.getDocumentUrlMap';
import updateWorkOrderLineItemStatus from '@salesforce/apex/DocumentMappingController.updateWorkOrderLineItemStatus';
import completeWorkOrderLineItems from '@salesforce/apex/DocumentMappingController.completeWorkOrderLineItems';
import validateDuplicateDocument from '@salesforce/apex/DocumentMappingController.validateDuplicateDocument';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DocumentButtonsLWC extends LightningElement {
    @api recordId;
    @api documentsToGenerate;
    @api selectedDocument;
    @api WOState;

    @track documentList = [];
    @track documentUrlMap = {};
    @track isLoading = false;
    @track documentExisting = false;
    @track existingDocuId;
    @track document;

    connectedCallback() {
        console.error('TEST connectedCallback ');
        if (this.documentsToGenerate) {
            this.documentList = this.documentsToGenerate
                .split(';')
                .map(doc => doc.trim())
                .filter(doc => doc.length > 0);
        }

        if (this.documentList.length === 0) {
            // No documents to generate, mark WOLIs as Completed
            completeWorkOrderLineItems({
                caseId: this.recordId,
                WOState: this.WOState
            })
            .catch(error => {
                console.error('Error completing WOLIs:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Failed to complete Work Order Line Items.',
                        variant: 'error'
                    })
                );
            });
        } else {
            this.fetchDocumentUrls();
        }
    }

    fetchDocumentUrls() {
        this.isLoading = true;
        getDocumentUrlMap({
            recordId: this.recordId,
            documentNames: this.documentList,
            WOState: this.WOState
        })
        .then(result => {
            this.documentUrlMap = result;
        })
        .catch(error => {
            console.error('Error fetching document URL map:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Failed to fetch document URLs.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleContinueClick(event) {
        if (this.documentList.length === 0) {
            // Prevent status update if no documents
            return;
        }
        var selectedDoc = this.document;

        getDocumentUrlMap({
            recordId: this.recordId,
            documentNames: this.documentList,
            WOState: this.WOState,
            deleteDocu: this.existingDocuId
        })
        .then(result => {
            this.documentUrlMap = result;

            return updateWorkOrderLineItemStatus({ 
                caseId: this.recordId,
                WOState: this.WOState
            });
        })
        .then(() => {
            const url = this.documentUrlMap?.[selectedDoc];
            if (url?.startsWith('http')) {
                window.open(url, '_blank');
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Document Not Available',
                        message: `No valid URL found for document: ${selectedDoc}`,
                        variant: 'warning'
                    })
                );
            }
        })
        .catch(error => {
            console.error('Error during document generation:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Failed to generate document.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
        
        this.documentExisting = false;
    }
    
    handleNoClick(event) {
        this.documentExisting = false;
    }
    
    handleClick(event) {
        if (this.documentList.length === 0) {
            // Prevent status update if no documents
            return;
        }
        
        const selectedDoc = event.target.dataset.doc;
        this.selectedDocument = selectedDoc;
        this.document = selectedDoc;
        this.isLoading = true;
        
        console.error('TEST selectedDoc:  ' + selectedDoc);

        validateDuplicateDocument({
            caseId: this.recordId,
            WOState: this.WOState,
            documentName: this.selectedDocument
        }).then(result => {
            
        console.error('TEST result:  ' + result);
            this.existingDocuId = result;
            if(this.existingDocuId){
                this.documentExisting = true;
            } else {
                this.documentExisting = false;
                this.handleContinueClick();
            }
            console.error('TEST documentExisting:  ' + this.documentExisting);
        });
    }
}