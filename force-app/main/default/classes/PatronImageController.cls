/**
 * Fetches a patron image (base64) from the Patron Image API for a Contact.
 * Endpoint host comes from the "Patron_Image_API" Named Credential (dev/uat/prod swappable there).
 */
public with sharing class PatronImageController {

    private static final String ENDPOINT = 'callout:Patron_Image_API/patron/image';

    public class PatronImage {
        @AuraEnabled public String name;
        @AuraEnabled public String patronId;
        @AuraEnabled public String imageBase64;
    }

    @AuraEnabled
    public static PatronImage getPatronImage(Id contactId, String imageType) {
        PatronImage result = new PatronImage();
        if (contactId == null) {
            return result;
        }
        List<Contact> cons = [SELECT Name, Patron_ID__c FROM Contact WHERE Id = :contactId LIMIT 1];
        if (cons.isEmpty()) {
            return result;
        }
        result.name = cons[0].Name;
        if (String.isBlank(cons[0].Patron_ID__c)) {
            return result; // no patron id -> UI shows "No Image Available"
        }
        result.patronId = cons[0].Patron_ID__c;

        // Key + API version come from protected Custom Metadata (Patron_Image_Config.Default),
        // so they are configurable per environment and not hard-coded in Apex.
        Patron_Image_Config__mdt cfg = Patron_Image_Config__mdt.getInstance('Default');
        String apiKey  = cfg == null ? null : cfg.Api_Key__c;
        String version = (cfg != null && String.isNotBlank(cfg.Version__c)) ? cfg.Version__c : 'v2';
        // imageType: caller override wins; otherwise use the configured default from CMDT.
        String type = imageType;
        if (String.isBlank(type)) {
            type = (cfg != null && String.isNotBlank(cfg.Image_Type__c)) ? cfg.Image_Type__c : 'Photograph';
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('GET');
        req.setHeader('patronId', result.patronId);
        req.setHeader('imageType', type);
        req.setHeader('version', version);
        req.setHeader('x-seg-image-key', apiKey);
        req.setTimeout(120000);

        HttpResponse res = new Http().send(req);
        Integer status = res.getStatusCode();
        if (status == 200) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Object content = body.get('imageBase64Content');
            result.imageBase64 = content == null ? null : String.valueOf(content);
            return result;
        }
        // 404 = patron has no image on file: treat as "no image" (not an error).
        if (status == 404) {
            return result;
        }
        throw new AuraHandledException('Patron Image API returned ' + status + ' ' + res.getStatus());
    }
}