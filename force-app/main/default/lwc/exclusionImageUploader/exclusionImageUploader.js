import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadImage from '@salesforce/apex/ExclusionImageService.uploadImage';
import getUploadValidationRules from '@salesforce/apex/ExclusionImageService.getUploadValidationRules';

/**
 * exclusionImageUploader
 * Upload modal. Accepts multiple image files (png/jpg/webp), validates each client-side
 * (format + size + a soft sub-720p warning), reads them to base64, then uploads them
 * ONE FILE PER Apex call (ExclusionImageService.uploadImage) in a loop. One transaction
 * per file keeps each upload within its own heap budget (design §8) and gives natural
 * partial success. Apex PUTs each object directly to the patron's S3 prefix; the LWC
 * never calls S3 directly. Fires `uploadcomplete` so the parent gallery refreshes.
 */
export default class ExclusionImageUploader extends LightningElement {
    /** @type {string} The Contact Id whose Patron_ID__c drives the S3 key prefix. */
    @api recordId;

    @track files = [];
    @track isUploading = false;

    supportedFormats = ['png', 'jpg', 'jpeg', 'webp'];
    // Client-side max size guard. Apex runs a 6 MB synchronous heap limit and base64
    // inflates the payload ~33%, so cap uploads at 4 MB (design §13) to stay heap-safe.
    maxSizeBytes = 4 * 1024 * 1024;
    // Minimum recommended image height (BR10). Below this we WARN but still allow upload.
    minRecommendedHeight = 720;

    connectedCallback() {
        // Load server-side validation rules so client and server stay in sync.
        getUploadValidationRules()
            .then((rules) => {
                if (rules && Array.isArray(rules.supportedFormats)) {
                    this.supportedFormats = rules.supportedFormats.map((f) => f.toLowerCase());
                }
            })
            .catch(() => {
                // Fall back to defaults on error.
            });
    }

    get hasFiles() {
        return this.files.length > 0;
    }

    get hasValidFiles() {
        return this.files.some((f) => f.valid);
    }

    get confirmDisabled() {
        return this.isUploading || !this.hasValidFiles;
    }

    /** Read selected files, validate each, and build the pass/fail list. */
    async handleFileChange(event) {
        const selected = Array.from(event.target.files || []);
        const processed = [];
        for (let i = 0; i < selected.length; i++) {
            /* eslint-disable no-await-in-loop */
            const result = await this.validateAndReadFile(selected[i], i);
            processed.push(result);
        }
        this.files = processed;
    }

    /**
     * Validates a single file (format + size), reads it as base64, and adds a soft,
     * non-blocking warning when the image is below the recommended 720p height (BR10).
     * @returns {Promise<object>} per-file descriptor with valid flag and message.
     */
    validateAndReadFile(file, index) {
        return new Promise((resolve) => {
            const extension = this.getExtension(file.name);
            const descriptor = {
                key: `${index}-${file.name}`,
                fileName: file.name,
                contentType: file.type,
                valid: false,
                message: '',
                base64: null
            };

            if (!this.supportedFormats.includes(extension)) {
                descriptor.message = `Unsupported format (.${extension}). Allowed: png, jpg, webp.`;
                resolve(descriptor);
                return;
            }
            if (file.size > this.maxSizeBytes) {
                descriptor.message = 'File exceeds the 4 MB size limit.';
                resolve(descriptor);
                return;
            }

            const reader = new FileReader();
            reader.onload = () => {
                const dataUrl = reader.result;
                descriptor.base64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
                descriptor.valid = true;
                descriptor.message = 'Ready';
                // Soft resolution check: inspect natural height, warn but keep valid.
                this.checkResolution(dataUrl)
                    .then((height) => {
                        if (height && height < this.minRecommendedHeight) {
                            descriptor.message = `Ready (warning: below 720p — ${height}px tall)`;
                            // Re-assign to trigger reactivity on the tracked array.
                            this.files = this.files.map((f) =>
                                f.key === descriptor.key ? { ...descriptor } : f
                            );
                        }
                        resolve(descriptor);
                    })
                    .catch(() => resolve(descriptor));
            };
            reader.onerror = () => {
                descriptor.message = 'Unable to read file.';
                resolve(descriptor);
            };
            reader.readAsDataURL(file);
        });
    }

    /**
     * Loads a data URL into an Image to read its natural height.
     * @returns {Promise<number>} the natural height in px (0 if it cannot be determined).
     */
    checkResolution(dataUrl) {
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => resolve(img.naturalHeight || 0);
            img.onerror = () => resolve(0);
            img.src = dataUrl;
        });
    }

    getExtension(fileName) {
        if (!fileName || fileName.indexOf('.') === -1) {
            return '';
        }
        return fileName.split('.').pop().toLowerCase();
    }

    /** Confirm: upload each valid file in its own Apex call (one transaction per file). */
    async handleConfirm() {
        const validFiles = this.files.filter((f) => f.valid);
        if (validFiles.length === 0) {
            this.showToast('No valid files', 'Please add at least one valid image.', 'warning');
            return;
        }

        this.isUploading = true;
        let successCount = 0;
        const failures = [];
        const outcomes = {};

        try {
            for (let i = 0; i < validFiles.length; i++) {
                const f = validFiles[i];
                /* eslint-disable no-await-in-loop */
                try {
                    const result = await uploadImage({
                        contactId: this.recordId,
                        image: {
                            fileName: f.fileName,
                            base64Content: f.base64,
                            contentType: f.contentType
                        }
                    });
                    if (result && result.success) {
                        successCount++;
                        outcomes[f.key] = 'Uploaded';
                    } else {
                        const msg = (result && result.errorMessage) || 'Upload failed';
                        failures.push(`${f.fileName}: ${msg}`);
                        outcomes[f.key] = msg;
                    }
                } catch (error) {
                    const msg = this.reduceError(error);
                    failures.push(`${f.fileName}: ${msg}`);
                    outcomes[f.key] = msg;
                }
            }

            // Reflect per-file outcomes back into the list.
            this.files = this.files.map((f) =>
                outcomes[f.key] ? { ...f, message: outcomes[f.key] } : f
            );

            if (successCount > 0) {
                this.showToast('Upload complete', `${successCount} image(s) uploaded successfully.`, 'success');
            }
            if (failures.length > 0) {
                this.showToast('Some uploads failed', failures.join(' | '), 'error');
            }
            this.dispatchEvent(new CustomEvent('uploadcomplete', { detail: { count: successCount } }));
        } finally {
            this.isUploading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
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
