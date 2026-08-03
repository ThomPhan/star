@RestResource(urlMapping='/MergeApexTest/*')
global class MergeApexTest {
    
    @HttpPost
    global static void mergeAccount(){
        
        Account a = new Account();
        a.Name = 'test23113123';
        insert a;
        /*
        // Queries to get the inserted accounts 
        Account masterAcct = [SELECT Id, Name FROM Account WHERE Name = 'TestMerge1' LIMIT 1];
        Account mergeAcct = [SELECT Id, Name FROM Account WHERE Name = 'TestMerge2' LIMIT 1];
        
        // Add a contact to the account to be merged
        //Contact c = new Contact(FirstName='Joe',LastName='Merged');
        //c.AccountId = mergeAcct.Id;
        //insert c;
        
        try {
            merge masterAcct mergeAcct;
        } catch (DmlException e) {
            // Process exception
            System.debug('An unexpected error has occurred: ' + e.getMessage()); 
        }
*/
    }
}