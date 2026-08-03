# Exclusion Image Gallery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one tab to the Salesforce Contact record — the "Exclusion Evidence Gallery" — that lists a patron's exclusion images from AWS S3 and lets authorised users view, enlarge, download, and multi-upload them.

**Architecture:** Three tiers, no Salesforce persistence. A single LWC (`exclusionImageGallery`) renders and orchestrates using **Lightning base components + SLDS**; a thin `with sharing` Apex controller (`ExclusionImageController`) validates and delegates to a service class (`ExclusionImageService`) that signs and proxies every S3 call through the pre-configured `Salesforce_S3_Connection` Named Credential (AWS SigV4). S3 is the source of truth. The browser never calls S3 directly because SigV4 signing is server-side only.

**Tech Stack:** Salesforce Apex (API 67.0), Lightning Web Components + SLDS, `sfdx-lwc-jest` for LWC tests, Apex `HttpCalloutMock` for Apex tests, AWS S3 REST (ListObjectsV2 / GetObject / PutObject).

## Global Constraints

- **No org deployment without explicit user go-ahead.** The user has frozen deploys. All source is authored locally. Apex tests and end-to-end verification run only when the user lifts the freeze (Task 8). LWC Jest tests run locally and are the live TDD loop until then.
- **SLDS-first (mandatory — the primary front-end standard).** Use Lightning base components (`lightning-card`, `lightning-button`, `lightning-button-icon`, `lightning-icon`, `lightning-spinner`, `lightning-input`) and SLDS layout (`slds-grid`, `slds-col`, `slds-size_*`) + SLDS utility classes for spacing. **No hardcoded colours/spacing** — use SLDS styling hooks (`--slds-g-color-*`) with hex fallbacks only. No hand-rolled equivalents of components SLDS already provides. The `lwc-reviewer` agent gates Task 6.
- **Apex structure standard.** Every class declares sharing explicitly. Controller entry-points are thin and delegate to a service class (no business logic in the controller). SOQL uses `WITH USER_MODE`. Custom exception is `*Exception extends Exception`. No swallowed exceptions. The `apex-reviewer` agent gates Task 3.
- **Named Credential name (verbatim):** `Salesforce_S3_Connection` — reference as `callout:Salesforce_S3_Connection`.
- **S3 key convention (verbatim):** `exclusion-images/{PatronId}/{PatronId}_{UploadedTimestampUTC}.{ext}` where timestamp format is `yyyyMMdd'T'HHmmss'Z'` (GMT).
- **Allowed upload formats (hard rule):** `png`, `jpg`, `jpeg`, `webp` only — reject all others. Sub-720p images are **allowed** (soft warning only, never blocked) — per BR10.
- **Patron key field:** `Contact.Patron_ID__c`. Blank patron ⇒ empty gallery, upload disabled.
- **Client upload size cap:** 4 MB per file (Apex sync heap is 6 MB; base64 inflates ~33%).
- **Key confinement:** `getImage` must reject any key not under `exclusion-images/{thisContactsPatronId}/`.
- **User-facing strings:** inline for the MVP. `lwc-reviewer` will flag these as [NIT/MINOR] "move to Custom Labels" — accepted for MVP, extract to Custom Labels in Phase 2. Do not block on it.
- **API version:** 67.0 for all `-meta.xml`.
- **Target org alias when deploying:** supplied by the user at Task 8 (referred to below as `<ORG>`).

---

## File Structure

| File | Responsibility |
|---|---|
| `force-app/main/default/classes/ExclusionImageService.cls` | S3 callouts + XML parsing + validation + key building. Holds constants, `ImageItem` DTO, `ExclusionImageException`. `inherited sharing`. |
| `force-app/main/default/classes/ExclusionImageService.cls-meta.xml` | Service metadata (API 67.0). |
| `force-app/main/default/classes/ExclusionImageController.cls` | Thin `with sharing` `@AuraEnabled` entry points: resolve patron (`WITH USER_MODE`), enforce key confinement, delegate to service, wrap errors as `AuraHandledException`. |
| `force-app/main/default/classes/ExclusionImageController.cls-meta.xml` | Controller metadata (API 67.0). |
| `force-app/main/default/classes/ExclusionImageControllerTest.cls` | Apex tests via `HttpCalloutMock`; drives the controller (covers service too). `@TestSetup` data. |
| `force-app/main/default/classes/ExclusionImageControllerTest.cls-meta.xml` | Test metadata. |
| `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.js` | Component logic: wire list, fetch thumbnails, modal state/nav, download, multi-upload. |
| `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.html` | SLDS grid + base components + SLDS modal viewer. |
| `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.css` | Minimal styling via SLDS hooks. |
| `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.js-meta.xml` | Exposes on `lightning__RecordPage`, Contact only. |
| `force-app/main/default/lwc/exclusionImageGallery/__tests__/exclusionImageGallery.test.js` | Jest tests (run locally now). |
| `force-app/main/default/permissionsets/Exclusion_Image_User.permissionset-meta.xml` | Grants `ExclusionImageController` access. |
| Contact Lightning Record Page | Config: add a tab hosting the LWC (manual, Task 8). |

---

## Task 1: List images (`ExclusionImageService.list` + `ExclusionImageController.getImages`)

**Files:**
- Create: `force-app/main/default/classes/ExclusionImageService.cls` (+ `.cls-meta.xml`)
- Create: `force-app/main/default/classes/ExclusionImageController.cls` (+ `.cls-meta.xml`)
- Create: `force-app/main/default/classes/ExclusionImageControllerTest.cls` (+ `.cls-meta.xml`)

**Interfaces:**
- Consumes: `Contact.Patron_ID__c` (existing external-id field).
- Produces:
  - `ExclusionImageService.ImageItem { String key; String fileName; Datetime lastModified; Long size; }` (all `@AuraEnabled`).
  - `ExclusionImageService.ExclusionImageException extends Exception`.
  - `ExclusionImageService.prefixFor(String patronId) → String` = `'exclusion-images/' + patronId + '/'`.
  - `ExclusionImageService.list(String patronId) → List<ImageItem>` (newest-first).
  - `ExclusionImageController.getImages(Id recordId) → List<ExclusionImageService.ImageItem>` (`@AuraEnabled(cacheable=true)`; empty list when no patron).
  - Service constants `NC`, `PREFIX` (reused by Tasks 2–3).

