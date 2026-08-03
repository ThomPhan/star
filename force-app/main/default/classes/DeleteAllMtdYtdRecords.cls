public class DeleteAllMtdYtdRecords implements Database.Batchable<SObject>
{
  public Database.QueryLocator start(Database.BatchableContext context)
  {
    return Database.getQueryLocator([select id from mtdytd_trend_data__c]);
  }
  public void execute(Database.BatchableContext context, mtdytd_trend_data__c[] scope) {
    delete scope;
  }
  public void finish(Database.BatchableContext context) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://prod-04.australiaeast.logic.azure.com:443/workflows/f0ddb4b64e5b4dc08bcece5297f31998/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=091E0SKgq1qd7GH4HaW_yWpejdpR65zYixv3wuXUYUM');
    req.setMethod('GET');
    Http http = new Http();
    HTTPResponse res = http.send(req);
  }
}