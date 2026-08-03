/**
 * @description       : 
 * @author            : rhysjohn.delacruz@simplus.com
 * @group             : 
 * @last modified on  : 05-13-2021
 * @last modified by  : rhysjohn.delacruz@simplus.com
 * Modifications Log 
 * Ver   Date         Author                            Modification
 * 1.0   05-13-2021   rhysjohn.delacruz@simplus.com     Initial Version
**/

public class QuerySelectedTaskRecords{

    @InvocableMethod(label = 'Query Selected Task Records' description = 'Apex to Query the selected tasks records from Task list')
    public static void queryTaskRecords(List<Request> reqList){


    }

    public class Request {

        /*
         * Each @InvocableVariable defined in this class
         * is an input variable you can populate when calling
         * this from Process Builder or Flow.
         */

        @InvocableVariable(label = 'oldFieldValue')
        public String oldFieldValue;
        
        @InvocableVariable(label = 'newFieldValue')
        public String newFieldValue;

        @InvocableVariable(label = 'accRec')
        public Account accRec;
        
        @InvocableVariable(label = 'fieldLabel')
        public String fieldLabel;
        
        @InvocableVariable(label = 'queueName')
        public String queueName;
    }
}