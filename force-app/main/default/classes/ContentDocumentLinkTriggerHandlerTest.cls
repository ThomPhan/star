/**
 * @description       : Test class for ContentDocumentLink
 * @author            : Simplus
 * @group             : Simplus
 * @last modified by  : Simplus
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   12-09-2023   Simplus                      Initial Version
 */
@isTest
public class ContentDocumentLinkTriggerHandlerTest {
    
    @isTest
    static void testAddContentDocument(){

        Contact c = new Contact();
        c.FirstName = 'Test FName';
        c.LastName = 'Test LName';
        insert c;

        ContentVersion content=new ContentVersion(); 
        content.Title='Test'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('ContentVersion'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = c.Id;
        contentlink.contentdocumentid = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        
        insert contentlink;

    }
}