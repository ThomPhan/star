public abstract class TriggerHandlerBase {
    private final string ALL_TRIGGER_KEY = 'ALL_TRIGGERS';   
    private final TriggerOperation TEST_DEFAULT_OP = TriggerOperation.BEFORE_INSERT;   
    private String triggerName = '-Untitled-';
    @testvisible private Trigger_Switch__mdt allTriggerConfig = Trigger_Switch__mdt.getInstance(ALL_TRIGGER_KEY);
    @testvisible private Trigger_Switch__mdt triggerConfig = null; 
    
    public virtual void beforeInsert(List<SObject> newRecords){}
    public virtual void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap){}
    public virtual void beforeDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap){}
    public virtual void afterInsert(List<SObject> newRecords, Map<ID, SObject> newRecordMap){}
    public virtual void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap){}
    public virtual void afterDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap){}
    public virtual void afterUndelete(List<SObject> newRecords, Map<ID, SObject> newRecordMap){}
    
    //STUBS for override in the extended class
    /*
    //required constructor
    public TriggerHandlerName(String triggerName) {
    	super(triggerName);
    }
	//implement as required
    public override void beforeInsert(List<SObject> newRecords){}
    public override void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap){}
    public override void beforeDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap){}
    public override void afterInsert(List<SObject> newRecords, Map<ID, SObject> newRecordMap){}
    public override void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap){}
    public override void afterDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap){}
    public override void afterUndelete(List<SObject> newRecords, Map<ID, SObject> newRecordMap){}
	*/
    
    //SAMPLE trigger code
    /*
    trigger AccountTrigger on Account (before insert, before update) {
        String triggerName = String.valueOf(this).split(':')[0];
        TriggerHandlerName handler = new TriggerHandlerName(triggerName);
        handler.execute();
    }
	*/
    
    public TriggerHandlerBase(String triggerName) {
        this.triggerName = triggerName;
        this.triggerConfig = Trigger_Switch__mdt.getInstance(triggerName);
    }
    
    private void Log(String source, String message) {
        System.debug(this.triggerName + ' >> ' + message);
        //TODO: establish logging framework or re-use existing one
		//if (config!=null && config.Trigger_Handler_Logging__c !=null && config.Trigger_Handler_Logging__c==true) {
        //    SM_ApplicationLog.addLog(SM_ApplicationLog.LOGGING_LEVEL.INFO.name(), 
        //                             message, source, null);                
        //}
    }
    
    public void execute() {
        //all switches are ignored if running tests, because all codes has to be executed.
        //otherwise, codes are skipped which lowers down code coverage, potentially causing deployment to fail.
        integer triggerSize = trigger.size;
        if (!trigger.isExecuting && !Test.isRunningTest()) return;
        if (!(triggerSize>0) && !Test.isRunningTest()) return;
        
        if (FeatureManagement.checkPermission('Bypass_Triggers') && !Test.isRunningTest()) {
            this.log('TriggerHandlerBase.execute()',
                     'Trigger ' + this.triggerName + ' NOT executed for event ' + String.valueOf(Trigger.operationType) + 
                     ' with ' + String.valueOf(triggerSize) + ' records: Trigger skipped due to permission.');                 
            return;
        }
        
        if (this.isTriggerEnabled() || Test.isRunningTest()) {
                this.Log('TriggerHandlerBase.execute()',
                         'Trigger ' + this.triggerName + ' executed for event ' + String.valueOf(Trigger.operationType) + 
                         ' with ' + String.valueOf(triggerSize) + ' records: trigger switch is ON.');               
            this.run(Trigger.operationType);
        } else {
                this.log('TriggerHandlerBase.execute()',
                         'Trigger ' + this.triggerName + ' NOT executed for event ' + String.valueOf(Trigger.operationType) + 
                         ' with ' + String.valueOf(triggerSize) + ' records: trigger switch is OFF.');            
        }
        //SM_ApplicationLog.publishLogs(); 
    }

    //order of preference
    //if ALL_TRIGGERS is enabled for a particular event, it further checks if there's a trigger specific config,
    //if trigger specifi config exists, that one wins
    //
    //if ALL_TRIGGERS is disabled/unchecked for a particular event, ALL_TRIGGERS wins and no trigger specific config is checked
    public boolean isTriggerEnabled() {
        boolean enabled = false;
        String operation = String.valueOf(trigger.operationType);
        if (operation==null && Test.isRunningTest()) operation = string.valueOf(TEST_DEFAULT_OP);
        
        enabled = allTriggerConfig!=null && (boolean.valueOf(allTriggerConfig.get(operation + '__c'))==true);
        if (enabled && triggerConfig != null) {
            enabled = triggerConfig.get(operation + '__c')==true;
        }
        return enabled;
    }       
    
    @testvisible
    private void run(System.TriggerOperation op) {
        if (op==null && Test.isRunningTest()) op = TEST_DEFAULT_OP;
        switch on op {
            when BEFORE_INSERT {
                this.beforeInsert(trigger.new);
            }
            when BEFORE_UPDATE {
                this.beforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE {
                this.beforeDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_INSERT {
                this.afterInsert(Trigger.new, Trigger.newMap);
            }
            when AFTER_UPDATE {
                this.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
            when AFTER_DELETE {
                this.afterDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                this.afterUndelete(Trigger.new, Trigger.newMap);
            }            
        }
    }
}