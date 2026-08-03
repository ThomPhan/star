import { LightningElement, api } from 'lwc';
import getPatronImage from '@salesforce/apex/PatronImageController.getPatronImage';

export default class ContactProfilePic extends LightningElement {
    @api recordId;

    imageData;          // real image data URI (from API)
    contactName;        // Contact full name (card title)
    showImage = false;  // popup open
    isLoading = true;

    connectedCallback() {
        // imageType omitted -> controller uses the configured default (Patron_Image_Config.Image_Type__c)
        getPatronImage({ contactId: this.recordId })
            .then((result) => {
                if (result) {
                    this.contactName = result.name;
                    if (result.imageBase64) {
                        this.imageData = 'data:image/jpeg;base64,' + result.imageBase64;
                    }
                }
            })
            .catch(() => {
                // leave as "No Image Available"
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get cardTitle() {
        return this.contactName || 'Contact';
    }

    get hasImage() {
        return !!this.imageData;
    }

    get imageUrl() {
        return this.imageData;
    }

    handleView() {
        this.showImage = true;
    }

    handleHide() {
        this.showImage = false;
    }
}