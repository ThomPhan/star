import { LightningElement, api } from 'lwc';

export default class ExlWrittenWarningButton extends LightningElement {
    /**
     * Fully resolved FormAssembly workflow URL
     * (exclusionId & contactId already substituted by the flow).
     * @type {string}
     */
    @api documentUrl;

    clicked = false;

    handleGenerate() {
        if (this.documentUrl && this.documentUrl.startsWith('http')) {
            window.open(this.documentUrl, '_blank');
            this.clicked = true;
        }
    }

    /**
     * Flow calls this automatically on Next/Finish.
     * Blocks navigation until the Generate button has been clicked.
     */
    @api
    validate() {
        if (this.clicked) {
            return { isValid: true };
        }
        return {
            isValid: false,
            errorMessage: 'Please click "Generate Written Warning" before finishing.'
        };
    }
}