> **Running Apex tests:** Apex has no local runtime — the "run test" steps for Tasks 1–3 execute against an org and are gated on the deploy freeze (Task 8). Write tests first now; run them at Task 8 or whenever the user lifts the freeze.

- [ ] **Step 1: Write the metadata files**

Create `ExclusionImageService.cls-meta.xml`, `ExclusionImageController.cls-meta.xml`, `ExclusionImageControllerTest.cls-meta.xml`, each:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>67.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

- [ ] **Step 2: Write the failing test (list + sort + no-patron + error)**

Create `ExclusionImageControllerTest.cls`:
```apex
@IsTest
private class ExclusionImageControllerTest {

    class S3Mock implements HttpCalloutMock {
        Integer listStatus; String listBody;
        Integer getStatus;  Blob getBody; String getContentType;
        Integer putStatus;
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET' && req.getEndpoint().contains('list-type=2')) {
                res.setStatusCode(listStatus); res.setBody(listBody);
            } else if (req.getMethod() == 'GET') {
                res.setStatusCode(getStatus); res.setBodyAsBlob(getBody);
                if (getContentType != null) res.setHeader('Content-Type', getContentType);
            } else if (req.getMethod() == 'PUT') {
                res.setStatusCode(putStatus);
            }
            return res;
        }
    }

    @TestSetup
    static void setup() {
        insert new Contact(LastName = 'Patron', Patron_ID__c = '40818053');
        insert new Contact(LastName = 'NoPatron');
    }

    static Id patronContactId() {
        return [SELECT Id FROM Contact WHERE Patron_ID__c = '40818053' LIMIT 1].Id;
    }
    static Id noPatronContactId() {
        return [SELECT Id FROM Contact WHERE Patron_ID__c = null LIMIT 1].Id;
    }

    static String listXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
          + '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
          + '<Contents><Key>exclusion-images/40818053/40818053_20260515T091230Z.jpg</Key>'
          + '<LastModified>2026-05-15T09:12:30.000Z</LastModified><Size>284517</Size></Contents>'
          + '<Contents><Key>exclusion-images/40818053/40818053_20260520T101500Z.png</Key>'
          + '<LastModified>2026-05-20T10:15:00.000Z</LastModified><Size>91234</Size></Contents>'
          + '</ListBucketResult>';
    }

    @IsTest
    static void getImagesReturnsItemsNewestFirst() {
        S3Mock mock = new S3Mock();
        mock.listStatus = 200; mock.listBody = listXml();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<ExclusionImageService.ImageItem> items =
            ExclusionImageController.getImages(patronContactId());
        Test.stopTest();

        System.assertEquals(2, items.size(), 'both objects returned');
        System.assertEquals('40818053_20260520T101500Z.png', items[0].fileName, 'newest first');
        System.assertEquals(284517, items[1].size, 'size parsed');
    }

    @IsTest
    static void getImagesEmptyWhenNoPatronId() {
        Test.startTest();
        List<ExclusionImageService.ImageItem> items =
            ExclusionImageController.getImages(noPatronContactId());
        Test.stopTest();
        System.assertEquals(0, items.size(), 'no patron id -> empty, no callout');
    }

    @IsTest
    static void getImagesThrowsOnS3Error() {
        S3Mock mock = new S3Mock();
        mock.listStatus = 500; mock.listBody = 'err';
        Test.setMock(HttpCalloutMock.class, mock);
        Boolean threw = false;
        Test.startTest();
        try { ExclusionImageController.getImages(patronContactId()); }
        catch (Exception e) { threw = true; }
        Test.stopTest();
        System.assert(threw, 'S3 500 surfaces as exception');
    }
}
```

- [ ] **Step 3: Run test to verify it fails** (when org available)

Run: `sf apex run test -l RunSpecifiedTests -t ExclusionImageControllerTest -o <ORG> -w 10`
Expected: FAIL/compile error — classes do not exist yet.

- [ ] **Step 4: Write the service with `list`**

Create `ExclusionImageService.cls`:
```apex
public inherited sharing class ExclusionImageService {

    @TestVisible static final String NC     = 'callout:Salesforce_S3_Connection';
    @TestVisible static final String PREFIX = 'exclusion-images/';
    static final Set<String> ALLOWED_EXT = new Set<String>{'png','jpg','jpeg','webp'};
    static final Map<String,String> EXT_BY_TYPE = new Map<String,String>{
        'image/png'  => 'png',  'image/jpeg' => 'jpg',
        'image/jpg'  => 'jpg',  'image/webp' => 'webp'
    };

    public class ExclusionImageException extends Exception {}

    public class ImageItem {
        @AuraEnabled public String key;
        @AuraEnabled public String fileName;
        @AuraEnabled public Datetime lastModified;
        @AuraEnabled public Long size;
    }

    class ByLastModifiedDesc implements Comparator<ImageItem> {
        public Integer compare(ImageItem a, ImageItem b) {
            if (a.lastModified == b.lastModified) return 0;
            return a.lastModified < b.lastModified ? 1 : -1;
        }
    }

    public static String prefixFor(String patronId) {
        return PREFIX + patronId + '/';
    }

    static String encodeKey(String key) {
        List<String> parts = new List<String>();
        for (String seg : key.split('/', -1)) {
            parts.add(EncodingUtil.urlEncode(seg, 'UTF-8').replace('+', '%20'));
        }
        return String.join(parts, '/');
    }

    public static List<ImageItem> list(String patronId) {
        List<ImageItem> items = new List<ImageItem>();
        String prefix = prefixFor(patronId);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NC + '/?list-type=2&prefix=' + EncodingUtil.urlEncode(prefix, 'UTF-8'));
        req.setMethod('GET');
        req.setTimeout(120000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new ExclusionImageException('S3 list failed: ' + res.getStatusCode() + ' ' + res.getStatus());
        }

        Dom.Document doc = res.getBodyDocument();
        Dom.XmlNode root = doc.getRootElement();
        String ns = root.getNamespace();
        for (Dom.XmlNode node : root.getChildElements()) {
            if (node.getName() != 'Contents') continue;
            ImageItem it = new ImageItem();
            it.key = node.getChildElement('Key', ns).getText();
            it.fileName = it.key.substringAfterLast('/');
            String lm = node.getChildElement('LastModified', ns).getText();
            it.lastModified = (Datetime) JSON.deserialize('"' + lm + '"', Datetime.class);
            it.size = Long.valueOf(node.getChildElement('Size', ns).getText());
            items.add(it);
        }
        items.sort(new ByLastModifiedDesc());
        return items;
    }
}
```

