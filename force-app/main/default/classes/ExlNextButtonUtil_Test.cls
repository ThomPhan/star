@IsTest(seeAllData=false)
private class ExlNextButtonUtil_Test {

    // ---- tiny helper to call the invocable cleanly
    private static ExlNextButtonUtil.FlowOutputWrapper callUtil(Id caseId, Id WoliId) {
        List<ExlNextButtonUtil.FlowInputWrapper> inList = new List<ExlNextButtonUtil.FlowInputWrapper>();
        ExlNextButtonUtil.FlowInputWrapper in1 = new ExlNextButtonUtil.FlowInputWrapper();
        in1.caseId = (String)caseId;
        in1.wOLIId = (String)WoliId;
        inList.add(in1);

        List<ExlNextButtonUtil.FlowOutputWrapper> out = ExlNextButtonUtil.updateCaseAndReturn(inList);
        System.assertEquals(1, out.size(), 'Expect exactly one output');
        return out[0];
    }
	
    @IsTest
    static void test_NullInput() {
         ExlNextButtonUtil.FlowOutputWrapper o0 = callUtil(null, null);
    }
    @IsTest
    static void test_fullJourney_common_to_close_Qld() {
        // ---------------------------------------------
        // Data setup (Property = Brisbane → origin=QLD, replicate=NSW)
        // ---------------------------------------------
        Case c = new Case(
            Status = 'New',
            Property__c = 'The Star Brisbane',          // origin = QLD
            Exl_Nextbutton_NSW__c = 'Open Rating Status', 
            Exl_Nextbutton_Qld__c = 'Open Rating Status',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Exl_Apply_Contravention').getRecordTypeId()
        );
        insert c;

        // COMMON WorkOrder (BOTH)
        WorkOrder woCommon = new WorkOrder(
            CaseId = c.Id,
            Jurisdiction__c = '',                  // treated as COMMON
            IsButton__c = true,                        // WO-level button
            WorkOrderType__c = 'Open Rating Status',
            Status = 'Open'
        );
        insert woCommon;

        // QLD WorkOrder (origin)
        WorkOrder woQld = new WorkOrder(
            CaseId = c.Id,
            Jurisdiction__c = 'QLD',
            IsButton__c = false,
            WorkOrderType__c = 'QLD Phase',
            Status = 'Not Started'
        );
        insert woQld;

        // NSW WorkOrder (replicate)
        WorkOrder woNsw = new WorkOrder(
            CaseId = c.Id,
            Jurisdiction__c = 'NSW',
            IsButton__c = false,
            WorkOrderType__c = 'NSW Phase',
            Status = 'Not Started'
        );
        insert woNsw;

        // QLD WOLIs (in CreatedDate/Id order)
        WorkOrderLineItem woliQld1 = new WorkOrderLineItem(
            WorkOrderId = woQld.Id,
            Line_Item_Type__c = 'Start Form',
            IsButton__c = true,
            StartReplicatedState__c = false,
            Status = 'Open'
        );
        insert woliQld1;
        
		// QLD WOLIs (in CreatedDate/Id order)
        WorkOrderLineItem woliQld2 = new WorkOrderLineItem(
            WorkOrderId = woQld.Id,
            Line_Item_Type__c = 'Upload security Document',
            IsButton__c = true,
            StartReplicatedState__c = true,     // unlock replicate when completed
            Status = 'Open'
        );
        insert woliQld2;

        // NSW WOLIs (in CreatedDate/Id order)
        WorkOrderLineItem n1 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Capture Details',
            IsButton__c = true,
            StartReplicatedState__c = false,
            Status = 'Open'
        );
        insert n1;

