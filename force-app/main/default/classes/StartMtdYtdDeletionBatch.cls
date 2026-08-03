@RestResource(urlMapping='/StartMtdYtdDeletionBatch/*')
global with sharing class StartMtdYtdDeletionBatch 
{
  @HttpGet
  global static void StartDeletion()
  {
    DeleteAllMtdYtdRecords batchDelete = new DeleteAllMtdYtdRecords();
    Database.executeBatch(batchDelete);
  }
}