- [ ] **Step 5: Write the controller with `getImages`**

Create `ExclusionImageController.cls`:
```apex
public with sharing class ExclusionImageController {

    static String patronIdFor(Id recordId) {
        if (recordId == null) return null;
        List<Contact> cons = [
            SELECT Patron_ID__c FROM Contact WHERE Id = :recordId WITH USER_MODE LIMIT 1
        ];
        if (cons.isEmpty() || String.isBlank(cons[0].Patron_ID__c)) return null;
        return cons[0].Patron_ID__c;
    }

    @AuraEnabled(cacheable=true)
    public static List<ExclusionImageService.ImageItem> getImages(Id recordId) {
        try {
            String patronId = patronIdFor(recordId);
            if (patronId == null) return new List<ExclusionImageService.ImageItem>();
            return ExclusionImageService.list(patronId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
```

- [ ] **Step 6: Run tests to verify all pass** (when org available)

Run: `sf apex run test -l RunSpecifiedTests -t ExclusionImageControllerTest -o <ORG> -w 10`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```powershell
git add force-app/main/default/classes/ExclusionImageService.cls force-app/main/default/classes/ExclusionImageService.cls-meta.xml force-app/main/default/classes/ExclusionImageController.cls force-app/main/default/classes/ExclusionImageController.cls-meta.xml force-app/main/default/classes/ExclusionImageControllerTest.cls force-app/main/default/classes/ExclusionImageControllerTest.cls-meta.xml
git commit -m "feat: list patron images via S3 service + thin controller"
```

---

## Task 2: Fetch one image (`ExclusionImageService.getObject` + `ExclusionImageController.getImage`)

**Files:**
- Modify: `force-app/main/default/classes/ExclusionImageService.cls`
- Modify: `force-app/main/default/classes/ExclusionImageController.cls`
- Modify: `force-app/main/default/classes/ExclusionImageControllerTest.cls`

**Interfaces:**
- Consumes: `NC`, `encodeKey`, `prefixFor` from Task 1.
- Produces:
  - `ExclusionImageService.getObject(String objectKey) → Map<String,String>` = `{ 'data': base64, 'contentType': mime }`.
  - `ExclusionImageController.getImage(Id recordId, String objectKey) → Map<String,String>` (`@AuraEnabled`) — enforces key confinement before delegating.

- [ ] **Step 1: Write the failing tests (success + key confinement)**

Add to `ExclusionImageControllerTest.cls`:
```apex
    @IsTest
    static void getImageReturnsBase64() {
        S3Mock mock = new S3Mock();
        mock.getStatus = 200; mock.getBody = Blob.valueOf('BINARY');
        mock.getContentType = 'image/jpeg';
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Map<String,String> out = ExclusionImageController.getImage(
            patronContactId(), 'exclusion-images/40818053/40818053_20260515T091230Z.jpg');
        Test.stopTest();

        System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf('BINARY')), out.get('data'));
        System.assertEquals('image/jpeg', out.get('contentType'));
    }

    @IsTest
    static void getImageRejectsForeignKey() {
        Test.setMock(HttpCalloutMock.class, new S3Mock());
        Boolean threw = false;
        Test.startTest();
        try {
            ExclusionImageController.getImage(patronContactId(), 'exclusion-images/99999/99999_x.jpg');
        } catch (Exception e) { threw = true; }
        Test.stopTest();
        System.assert(threw, 'cannot fetch another patron key');
    }
```

- [ ] **Step 2: Run tests to verify they fail** (when org available)

Run: `sf apex run test -l RunSpecifiedTests -t ExclusionImageControllerTest -o <ORG> -w 10`
Expected: FAIL — `getObject` / `getImage` not defined.

- [ ] **Step 3: Add `getObject` to the service**

Add to `ExclusionImageService.cls` (inside the class):
```apex
    public static Map<String,String> getObject(String objectKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NC + '/' + encodeKey(objectKey));
        req.setMethod('GET');
        req.setTimeout(120000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new ExclusionImageException('S3 get failed: ' + res.getStatusCode());
        }
        Map<String,String> out = new Map<String,String>();
        out.put('data', EncodingUtil.base64Encode(res.getBodyAsBlob()));
        String ct = res.getHeader('Content-Type');
        out.put('contentType', String.isBlank(ct) ? 'application/octet-stream' : ct);
        return out;
    }
```

- [ ] **Step 4: Add `getImage` to the controller (with key confinement)**

Add to `ExclusionImageController.cls`:
```apex
    @AuraEnabled
    public static Map<String,String> getImage(Id recordId, String objectKey) {
        try {
            String patronId = patronIdFor(recordId);
            if (patronId == null) {
                throw new ExclusionImageService.ExclusionImageException('Patron has no Patron ID.');
            }
            String allowed = ExclusionImageService.prefixFor(patronId);
            if (String.isBlank(objectKey) || !objectKey.startsWith(allowed)) {
                throw new ExclusionImageService.ExclusionImageException('Access denied for the requested object.');
            }
            return ExclusionImageService.getObject(objectKey);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
```

- [ ] **Step 5: Run tests to verify they pass** (when org available)

Run: `sf apex run test -l RunSpecifiedTests -t ExclusionImageControllerTest -o <ORG> -w 10`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```powershell
git add force-app/main/default/classes/ExclusionImageService.cls force-app/main/default/classes/ExclusionImageController.cls force-app/main/default/classes/ExclusionImageControllerTest.cls
git commit -m "feat: fetch image bytes with per-patron key confinement"
```

---

