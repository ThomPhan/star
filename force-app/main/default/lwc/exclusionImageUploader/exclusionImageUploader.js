import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadImages from '@salesforce/apex/ExclusionImageService.uploadImages';
import getUploadValidationRules from '@salesforce/apex/ExclusionImageService.getUploadValidationRules';

/**
 * exclusionImageUploader
 * BULK upload modal. Accepts multiple image files (png/jpg/webp), validates each
 * client-side (format + size), reads them to base64, and calls the Apex bulk method
 * ExclusionImageService.uploadImages ONCE with all valid files — Apex PUTs each object
 * directly to the patron's S3 bucket. Shows per-file results and fires `uploadcomplete`
 * so the parent gallery refreshes. The LWC never calls S3 directly.
 */
export default class ExclusionImageUploader extends LightningElement {
    /** @type {string} The Contact Id (S3 bucket name). */
    @api recordId;

    @track files = [];
    @track isUploading = false;

    supportedFormats = ['png', 'jpg', 'jpeg', 'webp'];
    // Client-side max size guard (25 MB) to avoid oversized base64 payloads to Apex.
    maxSizeBytes = 25 * 1024 * 1024;

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
     * Validates a single file (format + size) and reads it as base64.
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
                descriptor.message = 'File exceeds the 25 MB size limit.';
                resolve(descriptor);
                return;
            }

            const reader = new FileReader();
            reader.onload = () => {
                const dataUrl = reader.result;
                descriptor.base64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
                descriptor.valid = true;
                descriptor.message = 'Ready';
                resolve(descriptor);
            };
            reader.onerror = () => {
                descriptor.message = 'Unable to read file.';
                resolve(descriptor);
            };
            reader.readAsDataURL(file);
        });
    }

    getExtension(fileName) {
        if (!fileName || fileName.indexOf('.') === -1) {
            return '';
        }
        return fileName.split('.').pop().toLowerCase();
    }

    /** Confirm: build the bulk request and upload all valid files in a single Apex call. */
    async handleConfirm() {
        const validFiles = this.files.filter((f) => f.valid);
        if (validFiles.length === 0) {
            this.showToast('No valid files', 'Please add at least one valid image.', 'warning');
            return;
        }

        const requests = validFiles.map((f) => ({
            fileName: f.fileName,
            base64Content: f.base64,
            contentType: f.contentType
        }));

        this.isUploading = true;
        try {
            const results = await uploadImages({ contactId: this.recordId, images: requests });
            const successCount = results.filter((r) => r.success).length;
            const failures = results
                .filter((r) => !r.success)
                .map((r) => `${r.fileName}: ${r.errorMessage}`);

            // Reflect per-file outcomes back into the list.
            this.files = this.files.map((f) => {
                const match = results.find((r) => r.fileName === f.fileName);
                if (match) {
                    return { ...f, message: match.success ? 'Uploaded' : match.errorMessage };
                }
                return f;
            });

            if (successCount > 0) {
                this.showToast('Upload complete', `${successCount} image(s) uploaded successfully.`, 'success');
            }
            if (failures.length > 0) {
                this.showToast('Some uploads failed', failures.join(' | '), 'error');
            }
            this.dispatchEvent(new CustomEvent('uploadcomplete', { detail: { count: successCount } }));
        } catch (error) {
            this.showToast('Upload failed', this.reduceError(error), 'error');
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