        WorkOrderLineItem n2 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Generate security Document',
            IsButton__c = true,
            StartReplicatedState__c = false,
            Status = 'Open'
        );
        insert n2;

        WorkOrderLineItem n3 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Reconcile Security',
            IsButton__c = true,
            StartReplicatedState__c = true,
            Status = 'Open'
        );
        insert n3;

        WorkOrderLineItem n4 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Hand Over security Document',
            IsButton__c = true,
            StartReplicatedState__c = true,
            Status = 'Open'
        );
        insert n4;

        // ---------------------------------------------
        // Step 0: Common WO button is OPEN → both fields show common label
        // ---------------------------------------------
        Test.startTest();
        ExlNextButtonUtil.FlowOutputWrapper o0 = callUtil(c.Id, null);
        

        c = [SELECT Exl_Nextbutton_NSW__c, Exl_Nextbutton_Qld__c, Status FROM Case WHERE Id = :c.Id];
        System.debug('c.Exl_Nextbutton_NSW__c '+c.Exl_Nextbutton_NSW__c);
        System.assertEquals('Open Rating Status', c.Exl_Nextbutton_NSW__c, 'NSW should show common step');
        System.assertEquals('Open Rating Status', c.Exl_Nextbutton_Qld__c, 'QLD should show common step');
        System.assertEquals('Open', woCommon.Status, 'Common WO still Open');
        System.assertEquals(false, o0.caseClosed, 'Case should not be closed at start');

        // ---------------------------------------------
        // Step 1: Complete common WO; origin should start; replicate still locked
        // ---------------------------------------------
        woCommon.Status = 'Completed';
        update woCommon;

        
        ExlNextButtonUtil.FlowOutputWrapper o1 = callUtil(c.Id, null);
        
		
        System.debug('Step 1 completed : Open rating is completed ');
        System.assertEquals(null, o1.nextNSW, 'NSW should be null until replicate unlocks');
        System.assertEquals('Start Form', o1.nextQLD, 'QLD should pick first open WOLI');
        System.assertEquals(false, o1.caseClosed, 'Not closed yet');
		
        c.Exl_Nextbutton_NSW__c = o1.nextNSW;
        c.Exl_Nextbutton_Qld__c = o1.nextQLD;
        update c;
        
        // ---------------------------------------------
        // Step 2: Complete QLD Start Form; replicate still locked → QLD moves to next
        // ---------------------------------------------
        woliQld1.Status = 'Completed';
        update woliQld1;

        System.debug('Step 2 completed : WoliQld_1 is completed ');
        ExlNextButtonUtil.FlowOutputWrapper o2 = callUtil(c.Id, woliQld1.Id);
        System.assertEquals(null, o2.nextNSW, 'NSW still locked');
        System.assertEquals('Upload security Document', o2.nextQLD, 'QLD advances to next open WOLI');
        
        Test.stopTest();
        

        // ---------------------------------------------
        // Step 3: Complete QLD Upload security Document (flag=true) → unlock replicate
        // ---------------------------------------------
        woliQld2.Status = 'Completed';
        update woliQld2;

        
        ExlNextButtonUtil.FlowOutputWrapper o3 = callUtil(c.Id, woliQld2.Id);
        System.assertEquals('Capture Details', o3.nextNSW, 'NSW should now start');
        System.assertEquals(null, o3.nextQLD, 'QLD has no more open WOLIs');
        c.Exl_Nextbutton_NSW__c = o3.nextNSW;
        c.Exl_Nextbutton_Qld__c = o3.nextQLD;
        update c;
        

        // ---------------------------------------------
        // Step 4: Complete NSW Capture Details → NSW moves to Generate
        // ---------------------------------------------
        n1.Status = 'Completed';
        update n1;

        
        ExlNextButtonUtil.FlowOutputWrapper o4 = callUtil(c.Id, n1.Id);
        System.assertEquals('Generate security Document', o4.nextNSW, 'NSW advances to Generate');
        System.assertEquals(null, o4.nextQLD);
	c.Exl_Nextbutton_NSW__c = o4.nextNSW;
        c.Exl_Nextbutton_Qld__c = o4.nextQLD;
        update c;
        
        // ---------------------------------------------
        // Step 5: Complete NSW Generate → NSW moves to Reconcile
        // ---------------------------------------------
        n2.Status = 'Completed';
        update n2;

        
        ExlNextButtonUtil.FlowOutputWrapper o5 = callUtil(c.Id, n2.Id);
        System.assertEquals('Reconcile Security', o5.nextNSW, 'NSW advances to Reconcile');
        System.assertEquals(null, o5.nextQLD);
	c.Exl_Nextbutton_NSW__c = o5.nextNSW;
        c.Exl_Nextbutton_Qld__c = o5.nextQLD;
        update c;
        
        // ---------------------------------------------
        // Step 6: Complete NSW Reconcile → NSW moves to Hand Over
        // ---------------------------------------------
        n3.Status = 'Completed';
        update n3;

        
        ExlNextButtonUtil.FlowOutputWrapper o6 = callUtil(c.Id, n3.Id);
        System.assertEquals('Hand Over security Document', o6.nextNSW, 'NSW advances to Hand Over');
        System.assertEquals(null, o6.nextQLD);
		
        c.Exl_Nextbutton_NSW__c = o6.nextNSW;
        c.Exl_Nextbutton_Qld__c = o6.nextQLD;
        update c;
        
        
        // ---------------------------------------------
        // Step 7: Complete NSW Hand Over → all done → Case closes
        // ---------------------------------------------
        n4.Status = 'Completed';
        update n4;

        
        ExlNextButtonUtil.FlowOutputWrapper o7 = callUtil(c.Id, n4.Id);
        System.assertEquals(null, o7.nextNSW,  'NSW should be null once done');
        System.assertEquals(null, o7.nextQLD,  'QLD already null');
        System.assertEquals(true, o7.caseClosed, 'Output should reflect closed=true');
        System.assertEquals(null, o7.error, 'No errors expected');
        c.Exl_Nextbutton_NSW__c = o7.nextNSW;
        c.Exl_Nextbutton_Qld__c = o7.nextQLD;
        update c;
        
    }
    
    
   
    @IsTest
    static void test_fullJourney_common_to_close_NSW() {
        // ---------------------------------------------
        // Data setup (Property = Brisbane → origin=QLD, replicate=NSW)
        // ---------------------------------------------
        Case c = new Case(
            Status = 'New',
            Property__c = 'the star sydney',          // origin = QLD
            Exl_Nextbutton_NSW__c = 'Open Rating Status', 
            Exl_Nextbutton_Qld__c = 'Open Rating Status',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Exl_Apply_Contravention').getRecordTypeId()
        );
        insert c;

        // COMMON WorkOrder (BOTH)
        WorkOrder woCommon = new WorkOrder(
            CaseId = c.Id,
            Jurisdiction__c = '',                  // treated as COMMON
            IsButton__c = true,                        // WO-level button
            WorkOrderType__c = 'Open Rating Status',
            Status = 'Open'
        );
        insert woCommon;

        // QLD WorkOrder (origin)
        WorkOrder woQld = new WorkOrder(
            CaseId = c.Id,
            Jurisdiction__c = 'QLD',
            IsButton__c = false,
            WorkOrderType__c = 'QLD Phase',
            Status = 'Not Started'
        );
        insert woQld;

        // NSW WorkOrder (replicate)
        WorkOrder woNsw = new WorkOrder(
            CaseId = c.Id,
            Jurisdiction__c = 'NSW',
            IsButton__c = false,
            WorkOrderType__c = 'NSW Phase',
            Status = 'Not Started'
        );
        insert woNsw;

        // QLD WOLIs (in CreatedDate/Id order)
        WorkOrderLineItem woliQld1 = new WorkOrderLineItem(
            WorkOrderId = woQld.Id,
            Line_Item_Type__c = 'Start Form',
            IsButton__c = true,
            StartReplicatedState__c = false,
            Status = 'Open'
        );
        insert woliQld1;

        WorkOrderLineItem q2 = new WorkOrderLineItem(
            WorkOrderId = woQld.Id,
            Line_Item_Type__c = 'Upload security Document',
            IsButton__c = true,
            StartReplicatedState__c = true,     // unlock replicate when completed
            Status = 'Open'
        );
        insert q2;

        // NSW WOLIs (in CreatedDate/Id order)
        WorkOrderLineItem n1 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Capture Details',
            IsButton__c = true,
            StartReplicatedState__c = false,
            Status = 'Open'
        );
        insert n1;

        WorkOrderLineItem n2 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Generate security Document',
            IsButton__c = true,
            StartReplicatedState__c = false,
            Status = 'Open'
        );
        insert n2;

        WorkOrderLineItem n3 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Reconcile Security',
            IsButton__c = true,
            StartReplicatedState__c = true,
            Status = 'Open'
        );
        insert n3;

        WorkOrderLineItem n4 = new WorkOrderLineItem(
            WorkOrderId = woNsw.Id,
            Line_Item_Type__c = 'Hand Over security Document',
            IsButton__c = true,
            StartReplicatedState__c = true,
            Status = 'Open'
        );
        insert n4;

        
        Test.startTest();
        ExlNextButtonUtil.FlowOutputWrapper o0 = callUtil(c.Id, null);
        

        c = [SELECT Exl_Nextbutton_NSW__c, Exl_Nextbutton_Qld__c, Status FROM Case WHERE Id = :c.Id];
        System.debug('c.Exl_Nextbutton_NSW__c '+c.Exl_Nextbutton_NSW__c);
        System.assertEquals('Open Rating Status', c.Exl_Nextbutton_NSW__c, 'NSW should show common step');
        System.assertEquals('Open Rating Status', c.Exl_Nextbutton_Qld__c, 'QLD should show common step');
        System.assertEquals('Open', woCommon.Status, 'Common WO still Open');
        System.assertEquals(false, o0.caseClosed, 'Case should not be closed at start');

        woCommon.Status = 'Completed';
        update woCommon;

        
        ExlNextButtonUtil.FlowOutputWrapper o1 = callUtil(c.Id, null);
        Test.stopTest();
		
        System.debug('Step 1 completed : Arth');
        System.assertEquals(null, o1.nextQLD, 'Qld should be null until replicate unlocks');
        System.assertEquals('Capture Details', o1.nextNSW, 'NSW should pick first open WOLI');
        System.assertEquals(false, o1.caseClosed, 'Not closed yet');
		
        c.Exl_Nextbutton_NSW__c = o1.nextNSW;
        c.Exl_Nextbutton_Qld__c = o1.nextQLD;
        update c;
        
        woliQld1.Status = 'Completed';
        update woliQld1;

        
        ExlNextButtonUtil.FlowOutputWrapper o2 = callUtil(c.Id, woliQld1.Id);
        System.assertEquals(null, o2.nextQLD, 'NSW still locked');
	c.Exl_Nextbutton_NSW__c = o2.nextNSW;
        c.Exl_Nextbutton_Qld__c = o2.nextQLD;
        update c;
        
        n1.Status = 'Completed';
        update n1;

        
        ExlNextButtonUtil.FlowOutputWrapper o4 = callUtil(c.Id, n1.Id);
        System.assertEquals('Generate security Document', o4.nextNSW, 'NSW advances to Generate');
        System.assertEquals(null, o4.nextQLD);
	c.Exl_Nextbutton_NSW__c = o4.nextNSW;
        c.Exl_Nextbutton_Qld__c = o4.nextQLD;
        update c;
        n2.Status = 'Completed';
        update n2;

        
        ExlNextButtonUtil.FlowOutputWrapper o5 = callUtil(c.Id, n2.Id);
        System.assertEquals('Reconcile Security', o5.nextNSW, 'NSW advances to Reconcile');
        System.assertEquals(null, o5.nextQLD);
	c.Exl_Nextbutton_NSW__c = o5.nextNSW;
        c.Exl_Nextbutton_Qld__c = o5.nextQLD;
        update c;
       	n3.Status = 'Completed';
        update n3;

        
        ExlNextButtonUtil.FlowOutputWrapper o6 = callUtil(c.Id, n3.Id);
        System.assertEquals('Hand Over security Document', o6.nextNSW, 'NSW advances to Hand Over');
        System.assertEquals('Upload security Document', o6.nextQLD);
	c.Exl_Nextbutton_NSW__c = o6.nextNSW;
        c.Exl_Nextbutton_Qld__c = o6.nextQLD;
        update c;
        
        n4.Status = 'Completed';
        update n4;
        
        q2.Status = 'Completed';
		update q2;
        
        ExlNextButtonUtil.FlowOutputWrapper o7 = callUtil(c.Id, n4.Id);
        System.assertEquals(null, o7.nextNSW,  'NSW should be null once done');
        System.assertEquals(null, o7.error, 'No errors expected');
        c.Exl_Nextbutton_NSW__c = o7.nextNSW;
        c.Exl_Nextbutton_Qld__c = o7.nextQLD;
        update c;
    }
}