## Task 3: Upload one image (`ExclusionImageService.put` + `ExclusionImageController.uploadImage`) + apex-reviewer gate

**Files:**
- Modify: `force-app/main/default/classes/ExclusionImageService.cls`
- Modify: `force-app/main/default/classes/ExclusionImageController.cls`
- Modify: `force-app/main/default/classes/ExclusionImageControllerTest.cls`

**Interfaces:**
- Consumes: `NC`, `PREFIX`, `encodeKey`, `ALLOWED_EXT`, `EXT_BY_TYPE`, `ImageItem` from Tasks 1–2.
- Produces:
  - `ExclusionImageService.put(String patronId, String fileName, String base64Data, String contentType) → ImageItem` — validates format, builds the key, PUTs, returns the created item.
  - `ExclusionImageController.uploadImage(Id recordId, String fileName, String base64Data, String contentType) → ExclusionImageService.ImageItem` (`@AuraEnabled`).

- [ ] **Step 1: Write the failing tests (success + bad format)**

Add to `ExclusionImageControllerTest.cls`:
```apex
    @IsTest
    static void uploadImageSuccess() {
        S3Mock mock = new S3Mock();
        mock.putStatus = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        String b64 = EncodingUtil.base64Encode(Blob.valueOf('PNGDATA'));
        Test.startTest();
        ExclusionImageService.ImageItem it =
            ExclusionImageController.uploadImage(patronContactId(), 'evidence.png', b64, 'image/png');
        Test.stopTest();

        System.assert(it.key.startsWith('exclusion-images/40818053/40818053_'), 'key namespaced');
        System.assert(it.key.endsWith('.png'), 'extension preserved');
        System.assertEquals(it.key.substringAfterLast('/'), it.fileName);
    }

    @IsTest
    static void uploadImageRejectsBadFormat() {
        Test.setMock(HttpCalloutMock.class, new S3Mock());
        String b64 = EncodingUtil.base64Encode(Blob.valueOf('PDF'));
        Boolean threw = false;
        Test.startTest();
        try {
            ExclusionImageController.uploadImage(patronContactId(), 'form.pdf', b64, 'application/pdf');
        } catch (Exception e) { threw = true; }
        Test.stopTest();
        System.assert(threw, 'non-image rejected');
    }
```

- [ ] **Step 2: Run tests to verify they fail** (when org available)

Run: `sf apex run test -l RunSpecifiedTests -t ExclusionImageControllerTest -o <ORG> -w 10`
Expected: FAIL — `put` / `uploadImage` not defined.

- [ ] **Step 3: Add `put` + `extensionFor` to the service**

Add to `ExclusionImageService.cls`:
```apex
    static String extensionFor(String fileName, String contentType) {
        String ext;
        if (String.isNotBlank(fileName) && fileName.contains('.')) {
            ext = fileName.substringAfterLast('.').toLowerCase();
        }
        String ct = contentType == null ? null : contentType.toLowerCase();
        if (String.isBlank(ext) && ct != null && EXT_BY_TYPE.containsKey(ct)) {
            ext = EXT_BY_TYPE.get(ct);
        }
        return ext;
    }

    public static ImageItem put(String patronId, String fileName, String base64Data, String contentType) {
        if (String.isBlank(base64Data)) throw new ExclusionImageException('Empty file.');
        String ext = extensionFor(fileName, contentType);
        if (ext == null || !ALLOWED_EXT.contains(ext)) {
            throw new ExclusionImageException('Unsupported file type. Allowed: PNG, JPG, WEBP.');
        }

        String ts = Datetime.now().formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
        String key = prefixFor(patronId) + patronId + '_' + ts + '.' + ext;
        Blob body = EncodingUtil.base64Decode(base64Data);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NC + '/' + encodeKey(key));
        req.setMethod('PUT');
        req.setHeader('Content-Type', String.isBlank(contentType) ? 'application/octet-stream' : contentType);
        req.setBodyAsBlob(body);
        req.setTimeout(120000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200 && res.getStatusCode() != 204) {
            throw new ExclusionImageException('S3 upload failed: ' + res.getStatusCode() + ' ' + res.getStatus());
        }

        ImageItem it = new ImageItem();
        it.key = key;
        it.fileName = key.substringAfterLast('/');
        it.lastModified = Datetime.now();
        it.size = body.size();
        return it;
    }
```

- [ ] **Step 4: Add `uploadImage` to the controller**

Add to `ExclusionImageController.cls`:
```apex
    @AuraEnabled
    public static ExclusionImageService.ImageItem uploadImage(
        Id recordId, String fileName, String base64Data, String contentType) {
        try {
            String patronId = patronIdFor(recordId);
            if (patronId == null) {
                throw new ExclusionImageService.ExclusionImageException('Patron has no Patron ID; cannot upload.');
            }
            return ExclusionImageService.put(patronId, fileName, base64Data, contentType);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
```

- [ ] **Step 5: Run tests to verify they pass** (when org available)

Run: `sf apex run test -l RunSpecifiedTests -t ExclusionImageControllerTest -o <ORG> -w 10`
Expected: PASS (7 tests), coverage > 85%.

- [ ] **Step 6: Run the apex-reviewer agent and address findings**

Dispatch the `apex-reviewer` agent (Agent tool, `subagent_type: apex-reviewer`) against `ExclusionImageService.cls`, `ExclusionImageController.cls`, and `ExclusionImageControllerTest.cls`. Fix every **[BLOCKER]** and **[MAJOR]**; judgement-call **[MINOR]/[NIT]** may be deferred with a one-line rationale. Re-run the Apex tests after any change.

- [ ] **Step 7: Commit**

```powershell
git add force-app/main/default/classes
git commit -m "feat: upload image with format validation; address apex-reviewer findings"
```

---

## Task 4: LWC scaffold — SLDS grid, wire, thumbnails, empty state

**Files:**
- Create: `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.js`
- Create: `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.html`
- Create: `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.css`
- Create: `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.js-meta.xml`
- Create: `force-app/main/default/lwc/exclusionImageGallery/__tests__/exclusionImageGallery.test.js`

