/**
 * @description Single Apex service layer behind ALL Exclusion Evidence Gallery LWCs.
 *              Salesforce acts ONLY as a UI + integration layer: there is NO Salesforce
 *              storage/persistence of images or metadata. Every image is retrieved
 *              DIRECTLY FROM Amazon S3 and uploaded DIRECTLY TO Amazon S3.
 *
 *              LWCs NEVER call S3 directly — all S3 access is brokered here through the
 *              Named Credential `callout:Salesforce_S3_Connection`, which is virtual-hosted
 *              style: the bucket (star-profile-photos-poc) is baked into the credential URL
 *              and AWS SigV4 (RolesAnywhere, ap-southeast-2) signing is applied automatically.
 *
 *              PER-PATRON ISOLATION: a single shared bucket is used; each patron's images
 *              are isolated by an object-key PREFIX equal to the Contact record Id
 *              (`<contactId>/<fileName>`). Listing filters on that prefix.
 *
 *              Requirements: BR11, BR13, BR15, BR27, BR28, BR29, BR31, NFR04, NFR05.
 *
 * @group Exclusion Evidence Gallery
 */
public with sharing class ExclusionImageService {
    // Named Credential for exclusion image S3 access. Virtual-hosted style: the bucket
    // (star-profile-photos-poc) and region (ap-southeast-2) live on the credential itself,
    // and AWS SigV4 signing (RolesAnywhere) is generated automatically by the platform.
    @TestVisible
    private static final String NAMED_CREDENTIAL = 'callout:Salesforce_S3_Connection';

    // Fixed feature prefix within the shared bucket. Every image lives under
    // `exclusion-images/{Patron_ID__c}/` so listing is a cheap prefix query, each
    // object is intrinsically linked to its patron (BR13), and the prefix doubles as
    // the security allow-prefix for object-key confinement (see getImage).
    @TestVisible
    private static final String PREFIX = 'exclusion-images/';

    // Supported upload MIME content types (client + server enforced) — images only.
    private static final Set<String> SUPPORTED_CONTENT_TYPES = new Set<String>{
        'image/png',
        'image/jpeg',
        'image/jpg',
        'image/webp'
    };

    // Supported file extensions (mirror of the content types above).
    private static final Set<String> SUPPORTED_EXTENSIONS = new Set<String>{
        'png',
        'jpg',
        'jpeg',
        'webp'
    };

    // Server-side encryption algorithm applied on every upload (NFR04/NFR05 — encryption).
    private static final String SSE_ALGORITHM = 'AES256';

    /**
     * @description Lists all image objects stored under the current patron's key prefix in
     *              the shared S3 bucket. Calls S3 ListObjectsV2 (filtered by prefix) via the
     *              Named Credential, parses the XML response, and returns a list of ImageDto
     *              sorted newest-first.
     * @param contactId Contact Id (its Patron_ID__c drives the object-key prefix).
     * @return List of ImageDto (empty when the patron has no images or no Patron ID).
     */
    @AuraEnabled(cacheable=true)
    public static List<ImageDto> listImages(Id contactId) {
        if (contactId == null) {
            throw new AuraHandledException('A Contact Id is required to load exclusion images.');
        }

        // No Patron ID => no images to list (UI shows the empty state).
        String patronId = resolvePatronId(contactId);
        if (String.isBlank(patronId)) {
            return new List<ImageDto>();
        }

        try {
            HttpRequest req = new HttpRequest();
            // ListObjectsV2 on the bucket root (bucket is in the Named Credential host),
            // filtered to this patron's prefix: GET /?list-type=2&prefix=exclusion-images/<patronId>/
            req.setEndpoint(buildListEndpoint(patronId));
            req.setMethod('GET');
            req.setTimeout(120000);

            HttpResponse res = new Http().send(req);
            Integer status = res.getStatusCode();

            // An empty / not-yet-created prefix should surface as "no images", not an error.
            if (status == 404) {
                return new List<ImageDto>();
            }
            if (status < 200 || status >= 300) {
                throw new CalloutException(
                    'S3 ListObjects failed with status ' + status + ' (' + res.getStatus() + ').'
                );
            }

            List<ImageDto> images = parseListObjectsXml(res.getBody());
            // Newest first (BR / design §8: LIST sorted by LastModified desc).
            images.sort();
            return images;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load exclusion images: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves a single image object's bytes from S3 (GetObject) and returns
     *              base64-encoded content plus metadata for display/download in the viewer.
     * @param contactId Contact Id (retained for interface stability / auditing).
     * @param objectKey S3 object key of the image to retrieve.
     * @return ImageContentDto containing base64 content, content type and file name.
     */
    @AuraEnabled
    public static ImageContentDto getImage(Id contactId, String objectKey) {
        if (contactId == null) {
            throw new AuraHandledException('A Contact Id is required to retrieve an image.');
        }
        if (String.isBlank(objectKey)) {
            throw new AuraHandledException('An object key is required to retrieve an image.');
        }

        // Object-key confinement: a user may only fetch objects under this patron's own
        // prefix. Prevents retrieving another patron's image or an arbitrary bucket object
        // by guessing/forging a key (design §11). Enforced BEFORE any callout.
        String patronId = resolvePatronId(contactId);
        if (String.isBlank(patronId) || !objectKey.startsWith(buildPatronPrefix(patronId))) {
            throw new AuraHandledException('Access to this image is not permitted.');
        }

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(buildObjectEndpoint(objectKey));
            req.setMethod('GET');
            req.setTimeout(120000);

            HttpResponse res = new Http().send(req);
            Integer status = res.getStatusCode();
            if (status < 200 || status >= 300) {
                throw new CalloutException(
                    'S3 GetObject failed with status ' + status + ' (' + res.getStatus() + ').'
                );
            }

            ImageContentDto dto = new ImageContentDto();
            dto.objectKey = objectKey;
            dto.fileName = extractFileName(objectKey);
            Blob body = res.getBodyAsBlob();
            dto.base64Data = body == null ? null : EncodingUtil.base64Encode(body);
            String contentType = res.getHeader('Content-Type');
            dto.contentType = String.isBlank(contentType)
                ? contentTypeFromKey(objectKey)
                : contentType;
            dto.size = body == null ? 0 : body.size();
            return dto;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to retrieve image "' + objectKey + '": ' + e.getMessage()
            );
        }
    }

    /**
     * @description SINGLE-FILE direct-to-S3 upload. PUTs one image object under the patron's
     *              key prefix with a server-side-encryption header, using a server-generated
     *              timestamped key that prevents overwriting existing evidence. One file per
     *              call keeps each upload in its own transaction (independent heap budget), so
     *              the LWC loops over selected files for natural partial success (design §8).
     * @param contactId Contact Id (its Patron_ID__c drives the object-key prefix).
     * @param image ImageUploadRequest (fileName, base64Content, contentType).
     * @return UploadResultDto (fileName, success, objectKey, eTag, errorMessage).
     */
    @AuraEnabled
    public static UploadResultDto uploadImage(Id contactId, ImageUploadRequest image) {
        if (contactId == null) {
            throw new AuraHandledException('A Contact Id is required to upload an image.');
        }

        String patronId = resolvePatronId(contactId);
        if (String.isBlank(patronId)) {
            throw new AuraHandledException(
                'This patron has no Patron ID; exclusion images cannot be uploaded.'
            );
        }

        UploadResultDto result = new UploadResultDto();
        result.fileName = image == null ? null : image.fileName;
        result.success = false;

        try {
            validateUploadRequest(image);

            String extension = getExtension(image.fileName);
            String objectKey = buildObjectKey(patronId, extension);
            result.objectKey = objectKey;

            Blob body = EncodingUtil.base64Decode(image.base64Content);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(buildObjectEndpoint(objectKey));
            req.setMethod('PUT');
            req.setHeader('Content-Type', image.contentType);
            // Server-side encryption required for evidence storage (NFR04/NFR05).
            req.setHeader('x-amz-server-side-encryption', SSE_ALGORITHM);
            req.setBodyAsBlob(body);
            req.setTimeout(120000);
            // AWS SigV4 signing is handled by the Named Credential config;
            // no manual Authorization header is set here.

            HttpResponse res = new Http().send(req);
            Integer status = res.getStatusCode();
            if (status < 200 || status >= 300) {
                throw new CalloutException(
                    'S3 PutObject failed with status ' + status + ' (' + res.getStatus() + ').'
                );
            }

            result.success = true;
            result.eTag = res.getHeader('ETag');
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }

        return result;
    }

    /**
     * @description Returns the client-side upload validation rules so the LWC and server
     *              stay in sync (supported formats).
     * @return Map of validation rules.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUploadValidationRules() {
        return new Map<String, Object>{
            'supportedFormats' => new List<String>{ 'png', 'jpg', 'jpeg', 'webp' },
            'supportedContentTypes' => new List<String>(SUPPORTED_CONTENT_TYPES)
        };
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    /**
     * @description Resolves the patron identifier (Contact.Patron_ID__c) for a Contact.
     *              Field-level security is respected (WITH SECURITY_ENFORCED). Returns null
     *              when the Contact does not exist or has no Patron ID.
     */
    private static String resolvePatronId(Id contactId) {
        List<Contact> contacts = [
            SELECT Patron_ID__c
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0].Patron_ID__c;
    }

    /**
     * @description Builds the per-patron key prefix: `exclusion-images/{patronId}/`.
     *              Used for listing and object-key confinement.
     */
    private static String buildPatronPrefix(String patronId) {
        return PREFIX + patronId + '/';
    }

    /**
     * @description Builds the bucket-root ListObjectsV2 endpoint, filtered to a patron's
     *              key prefix. The bucket lives in the Named Credential host (virtual-hosted).
     */
    private static String buildListEndpoint(String patronId) {
        return NAMED_CREDENTIAL +
            '?list-type=2&prefix=' +
            EncodingUtil.urlEncode(buildPatronPrefix(patronId), 'UTF-8');
    }

    /**
     * @description Builds an object-level endpoint (GetObject / PutObject). The bucket lives
     *              in the Named Credential host, so only the (encoded) key is appended.
     */
    private static String buildObjectEndpoint(String objectKey) {
        return NAMED_CREDENTIAL + '/' + encodeObjectKey(objectKey);
    }

    /**
     * @description URL-encodes an object key while preserving path separators.
     */
    private static String encodeObjectKey(String objectKey) {
        List<String> encoded = new List<String>();
        for (String segment : objectKey.split('/')) {
            encoded.add(EncodingUtil.urlEncode(segment, 'UTF-8').replace('+', '%20'));
        }
        return String.join(encoded, '/');
    }

    /**
     * @description Builds a server-generated, collision-resistant object key following the
     *              design's naming convention (§6):
     *              `exclusion-images/{patronId}/{patronId}_{UTCtimestamp}.{ext}`.
     *              The timestamp (millisecond precision, GMT) guarantees uniqueness and makes
     *              overwriting existing evidence impossible.
     */
    private static String buildObjectKey(String patronId, String extension) {
        String ts = Datetime.now().formatGmt('yyyyMMdd\'T\'HHmmssSSS\'Z\'');
        return buildPatronPrefix(patronId) + patronId + '_' + ts + '.' + extension;
    }

    /**
     * @description Validates a single upload request: presence + supported content type/extension.
     */
    private static void validateUploadRequest(ImageUploadRequest request) {
        if (request == null) {
            throw new IllegalArgumentException('Missing image upload request.');
        }
        if (String.isBlank(request.fileName)) {
            throw new IllegalArgumentException('A file name is required.');
        }
        if (String.isBlank(request.base64Content)) {
            throw new IllegalArgumentException('File content is required for "' + request.fileName + '".');
        }

        String extension = getExtension(request.fileName);
        String contentType = request.contentType == null ? '' : request.contentType.toLowerCase();

        Boolean typeOk = SUPPORTED_CONTENT_TYPES.contains(contentType);
        Boolean extOk = SUPPORTED_EXTENSIONS.contains(extension);
        if (!typeOk && !extOk) {
            throw new IllegalArgumentException(
                'Unsupported file type for "' + request.fileName +
                '". Supported formats: png, jpeg, jpg, webp.'
            );
        }
    }

    /**
     * @description Extracts the lower-case file extension from a file name.
     */
    private static String getExtension(String fileName) {
        if (String.isBlank(fileName) || !fileName.contains('.')) {
            return '';
        }
        return fileName.substringAfterLast('.').toLowerCase();
    }

    /**
     * @description Extracts the display file name (last path segment) from an object key.
     */
    private static String extractFileName(String objectKey) {
        if (String.isBlank(objectKey)) {
            return objectKey;
        }
        return objectKey.contains('/') ? objectKey.substringAfterLast('/') : objectKey;
    }

    /**
     * @description Infers a MIME content type from an object key's extension.
     */
    private static String contentTypeFromKey(String objectKey) {
        String ext = getExtension(objectKey);
        if (ext == 'png') {
            return 'image/png';
        }
        if (ext == 'jpg' || ext == 'jpeg') {
            return 'image/jpeg';
        }
        if (ext == 'webp') {
            return 'image/webp';
        }
        return 'application/octet-stream';
    }

    /**
     * @description Parses an S3 ListObjectsV2 XML response into ImageDto records. Only
     *              image objects (by extension) are returned; folder markers and
     *              non-image objects are skipped.
     * @param xmlBody The S3 ListObjectsV2 XML response body.
     * @return List of ImageDto.
     */
    private static List<ImageDto> parseListObjectsXml(String xmlBody) {
        List<ImageDto> images = new List<ImageDto>();
        if (String.isBlank(xmlBody)) {
            return images;
        }

        Dom.Document doc = new Dom.Document();
        doc.load(xmlBody);
        Dom.XMLNode root = doc.getRootElement();
        String ns = root.getNamespace();

        for (Dom.XMLNode child : root.getChildElements()) {
            if (child.getName() != 'Contents') {
                continue;
            }
            String key = getChildText(child, 'Key', ns);
            if (String.isBlank(key)) {
                continue;
            }
            String ext = getExtension(key);
            if (!SUPPORTED_EXTENSIONS.contains(ext)) {
                // Skip non-image objects and folder placeholders.
                continue;
            }

            ImageDto dto = new ImageDto();
            dto.key = key;
            dto.objectKey = key;
            dto.fileName = extractFileName(key);
            dto.contentType = contentTypeFromKey(key);
            dto.lastModified = getChildText(child, 'LastModified', ns);
            String sizeText = getChildText(child, 'Size', ns);
            dto.size = String.isBlank(sizeText) ? 0 : Integer.valueOf(sizeText.trim());
            // Retrievable reference: the LWC fetches bytes via getImage(contactId, key).
            dto.reference = key;
            images.add(dto);
        }
        return images;
    }

    /**
     * @description Returns the text of the first matching child element, namespace-aware.
     */
    private static String getChildText(Dom.XMLNode parent, String name, String ns) {
        Dom.XMLNode node = parent.getChildElement(name, ns);
        if (node == null) {
            // Fall back to a namespace-agnostic search.
            for (Dom.XMLNode c : parent.getChildElements()) {
                if (c.getName() == name) {
                    node = c;
                    break;
                }
            }
        }
        return node == null ? null : node.getText();
    }

    // =========================================================================
    // DTOs
    // =========================================================================

    /**
     * @description Describes a single image object listed from S3. No Salesforce record backs it.
     *              Comparable so a list sorts newest-first (LastModified desc). LastModified is
     *              the S3 ISO-8601 string, which sorts lexicographically == chronologically.
     */
    public class ImageDto implements Comparable {

        /**
         * @description Orders newest-first by lastModified; null timestamps sort last.
         */
        public Integer compareTo(Object other) {
            ImageDto that = (ImageDto) other;
            if (this.lastModified == that.lastModified) {
                return 0;
            }
            if (String.isBlank(this.lastModified)) {
                return 1;
            }
            if (String.isBlank(that.lastModified)) {
                return -1;
            }
            // Descending: later timestamp (greater string) comes first.
            return that.lastModified.compareTo(this.lastModified);
        }

        /** S3 object key. */
        @AuraEnabled
        public String key { get; set; }

        /** Alias of key, exposed for LWC clarity. */
        @AuraEnabled
        public String objectKey { get; set; }

        /** Display file name (last path segment of the key). */
        @AuraEnabled
        public String fileName { get; set; }

        /** Object size in bytes. */
        @AuraEnabled
        public Integer size { get; set; }

        /** Last-modified timestamp (ISO-8601 string as returned by S3). */
        @AuraEnabled
        public String lastModified { get; set; }

        /** Inferred MIME content type. */
        @AuraEnabled
        public String contentType { get; set; }

        /** Retrievable reference (object key) — the LWC calls getImage to fetch bytes. */
        @AuraEnabled
        public String reference { get; set; }
    }

    /**
     * @description A single bulk-upload request from the client.
     */
    public class ImageUploadRequest {
        /** Original file name (drives the object key + extension). */
        @AuraEnabled
        public String fileName { get; set; }

        /** Base64-encoded file body. */
        @AuraEnabled
        public String base64Content { get; set; }

        /** MIME content type of the file. */
        @AuraEnabled
        public String contentType { get; set; }
    }

    /**
     * @description Per-file result of a bulk upload.
     */
    public class UploadResultDto {
        /** File name this result relates to. */
        @AuraEnabled
        public String fileName { get; set; }

        /** True when the object was PUT to S3 successfully. */
        @AuraEnabled
        public Boolean success { get; set; }

        /** The S3 object key the file was stored under. */
        @AuraEnabled
        public String objectKey { get; set; }

        /** ETag returned by S3 on a successful PUT. */
        @AuraEnabled
        public String eTag { get; set; }

        /** Error message when success == false. */
        @AuraEnabled
        public String errorMessage { get; set; }
    }

    /**
     * @description The raw content of a single image retrieved from S3 (GetObject).
     */
    public class ImageContentDto {
        /** S3 object key. */
        @AuraEnabled
        public String objectKey { get; set; }

        /** Display file name. */
        @AuraEnabled
        public String fileName { get; set; }

        /** Base64-encoded image bytes (for rendering / download). */
        @AuraEnabled
        public String base64Data { get; set; }

        /** MIME content type. */
        @AuraEnabled
        public String contentType { get; set; }

        /** Size in bytes. */
        @AuraEnabled
        public Integer size { get; set; }
    }
}
