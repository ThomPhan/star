public with sharing class Exl_SFEventToAzureService_PEBody {
    public class FlowInputWrapper {
        @InvocableVariable(required=true) public Exl_Exclusion__c exclusionRecord;
    }

    public class FlowOutputWrapper {
        @InvocableVariable public List<String> serialised_PE_PayLoads;
        @InvocableVariable public String error;
    }

    @InvocableMethod(
        label='returnPlatformEventBody'
        description='returnPlatformEventBody'
    )
    public static List<FlowOutputWrapper> returnPlatformEventBody(List<FlowInputWrapper> reqs) {
        List<FlowOutputWrapper> outs = new List<FlowOutputWrapper>();
        Map<String, String> sourceNameMap = new Map<String, String>{
            'The Star Sydney' => 'SC',
            'The Star Brisbane' => 'CT',
            'The Star Gold Coast' => 'CJ'
        };

        for (FlowInputWrapper req : reqs) {
            FlowOutputWrapper out = new FlowOutputWrapper();
            out.serialised_PE_PayLoads = new List<String>();

            try {
                Exl_Exclusion__c exclusionRecord = req.exclusionRecord;
                system.debug('exclusionRecord:: ' + exclusionRecord);

                // Fetch the linked patron
                Contact exlPatron = getExlPatron(exclusionRecord.Contact__c);
                if (exlPatron != null) {
                    Exl_PlatformEvent_JSONBody bodyWrapper = new Exl_PlatformEvent_JSONBody();
                    populateBodyWrapper(bodyWrapper, exclusionRecord, exlPatron, sourceNameMap);

                    // Serialize the payload and add to the list
                    out.serialised_PE_PayLoads.add(JSON.serialize(bodyWrapper));
                } else {
                    // Handle missing patron
                    out.error = 'Unexpected error: No Linked Patron Found';
                }
            } catch (Exception ex) {
                // Log the exception and return a generic error
                System.debug(LoggingLevel.ERROR, 'Error in processing exclusion record: ' + ex.getMessage());
                out.error = 'Unexpected error: ' + ex.getMessage();
            }

            outs.add(out);
        }

        return outs;
    }

    private static void populateBodyWrapper(
        Exl_PlatformEvent_JSONBody bodyWrapper,
        Exl_Exclusion__c exclusionRecord,
        Contact exlPatron,
        Map<String, String> sourceNameMap
    ) {
        bodyWrapper.surname = exlPatron.LastName;
        bodyWrapper.firstName = exlPatron.FirstName;
        bodyWrapper.dob = exlPatron.Date_of_Birth__c;

        bodyWrapper.exclusionNumber = exclusionRecord.Name;
        bodyWrapper.exclusionReason = exclusionRecord.Behaviour__c;

        bodyWrapper.poeType = exclusionRecord.POE_Type__c;
        bodyWrapper.poeTypeID = getPOETypeId(exclusionRecord.POE_Type__c, exclusionRecord.Jurisdiction__c);
        bodyWrapper.poeLength = exclusionRecord.POE_Length__c;

        bodyWrapper.isExcluded = isExclusionPendingOrFailed(exclusionRecord.Status__c);
        bodyWrapper.sourceName = sourceNameMap.get(exclusionRecord.Property__c);

        bodyWrapper.issuedDate = exclusionRecord.Start_Date__c;
        bodyWrapper.accountIssuedDate = exclusionRecord.Start_Date__c;

        bodyWrapper.revocationDate = exclusionRecord.Revocation_Date__c;
        bodyWrapper.accountRevocationDate = exclusionRecord.Revocation_Date__c;

        bodyWrapper.excBySourceName = exlPatron.Id; // Repurposed to use for sourceSystemId i.e. Patron Salesforce Record Id.
    }

    private static Boolean isExclusionPendingOrFailed(String status) {
        return status == 'Exclusion Pending' || status == 'Activation Failed';
    }

    private static String getPOETypeId(String pOETypeStr, String stateStr) {
        if (String.isBlank(pOETypeStr)) {
            return null;
        }
        String POETypeIDstr = '';

        List<Exl_POEType_ID_Mapping__mdt> pOEIdMdts = [
            SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, SystemModstamp,
                   POE_Type__c, POEType_Id__c, Jurisdiction__c, POE_Type__r.Label
            FROM Exl_POEType_ID_Mapping__mdt
        ];

        if (!pOEIdMdts.isEmpty()) {
            for (Exl_POEType_ID_Mapping__mdt poeMdtRec : pOEIdMdts) {
                if (poeMdtRec.POE_Type__c != null
                    && !String.isBlank(poeMdtRec.POE_Type__r.Label) && poeMdtRec.POE_Type__r.Label == pOETypeStr
                    && !String.isBlank(poeMdtRec.Jurisdiction__c) && poeMdtRec.Jurisdiction__c == stateStr) {
                    POETypeIDstr = poeMdtRec.POEType_Id__c;
                }
            }
        }

        return POETypeIDstr;
    }

    private static Contact getExlPatron(Id patronId) {
        return [SELECT Id, FirstName, LastName, Date_of_Birth__c FROM Contact WHERE Id = :patronId];
    }
}