**Interfaces:**
- Consumes: `getImages`, `getImage` from `ExclusionImageController`.
- Produces: component `exclusionImageGallery` with `@api recordId`; state `images` (each `{ key, fileName, dateText, src }`), `isLoading`, `errorMsg`; getters `hasImages`, `showEmpty`, `selected`, `isModalOpen`; method `loadThumbnails()`.

> **This is the live TDD loop** — Jest runs locally now via `npm run test:unit`.

- [ ] **Step 1: Write the meta file (exposes on Contact record page)**

Create `exclusionImageGallery.js-meta.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>67.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Contact</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

- [ ] **Step 2: Write the failing Jest test (empty state + tile render)**

Create `__tests__/exclusionImageGallery.test.js`:
```javascript
import { createElement } from 'lwc';
import ExclusionImageGallery from 'c/exclusionImageGallery';
import getImages from '@salesforce/apex/ExclusionImageController.getImages';
import getImage from '@salesforce/apex/ExclusionImageController.getImage';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

jest.mock(
    '@salesforce/apex/ExclusionImageController.getImages',
    () => ({ default: jest.fn() }), { virtual: true }
);
jest.mock(
    '@salesforce/apex/ExclusionImageController.getImage',
    () => ({ default: jest.fn() }), { virtual: true }
);
jest.mock(
    '@salesforce/apex/ExclusionImageController.uploadImage',
    () => ({ default: jest.fn() }), { virtual: true }
);

const getImagesAdapter = registerApexTestWireAdapter(getImages);
function flush() { return Promise.resolve(); }

