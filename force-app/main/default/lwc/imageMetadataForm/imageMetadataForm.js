import { LightningElement, api, track } from 'lwc';

/**
 * imageMetadataForm
 * Lightweight, optional metadata capture for uploads. Because there is NO Salesforce
 * persistence, this metadata is purely descriptive and (where applicable) travels with
 * the S3 object. Exposes @api getValues() and @api reportValidity() for the parent
 * uploader and fires `metadatachange`.
 */
export default class ImageMetadataForm extends LightningElement {
    @track values = {
        description: '',
        tags: ''
    };

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.values = { ...this.values, [field]: event.target.value };
        this.dispatchEvent(new CustomEvent('metadatachange', { detail: { ...this.values } }));
    }

    /**
     * Returns the captured metadata values.
     * @returns {object} the current metadata values.
     */
    @api
    getValues() {
        return { ...this.values };
    }

    /**
     * Validates the (optional) fields.
     * @returns {boolean} true when the form is valid.
     */
    @api
    reportValidity() {
        const inputs = [...this.template.querySelectorAll('lightning-input,lightning-textarea')];
        return inputs.reduce((valid, input) => valid && input.reportValidity(), true);
    }
}