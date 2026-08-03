import { LightningElement, api } from 'lwc';

/**
 * exclusionGalleryEmptyState
 * Displays the appropriate empty-state message. For "noimages" it offers an upload
 * call-to-action (fires `upload`). For "noaccess" it shows an access message only.
 * Implements BR11 (empty state).
 */
export default class ExclusionGalleryEmptyState extends LightningElement {
    /** @type {string} "noimages" | "noaccess". */
    @api mode = 'noimages';

    /** Whether the current user may upload (controls CTA visibility). */
    @api canUpload = false;

    get isNoImages() {
        return this.mode === 'noimages';
    }

    get isNoAccess() {
        return this.mode === 'noaccess';
    }

    get showUploadCta() {
        return this.isNoImages && this.canUpload;
    }

    get iconName() {
        return this.isNoAccess ? 'utility:lock' : 'utility:image';
    }

    get heading() {
        return this.isNoAccess ? 'No Access' : 'No Images Yet';
    }

    get message() {
        return this.isNoAccess
            ? 'You do not have permission to view exclusion evidence images for this patron.'
            : 'There are no exclusion evidence images for this patron yet.';
    }

    handleUpload() {
        this.dispatchEvent(new CustomEvent('upload'));
    }
}