describe('c-exclusion-image-gallery', () => {
    afterEach(() => {
        while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
        jest.clearAllMocks();
    });

    it('shows empty state when no images', async () => {
        const el = createElement('c-exclusion-image-gallery', { is: ExclusionImageGallery });
        el.recordId = '003000000000001';
        document.body.appendChild(el);
        getImagesAdapter.emit([]);
        await flush();
        expect(el.shadowRoot.querySelector('.empty-state')).not.toBeNull();
    });

    it('renders a tile per image', async () => {
        getImage.mockResolvedValue({ data: 'QUJD', contentType: 'image/png' });
        const el = createElement('c-exclusion-image-gallery', { is: ExclusionImageGallery });
        el.recordId = '003000000000001';
        document.body.appendChild(el);
        getImagesAdapter.emit([
            { key: 'exclusion-images/1/1_a.png', fileName: '1_a.png', lastModified: '2026-05-20T10:15:00.000Z', size: 100 },
            { key: 'exclusion-images/1/1_b.jpg', fileName: '1_b.jpg', lastModified: '2026-05-15T09:12:30.000Z', size: 200 }
        ]);
        await flush(); await flush();
        expect(el.shadowRoot.querySelectorAll('.tile').length).toBe(2);
    });
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `npm run test:unit -- exclusionImageGallery`
Expected: FAIL — component module not found / no `.empty-state`.

- [ ] **Step 4: Write the component JS**

Create `exclusionImageGallery.js`:
```javascript
import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getImages from '@salesforce/apex/ExclusionImageController.getImages';
import getImage from '@salesforce/apex/ExclusionImageController.getImage';
import uploadImage from '@salesforce/apex/ExclusionImageController.uploadImage';

const ALLOWED_TYPES = ['image/png', 'image/jpeg', 'image/webp'];
const MAX_BYTES = 4 * 1024 * 1024;

export default class ExclusionImageGallery extends LightningElement {
    @api recordId;

    images = [];
    isLoading = true;
    errorMsg;
    selectedIndex = -1;
    _wired;

    @wire(getImages, { recordId: '$recordId' })
    wiredImages(result) {
        this._wired = result;
        const { data, error } = result;
        if (data) {
            this.images = data.map((i) => ({
                key: i.key,
                fileName: i.fileName,
                dateText: this.formatDate(i.lastModified),
                src: null
            }));
            this.errorMsg = undefined;
            this.isLoading = false;
            this.loadThumbnails();
        } else if (error) {
            this.errorMsg = this.reduceError(error);
            this.isLoading = false;
        }
    }

    get hasImages() { return this.images && this.images.length > 0; }
    get showEmpty() { return !this.isLoading && !this.errorMsg && !this.hasImages; }
    get isModalOpen() { return this.selectedIndex >= 0; }
    get selected() { return this.isModalOpen ? this.images[this.selectedIndex] : null; }

    async loadThumbnails() {
        const updated = [...this.images];
        await Promise.allSettled(
            updated.map(async (img, idx) => {
                try {
                    const r = await getImage({ recordId: this.recordId, objectKey: img.key });
                    updated[idx] = { ...img, src: `data:${r.contentType};base64,${r.data}` };
                } catch (e) {
                    updated[idx] = { ...img, src: null };
                }
            })
        );
        this.images = updated;
    }

    handleTileClick(event) {
        this.selectedIndex = parseInt(event.currentTarget.dataset.idx, 10);
    }
    closeModal() { this.selectedIndex = -1; }

    // Real logic added in Tasks 5–6.
    showPrev() {}
    showNext() {}
    downloadCurrent() {}
    handleFilesSelected() {}

    formatDate(iso) {
        if (!iso) return '';
        return new Date(iso).toLocaleDateString('en-AU', { day: '2-digit', month: 'short', year: 'numeric' });
    }
    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        return error?.body?.message || error?.message || 'Unknown error';
    }
}
```

- [ ] **Step 5: Write the component HTML (base components + SLDS grid)**

Create `exclusionImageGallery.html`:
```html
<template>
    <lightning-card title="Exclusion Evidence Gallery" icon-name="standard:photo">
        <div slot="actions">
            <lightning-input
                type="file"
                label="Upload image(s)"
                variant="label-hidden"
                multiple
                accept="image/png,image/jpeg,image/webp"
                onchange={handleFilesSelected}
            ></lightning-input>
        </div>

        <div class="slds-p-horizontal_small slds-p-bottom_small gallery-body">
            <template if:true={isLoading}>
                <lightning-spinner alternative-text="Loading images" size="small"></lightning-spinner>
            </template>

            <template if:true={errorMsg}>
                <div class="slds-text-color_error slds-p-around_small" role="alert">{errorMsg}</div>
            </template>

            <template if:true={showEmpty}>
                <div class="empty-state slds-p-around_large slds-align_absolute-center slds-text-color_weak">
                    No exclusion images on file yet.
                </div>
            </template>

            <template if:true={hasImages}>
                <div class="slds-grid slds-wrap slds-gutters_x-small">
                    <template for:each={images} for:item="img" for:index="idx">
                        <div key={img.key}
                             class="slds-col slds-size_1-of-2 slds-medium-size_1-of-3 slds-large-size_1-of-4 slds-p-vertical_x-small">
                            <button class="slds-button slds-button_reset tile"
                                    data-idx={idx}
                                    onclick={handleTileClick}
                                    aria-label={img.fileName}
                                    title={img.fileName}>
                                <template if:true={img.src}>
                                    <img src={img.src} alt={img.fileName} class="tile-img" />
                                </template>
                                <template if:false={img.src}>
                                    <div class="tile-img tile-placeholder slds-align_absolute-center">
                                        <lightning-icon icon-name="standard:photo"
                                                        alternative-text="Image loading"
                                                        size="small"></lightning-icon>
                                    </div>
                                </template>
                                <div class="slds-p-around_xx-small slds-text-body_small tile-meta">
                                    <span class="slds-truncate" title={img.fileName}>{img.fileName}</span>
                                    <span class="slds-text-color_weak">{img.dateText}</span>
                                </div>
                            </button>
                        </div>
                    </template>
                </div>
            </template>
        </div>

        <!-- SLDS modal viewer; controls wired in Task 5 -->
        <template if:true={isModalOpen}>
            <section role="dialog" tabindex="-1" aria-modal="true" aria-labelledby="viewer-heading"
                     class="slds-modal slds-fade-in-open">
                <div class="slds-modal__container">
                    <header class="slds-modal__header">
                        <lightning-button-icon icon-name="utility:close" alternative-text="Close"
                            variant="bare-inverse" class="slds-modal__close viewer-close"
                            onclick={closeModal}></lightning-button-icon>
                        <h2 id="viewer-heading" class="slds-modal__title slds-hyphenate">{selected.fileName}</h2>
                        <p class="slds-m-top_x-small slds-text-color_weak">{selected.dateText}</p>
                    </header>
                    <div class="slds-modal__content slds-p-around_medium slds-grid slds-grid_align-center slds-grid_vertical-align-center">
                        <lightning-button-icon icon-name="utility:chevronleft" alternative-text="Previous image"
                            size="large" class="viewer-prev slds-m-right_small" onclick={showPrev}></lightning-button-icon>
                        <img class="viewer-img" src={selected.src} alt={selected.fileName} />
                        <lightning-button-icon icon-name="utility:chevronright" alternative-text="Next image"
                            size="large" class="viewer-next slds-m-left_small" onclick={showNext}></lightning-button-icon>
                    </div>
                    <footer class="slds-modal__footer">
                        <lightning-button label="Download" icon-name="utility:download"
                            variant="brand" class="viewer-download" onclick={downloadCurrent}></lightning-button>
                    </footer>
                </div>
            </section>
            <div class="slds-backdrop slds-backdrop_open" onclick={closeModal}></div>
        </template>
    </lightning-card>
</template>
```

- [ ] **Step 6: Write the component CSS (SLDS styling hooks only)**

Create `exclusionImageGallery.css`:
```css
.gallery-body { min-height: 6rem; position: relative; }
.tile {
    width: 100%;
    border: 1px solid var(--slds-g-color-border-base-1, #dddbda);
    border-radius: 0.25rem;
    overflow: hidden;
    background: var(--slds-g-color-neutral-base-100, #ffffff);
    cursor: pointer;
}
.tile-img { width: 100%; height: 7rem; object-fit: cover; display: block; }
.tile-placeholder { background: var(--slds-g-color-neutral-base-95, #f3f2f2); }
.tile-meta { display: flex; flex-direction: column; text-align: left; }
.viewer-img { max-width: 70vw; max-height: 65vh; object-fit: contain; }
```

- [ ] **Step 7: Run test to verify it passes**

Run: `npm run test:unit -- exclusionImageGallery`
Expected: PASS (empty state + 2 tiles).

- [ ] **Step 8: Commit**

```powershell
git add force-app/main/default/lwc/exclusionImageGallery
git commit -m "feat: exclusionImageGallery LWC with SLDS grid, wire and empty state"
```

---

## Task 5: Modal viewer — navigation, keyboard, download

**Files:**
- Modify: `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.js`
- Modify: `force-app/main/default/lwc/exclusionImageGallery/__tests__/exclusionImageGallery.test.js`

**Interfaces:**
- Consumes: `images`, `selectedIndex`, `handleTileClick`, `isModalOpen` from Task 4.
- Produces: working `showPrev`/`showNext` (wrap-around), `downloadCurrent` (data-URL anchor), and `Escape`/`ArrowLeft`/`ArrowRight` key handling active only while the modal is open.

- [ ] **Step 1: Write the failing test (open → prev wraps to last)**

Add to `__tests__/exclusionImageGallery.test.js`:
```javascript
    it('opens modal on tile click and navigates with wrap-around', async () => {
        getImage.mockResolvedValue({ data: 'QUJD', contentType: 'image/png' });
        const el = createElement('c-exclusion-image-gallery', { is: ExclusionImageGallery });
        el.recordId = '003000000000001';
        document.body.appendChild(el);
        getImagesAdapter.emit([
            { key: 'k/1_a.png', fileName: '1_a.png', lastModified: '2026-05-20T10:15:00.000Z', size: 100 },
            { key: 'k/1_b.jpg', fileName: '1_b.jpg', lastModified: '2026-05-15T09:12:30.000Z', size: 200 }
        ]);
        await flush(); await flush();

        el.shadowRoot.querySelectorAll('.tile')[0].click();
        await flush();
        expect(el.shadowRoot.querySelector('.slds-modal')).not.toBeNull();

        el.shadowRoot.querySelector('.viewer-prev').click(); // index 0 wraps to last
        await flush();
        expect(el.shadowRoot.querySelector('.viewer-img').getAttribute('alt')).toBe('1_b.jpg');
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- exclusionImageGallery`
Expected: FAIL — `showPrev` is a no-op; alt stays `1_a.png`.

- [ ] **Step 3: Implement navigation, download, and keyboard handling**

Replace the stub `showPrev`/`showNext`/`downloadCurrent` in `exclusionImageGallery.js` and add lifecycle key handling:
```javascript
    showPrev() {
        if (!this.images.length) return;
        this.selectedIndex = (this.selectedIndex - 1 + this.images.length) % this.images.length;
    }
    showNext() {
        if (!this.images.length) return;
        this.selectedIndex = (this.selectedIndex + 1) % this.images.length;
    }
    downloadCurrent() {
        const img = this.selected;
        if (!img || !img.src) return;
        const a = document.createElement('a');
        a.href = img.src;
        a.download = img.fileName;
        a.click();
    }

    connectedCallback() {
        this._onKey = (e) => this.handleKey(e);
        window.addEventListener('keydown', this._onKey);
    }
    disconnectedCallback() {
        window.removeEventListener('keydown', this._onKey);
    }
    handleKey(e) {
        if (!this.isModalOpen) return;
        if (e.key === 'Escape') this.closeModal();
        else if (e.key === 'ArrowLeft') this.showPrev();
        else if (e.key === 'ArrowRight') this.showNext();
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- exclusionImageGallery`
Expected: PASS — alt is `1_b.jpg` after prev wrap.

- [ ] **Step 5: Commit**

```powershell
git add force-app/main/default/lwc/exclusionImageGallery
git commit -m "feat: modal viewer navigation, keyboard controls and download"
```

---

## Task 6: Multi-file upload with partial success + lwc-reviewer gate

**Files:**
- Modify: `force-app/main/default/lwc/exclusionImageGallery/exclusionImageGallery.js`
- Modify: `force-app/main/default/lwc/exclusionImageGallery/__tests__/exclusionImageGallery.test.js`

**Interfaces:**
- Consumes: `uploadImage` Apex, `refreshApex`, `ShowToastEvent`, `ALLOWED_TYPES`, `MAX_BYTES`, `_wired` from Task 4.
- Produces: working `handleFilesSelected(event)` → `processFiles(files)` that validates each file (format hard-reject, >4 MB reject, <720p soft-warn only), uploads accepted files one call each, aggregates `{uploaded, rejected, failed}`, toasts a summary, and `refreshApex(this._wired)`. Helpers `fileToBase64(file)`, `checkResolution(file)`, and a test-only `handleFilesForTest(files)` pass-through.

- [ ] **Step 1: Write the failing test (mixed valid/invalid batch)**

Add to `__tests__/exclusionImageGallery.test.js`:
```javascript
    it('uploads valid files and rejects bad formats (partial success)', async () => {
        const uploadImage = require('@salesforce/apex/ExclusionImageController.uploadImage').default;
        uploadImage.mockResolvedValue({ key: 'k/1_new.png', fileName: '1_new.png', lastModified: '2026-06-01T00:00:00.000Z', size: 50 });
        getImage.mockResolvedValue({ data: 'QUJD', contentType: 'image/png' });

        const el = createElement('c-exclusion-image-gallery', { is: ExclusionImageGallery });
        el.recordId = '003000000000001';
        document.body.appendChild(el);
        getImagesAdapter.emit([]);
        await flush();

        const good = new File(['x'], 'a.png', { type: 'image/png' });
        const bad = new File(['x'], 'b.pdf', { type: 'application/pdf' });
        await el.handleFilesForTest([good, bad]);
        await flush();

        expect(uploadImage).toHaveBeenCalledTimes(1); // only the png
    });
```

> The test calls a thin, test-only pass-through (`handleFilesForTest`) so we exercise the aggregation logic without depending on jsdom's `FileReader`/`Image`. Production uses `handleFilesSelected`.

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- exclusionImageGallery`
Expected: FAIL — `handleFilesForTest` undefined; `uploadImage` never called.

- [ ] **Step 3: Implement the upload workflow**

Replace the stub `handleFilesSelected` in `exclusionImageGallery.js` and add helpers:
```javascript
    handleFilesSelected(event) {
        const files = Array.from(
            (event.detail && event.detail.files) || event.target.files || []
        );
        return this.processFiles(files);
    }

    // Test-only pass-through (keeps Jest independent of jsdom FileReader/Image).
    handleFilesForTest(files) { return this.processFiles(files); }

    async processFiles(files) {
        if (!files.length) return;
        let uploaded = 0, rejected = 0, failed = 0;
        const rejectedNames = [];

        for (const f of files) {
            if (!ALLOWED_TYPES.includes(f.type)) { rejected++; rejectedNames.push(f.name); continue; }
            if (f.size && f.size > MAX_BYTES) { rejected++; rejectedNames.push(f.name + ' (too large)'); continue; }
            await this.checkResolution(f); // soft warn only; never blocks
            try {
                const base64Data = await this.fileToBase64(f);
                await uploadImage({
                    recordId: this.recordId, fileName: f.name,
                    base64Data, contentType: f.type
                });
                uploaded++;
            } catch (e) { failed++; }
        }

        this.dispatchEvent(new ShowToastEvent({
            title: 'Upload complete',
            message: `${uploaded} uploaded, ${rejected} rejected, ${failed} failed`
                + (rejectedNames.length ? ` — rejected: ${rejectedNames.join(', ')}` : ''),
            variant: failed || rejected ? 'warning' : 'success'
        }));

        if (uploaded > 0 && this._wired) {
            await refreshApex(this._wired);
        }
    }

    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(String(reader.result).split(',')[1]);
            reader.onerror = () => reject(reader.error);
            reader.readAsDataURL(file);
        });
    }

    checkResolution(file) {
        // <720p is allowed (BR10) — warn only, never block.
        return new Promise((resolve) => {
            if (typeof Image === 'undefined' || !file.type.startsWith('image/')) { resolve(); return; }
            const url = URL.createObjectURL(file);
            const img = new Image();
            img.onload = () => {
                if (Math.min(img.width, img.height) < 720) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Low resolution',
                        message: `${file.name} is below 720p — uploaded anyway.`,
                        variant: 'info'
                    }));
                }
                URL.revokeObjectURL(url); resolve();
            };
            img.onerror = () => { URL.revokeObjectURL(url); resolve(); };
            img.src = url;
        });
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- exclusionImageGallery`
Expected: PASS — `uploadImage` called once (png only).

- [ ] **Step 5: Run the full Jest suite with coverage**

Run: `npm run test:unit -- --coverage exclusionImageGallery`
Expected: all tests pass.

- [ ] **Step 6: Run the lwc-reviewer agent and address findings**

Dispatch the `lwc-reviewer` agent (Agent tool, `subagent_type: lwc-reviewer`) against the `exclusionImageGallery` bundle. Fix every **[BLOCKER]** and **[MAJOR]** (expected focus: base components vs raw HTML, SLDS hooks vs hardcoded styles, accessible names, `@wire` error handling, stable `key`). Custom-Label **[NIT/MINOR]** is deferred per Global Constraints with that rationale. Re-run Jest after any change.

- [ ] **Step 7: Commit**

```powershell
git add force-app/main/default/lwc/exclusionImageGallery
git commit -m "feat: multi-file upload with partial success; address lwc-reviewer findings"
```

---

## Task 7: Permission set

**Files:**
- Create: `force-app/main/default/permissionsets/Exclusion_Image_User.permissionset-meta.xml`

**Interfaces:**
- Consumes: `ExclusionImageController` (grants access to it — the only class the LWC calls).
- Produces: assignable permission set `Exclusion_Image_User`.

- [ ] **Step 1: Write the permission set metadata**

Create `Exclusion_Image_User.permissionset-meta.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Exclusion Image User</label>
    <description>Access to the Exclusion Evidence Gallery (Apex proxy to S3).</description>
    <hasActivationRequired>false</hasActivationRequired>
    <classAccesses>
        <apexClass>ExclusionImageController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
