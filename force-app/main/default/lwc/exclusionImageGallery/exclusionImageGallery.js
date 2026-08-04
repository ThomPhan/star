import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import listImages from '@salesforce/apex/ExclusionImageService.listImages';

/**
 * exclusionImageGallery (PARENT / container, exposed as a Contact record-page tab)
 * Salesforce is a UI + integration layer only — this component owns all state and
 * orchestrates the child components. It NEVER calls Amazon S3 directly; every S3
 * operation is brokered through ExclusionImageService Apex.
 *
 * - @api recordId is the Contact Id, which is also the S3 bucket name (per-patron isolation).
 * - Loads the image list from S3 via Apex listImages (BR13/BR28).
 * - Renders a responsive grid of exclusionImageTile children.
 * - Shows exclusionGalleryEmptyState when the bucket has no images (BR11).
 * - Opens the exclusionImageUploader (bulk upload) and exclusionImageViewer modals.
 * - Handles child events (upload complete, tile selected/enlarged, viewer navigate/close, refresh).
 */
export default class ExclusionImageGallery extends LightningElement {
    /** @type {string} The Contact Id supplied by the record page (S3 bucket name). */
    @api recordId;

    @track images = [];
    @track isLoading = true;
    @track showUploader = false;
    @track showViewer = false;
    @track viewerIndex = 0;
    @track selectedKeys = [];
    @track loadError = '';

    _wiredImages;

    /** Wire the S3 image list so we can refreshApex after a bulk upload. */
    @wire(listImages, { contactId: '$recordId' })
    wiredImages(result) {
        this._wiredImages = result;
        const { data, error } = result;
        if (data) {
            this.images = data;
            this.loadError = '';
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            this.images = [];
            // A load failure is a real error (callout/config/permission), not an empty
            // gallery. Surface it via a toast AND an inline message — never disguise it
            // as a "no access" screen (design §9.1). Access is gated by the permission
            // set + tab visibility, not by parsing error text.
            this.loadError = this.reduceError(error);
            this.showToast('Unable to load images', this.loadError, 'error');
        }
    }

    get hasImages() {
        return this.images && this.images.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.hasImages && !this.loadError;
    }

    get emptyStateMode() {
        // The gallery has no separate "no access" screen — access is gated by the
        // permission set + tab visibility. An empty gallery always means "no images".
        return 'noimages';
    }

    get hasLoadError() {
        return !this.isLoading && !!this.loadError;
    }

    get showUploadButton() {
        return !this.loadError;
    }

    /** Decorate images with their selection state for the tiles. */
    get decoratedImages() {
        return this.images.map((img) => ({
            ...img,
            selected: this.selectedKeys.includes(img.objectKey)
        }));
    }

    handleOpenUploader() {
        this.showUploader = true;
    }

    handleCloseUploader() {
        this.showUploader = false;
    }

    /** Refresh the gallery after a successful bulk upload. */
    handleUploadComplete(event) {
        this.showUploader = false;
        const count = event && event.detail ? event.detail.count : 0;
        if (count > 0) {
            this.isLoading = true;
            refreshApex(this._wiredImages).finally(() => {
                this.isLoading = false;
            });
        }
    }

    /** Empty-state upload CTA. */
    handleEmptyStateUpload() {
        this.handleOpenUploader();
    }

    /** Manual refresh button. */
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this._wiredImages).finally(() => {
            this.isLoading = false;
        });
    }

    /** Open the full-size viewer at the enlarged tile. */
    handleEnlarge(event) {
        const objectKey = event.detail.objectKey;
        const index = this.images.findIndex((img) => img.objectKey === objectKey);
        this.viewerIndex = index > -1 ? index : 0;
        this.showViewer = true;
    }

    handleCloseViewer() {
        this.showViewer = false;
    }

    handleViewerNavigate(event) {
        this.viewerIndex = event.detail.currentIndex;
    }

    /** Track tile selection state. */
    handleSelect(event) {
        const { objectKey, selected } = event.detail;
        if (selected) {
            if (!this.selectedKeys.includes(objectKey)) {
                this.selectedKeys = [...this.selectedKeys, objectKey];
            }
        } else {
            this.selectedKeys = this.selectedKeys.filter((k) => k !== objectKey);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /** Reduce an Apex/JS error into a readable message. */
    reduceError(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return String(error);
    }
}