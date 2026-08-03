import { LightningElement, api, track } from 'lwc';
import getImage from '@salesforce/apex/ExclusionImageService.getImage';

/**
 * exclusionImageTile
 * Presentational tile for a single S3 image object. Lazily fetches the image bytes
 * via ExclusionImageService.getImage (Apex → S3) and renders them as a data URL — the
 * component never calls S3 directly. Emits `enlarge` (click/keyboard) and `select`
 * (checkbox) events to the parent gallery.
 */
export default class ExclusionImageTile extends LightningElement {
    /** @type {object} The ImageDto for this tile (objectKey, fileName, size, ...). */
    @api image;

    /** @type {string} Contact Id / S3 bucket name — needed to retrieve the object. */
    @api recordId;

    /** @type {boolean} Whether this tile is currently selected. */
    @api selected = false;

    @track thumbnailUrl;
    @track isLoadingImage = true;
    @track loadError = false;

    connectedCallback() {
        this.loadThumbnail();
    }

    /** Retrieve the image bytes from S3 (via Apex) and build a data URL. */
    loadThumbnail() {
        if (!this.image || !this.recordId) {
            this.isLoadingImage = false;
            this.loadError = true;
            return;
        }
        getImage({ contactId: this.recordId, objectKey: this.image.objectKey })
            .then((content) => {
                if (content && content.base64Data) {
                    const type = content.contentType || 'image/jpeg';
                    this.thumbnailUrl = `data:${type};base64,${content.base64Data}`;
                } else {
                    this.loadError = true;
                }
                this.isLoadingImage = false;
            })
            .catch(() => {
                this.loadError = true;
                this.isLoadingImage = false;
            });
    }

    get fileName() {
        return this.image ? this.image.fileName : '';
    }

    get altText() {
        return this.image ? `Exclusion evidence image ${this.image.fileName}` : 'Exclusion evidence image';
    }

    get showImage() {
        return !this.isLoadingImage && !this.loadError && this.thumbnailUrl;
    }

    /** CSS class for the tile container, reflecting selection state. */
    get tileCssClass() {
        return this.selected
            ? 'tile-container slds-box slds-box_x-small tile-selected'
            : 'tile-container slds-box slds-box_x-small';
    }

    /** Handle the enlarge action (click / Enter / Space). */
    handleEnlarge() {
        this.dispatchEvent(
            new CustomEvent('enlarge', {
                detail: { objectKey: this.image ? this.image.objectKey : null }
            })
        );
    }

    /** Keyboard support: Enter or Space enlarges the tile. */
    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleEnlarge();
        }
    }

    /** Handle the selection checkbox change. */
    handleSelect(event) {
        event.stopPropagation();
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: {
                    objectKey: this.image ? this.image.objectKey : null,
                    selected: event.target.checked
                }
            })
        );
    }

    /** Stop checkbox clicks from bubbling to the enlarge handler. */
    stopPropagation(event) {
        event.stopPropagation();
    }
}