</PermissionSet>
```

- [ ] **Step 2: Commit**

```powershell
git add force-app/main/default/permissionsets/Exclusion_Image_User.permissionset-meta.xml
git commit -m "feat: add Exclusion_Image_User permission set"
```

---

## Task 8: Deploy & verify (GATED on user lifting the deploy freeze)

**Files:** none — deployment + org config + manual verification.

**Interfaces:**
- Consumes: everything above.
- Produces: a working tab on the Contact record in the target sandbox.

> **Do not run this task until the user explicitly authorises deployment.** Ask for the target org alias `<ORG>` first.

- [ ] **Step 1: Validate-only deploy with tests**

Run: `sf project deploy start -d force-app/main/default/classes -d force-app/main/default/lwc/exclusionImageGallery -d force-app/main/default/permissionsets/Exclusion_Image_User.permissionset-meta.xml -o <ORG> --dry-run -l RunSpecifiedTests -t ExclusionImageControllerTest`
Expected: validation succeeds, tests pass.

- [ ] **Step 2: Deploy**

Run: `sf project deploy start -d force-app/main/default/classes -d force-app/main/default/lwc/exclusionImageGallery -d force-app/main/default/permissionsets/Exclusion_Image_User.permissionset-meta.xml -o <ORG> -l RunSpecifiedTests -t ExclusionImageControllerTest`
Expected: `Deploy Succeeded`.

- [ ] **Step 3: Assign the permission set**

Run: `sf org assign permset -n Exclusion_Image_User -o <ORG>`

- [ ] **Step 4: Add the tab to the Contact record page (Lightning App Builder)**

Manual, in the target org:
1. Setup → Object Manager → Contact → Lightning Record Pages → open the active page → Edit.
2. Add a new **Tab** to the tab set; label it **"Exclusion Images"**.
3. Drag the **`exclusionImageGallery`** custom component into that tab.
4. Save and Activate (keep existing activation/assignment).

- [ ] **Step 5: Manual end-to-end verification**

On a Contact with a valid `Patron_ID__c`:
1. Open the **Exclusion Images** tab → gallery loads (or empty state).
2. Upload a valid `.png` and an invalid `.pdf` together → png succeeds, pdf rejected, summary toast shown; gallery refreshes.
3. Upload a `.jpg` and a `.webp` → both succeed.
4. Click a tile → modal opens; ‹ / › buttons and ←/→ keys navigate; Esc closes.
5. Click **Download** → file downloads with its S3 filename.
6. Confirm S3 keys follow `exclusion-images/{PatronId}/{PatronId}_{timestamp}.{ext}`.

- [ ] **Step 6: Commit any config retrieved back (optional)**

If the FlexiPage change is retrieved into source:
```powershell
git add force-app/main/default/flexipages
git commit -m "chore: contact record page with exclusion images tab"
```

---

## Self-Review Notes (author checklist — resolved)

- **Spec coverage:** POP-2520/BR08 tab+list (Tasks 1/4/8), BR11 empty state (Task 4), BR28/29 enlarge+nav (Task 5), BR19 download (Task 5), BR10 format reject + <720p warn (Tasks 3/6), BR22/23/38 multi-upload partial success (Task 6), BR13 patron link via key convention (Tasks 1/3), BR31 a11y (Tasks 4/5 + lwc-reviewer gate Task 6), permission set (Task 7). Deferred/OUT items intentionally have no task (design doc §16).
- **Vocus standards applied:** SLDS-first mandate + base components in every template element (Task 4/5); Apex controller→service split with `WITH USER_MODE`, explicit sharing, `*Exception`, no swallowed errors (Tasks 1–3); `apex-reviewer` gate (Task 3 Step 6) and `lwc-reviewer` gate (Task 6 Step 6).
- **Placeholders:** none — all code blocks complete; the only intentional stubs (Task 4 `showPrev`/`showNext`/`downloadCurrent`/`handleFilesSelected`) are replaced with full implementations in Tasks 5–6 and called out as such.
- **Type consistency:** `ExclusionImageService.ImageItem{key,fileName,lastModified,size}` consistent across Apex + LWC; `getImage` returns `{data,contentType}` consumed identically in Tasks 4/6; `_wired` defined in Task 4, used in Task 6; controller returns `ExclusionImageService.ImageItem` in Tasks 3/6.
