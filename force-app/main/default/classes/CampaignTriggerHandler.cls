public class CampaignTriggerHandler extends TriggerHandlerBase //extending the trigger framework
{

    static final String APEXCLASSNAME = 'CampaignTriggerHandler';
    static final String COMPONENTTYPE = 'Apex Class';

    //new method which is required when we extend the TriggerHandlerBase class
    public CampaignTriggerHandler(String triggerName) {
    	super(triggerName);
    }

    //overriden methods from trigger framework base class
    public override void beforeInsert(List<SObject> tempNewCampaignList){


        List<Campaign> newCampaignList = (List<Campaign>)tempNewCampaignList;

        String timezone;
        for(Campaign camp: newCampaignList){
            if(camp.Event_Start_Date_Time__c != null && camp.Event_End_Date_Time__c != null){
                timezone = (camp.Timezone__c != null) ? camp.Timezone__c : '';
                camp.Static_Start_Date_Time__c = camp.Event_Start_Date_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                camp.Static_End_Date_Time__c = camp.Event_End_Date_Time__c.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
            }
        }
    }
    
    public override void beforeUpdate(List<SObject> tempOldCampaignList, List<SObject> tempNewCampaignList, Map<Id, SObject> tempOldCampMap, Map<Id, SObject> tempNewCampMap){
        String timezone;

        List<Campaign> newCampaignList = (List<Campaign>)tempNewCampaignList;
        Map<Id, Campaign> newCampMap = (Map<Id, Campaign>)tempNewCampMap;
        Map<Id, Campaign> oldCampMap = (Map<Id, Campaign>)tempOldCampMap;

        for(Campaign camp: newCampaignList){
            if(camp.Event_Start_Date_Time__c != null && camp.Event_End_Date_Time__c != null){
                timezone = (camp.Timezone__c != null) ? camp.Timezone__c : '';
                Datetime newStartDate = newCampMap.get(camp.Id).Event_Start_Date_Time__c;
                Datetime newEndDate = newCampMap.get(camp.Id).Event_End_Date_Time__c;
                String newTimezone = newCampMap.get(camp.Id).Timezone__c;
                
                Datetime oldStartDate = oldCampMap.get(camp.Id).Event_Start_Date_Time__c;
                Datetime oldEndDate = oldCampMap.get(camp.Id).Event_End_Date_Time__c;
                String oldTimezone = oldCampMap.get(camp.Id).Timezone__c;
                
                if(newStartDate != oldStartDate || newEndDate != oldEndDate || newTimezone != oldTimezone){
                    camp.Static_Start_Date_Time__c = newStartDate.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                    camp.Static_End_Date_Time__c = newEndDate.format('dd/MM/yyyy h:mm a') + ' ' + timezone;
                }
            }
        }
    }
}