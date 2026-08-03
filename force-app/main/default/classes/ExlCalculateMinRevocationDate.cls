public with sharing class ExlCalculateMinRevocationDate {

    @InvocableMethod(
        label='Calculate Minimum Revocation Date'
        description='Returns the minimum allowed revocation date using Salesforce Business Hours (21 business days). Business Hours records named "<Jurisdiction> Revocation Business Hours" must be configured in Setup with the relevant public holidays attached.'
    )
    public static List<Response> calculate(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response resp = new Response();
            try {
                String bhName = req.jurisdiction + ' Revocation Business Hours';
                List<BusinessHours> bhList = [
                    SELECT Id FROM BusinessHours
                    WHERE Name = :bhName AND IsActive = true
                    LIMIT 1
                ];

                if (bhList.isEmpty()) {
                    // Fallback: 30 calendar days if Business Hours not yet configured
                    resp.minRevocationDate = req.startDate.addDays(30);
                    resp.errorMessage = 'Business Hours not configured: ' + bhName
                        + '. Please create in Setup > Business Hours (Mon-Fri, 12am-11:59pm) and attach relevant public holidays.';
                } else {
                    // 21 business days expressed as ms of business time (assumes 8-hour working day in BH config)
                    Long msIn21BusinessDays = 21L * 8L * 60L * 60L * 1000L;
                    DateTime startDT = DateTime.newInstance(req.startDate, Time.newInstance(0, 0, 0, 0));
                    DateTime resultDT = BusinessHours.add(bhList[0].Id, startDT, msIn21BusinessDays);
                    resp.minRevocationDate = resultDT.date();
                }
            } catch (Exception ex) {
                resp.minRevocationDate = req.startDate != null ? req.startDate.addDays(30) : Date.today().addDays(30);
                resp.errorMessage = ex.getMessage();
            }
            responses.add(resp);
        }
        return responses;
    }

    public class Request {
        @InvocableVariable(label='Start Date (Work Order Created Date)' required=true)
        public Date startDate;

        @InvocableVariable(label='Jurisdiction (NSW or QLD)' required=true)
        public String jurisdiction;
    }

    public class Response {
        @InvocableVariable(label='Minimum Revocation Date')
        public Date minRevocationDate;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
}