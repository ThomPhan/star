import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getImage from '@salesforce/apex/ExclusionImageService.getImage';

/**
 * exclusionImageViewer
 * Full-size image viewer modal. Retrieves the current image's bytes on demand via
 * ExclusionImageService.getImage (Apex → S3) and renders them as a data URL — never
 * calls S3 directly. Supports previous/next navigation, arrow-key nav, Esc to close,
 * zoom, and download of the current image. Accessible per BR29/BR31.
 */
export default class ExclusionImageViewer extends LightningElement {
    /** @type {Array} List of ImageDto objects (objectKey, fileName, ...). */
    @api images = [];

    /** @type {string} Contact Id / S3 bucket name — needed to retrieve objects. */
    @api recordId;

    _currentIndex = 0;

    /** @type {number} Index of the currently displayed image. */
    @api
    get currentIndex() {
        return this._currentIndex;
    }
    set currentIndex(value) {
        this._currentIndex = Number.isInteger(value) ? value : 0;
    }

    @track zoom = 1;
    @track imageUrl;
    @track isLoadingImage = true;
    @track loadError = false;
    _lastLoadedKey;

    renderedCallback() {
        // Move focus to the dialog for keyboard users / screen readers.
        const dialog = this.template.querySelector('.viewer-dialog');
        if (dialog && !this._focused) {
            dialog.focus();
            this._focused = true;
        }
        // Load the current image whenever the displayed object changes.
        const current = this.currentImage;
        if (current && current.objectKey !== this._lastLoadedKey) {
            this._lastLoadedKey = current.objectKey;
            this.loadCurrentImage();
        }
    }

    /** Fetch the current image bytes from S3 (via Apex) and build a data URL. */
    loadCurrentImage() {
        const current = this.currentImage;
        if (!current || !this.recordId) {
            this.isLoadingImage = false;
            this.loadError = true;
            return;
        }
        this.isLoadingImage = true;
        this.loadError = false;
        this.imageUrl = null;
        getImage({ contactId: this.recordId, objectKey: current.objectKey })
            .then((content) => {
                if (content && content.base64Data) {
                    const type = content.contentType || 'image/jpeg';
                    this.imageUrl = `data:${type};base64,${content.base64Data}`;
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

    get currentImage() {
        if (!this.images || this.images.length === 0) {
            return null;
        }
        return this.images[this._currentIndex];
    }

    get showImage() {
        return !this.isLoadingImage && !this.loadError && this.imageUrl;
    }

    get fileName() {
        return this.currentImage ? this.currentImage.fileName : '';
    }

    get altText() {
        return this.currentImage
            ? `Exclusion evidence image ${this.currentImage.fileName}`
            : 'Exclusion evidence image';
    }

    get imageStyle() {
        return `transform: scale(${this.zoom});`;
    }

    get positionLabel() {
        const total = this.images ? this.images.length : 0;
        return `${this._currentIndex + 1} of ${total}`;
    }

    get disablePrevious() {
        return this._currentIndex <= 0;
    }

    get disableNext() {
        return !this.images || this._currentIndex >= this.images.length - 1;
    }

    handlePrevious() {
        if (!this.disablePrevious) {
            this._currentIndex -= 1;
            this.resetZoom();
            this.fireNavigate();
        }
    }

    handleNext() {
        if (!this.disableNext) {
            this._currentIndex += 1;
            this.resetZoom();
            this.fireNavigate();
        }
    }

    handleZoomIn() {
        this.zoom = Math.min(this.zoom + 0.25, 3);
    }

    handleZoomOut() {
        this.zoom = Math.max(this.zoom - 0.25, 0.5);
    }

    resetZoom() {
        this.zoom = 1;
    }

    /** Download the currently displayed image via a data-URL anchor. */
    handleDownload() {
        if (!this.imageUrl) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Not ready',
                    message: 'The image is still loading. Please try again.',
                    variant: 'warning'
                })
            );
            return;
        }
        const anchor = document.createElement('a');
        anchor.href = this.imageUrl;
        anchor.download = this.fileName || 'image';
        anchor.click();
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /** Keyboard navigation: arrows to move, Esc to close. */
    handleKeyDown(event) {
        switch (event.key) {
            case 'ArrowLeft':
                event.preventDefault();
                this.handlePrevious();
                break;
            case 'ArrowRight':
                event.preventDefault();
                this.handleNext();
                break;
            case 'Escape':
                event.preventDefault();
                this.handleClose();
                break;
            default:
                break;
        }
    }

    fireNavigate() {
        this.dispatchEvent(
            new CustomEvent('navigate', { detail: { currentIndex: this._currentIndex } })
        );
    }
}