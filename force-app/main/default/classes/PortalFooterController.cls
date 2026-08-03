public class PortalFooterController {
    @AuraEnabled
    public static Portal_Footer_Message__mdt getFooterMessages(String location) {
        Portal_Footer_Message__mdt message = new Portal_Footer_Message__mdt();
        try{
           message = [Select Id,Address__c,Legal_Statement__c from Portal_Footer_Message__mdt where Location__c =: location LIMIT 1]; 
        }catch (Exception e){
			//execute the Error Logger object
			ErrorLogger.createLog('PortalFooterController', 'getFooterMessages', e, '', 'Apex Class');
		}
        return message;
    }

    @AuraEnabled
    public static Map<String,Map<String,List<Portal_Footer_Links__mdt>>> getFooterLinks(String location) {
        Map<String,List<Portal_Footer_Links__mdt>> sectionMap = new Map<String,List<Portal_Footer_Links__mdt>>();
        Map<String,Map<String,List<Portal_Footer_Links__mdt>>> sectionListMap = new Map<String,Map<String,List<Portal_Footer_Links__mdt>>>();
        Set<Integer> iSet = new Set<Integer>();
        try{
            List<Portal_Footer_Links__mdt> links = [Select Id,Link_Icon__c,Link_Name__c,Link_Order__c,Link_URL__c,Location__c,Section_Name__c,Section_Order__c from Portal_Footer_Links__mdt where Location__c =: location ORDER BY Section_Order__c ASC, Link_Order__c ASC];
            for(Portal_Footer_Links__mdt l : links){
                iSet.add(Integer.ValueOf(l.Section_Order__c));
            }

            for(Integer i : iSet){
                sectionMap = new Map<String,List<Portal_Footer_Links__mdt>>();
                for(Portal_Footer_Links__mdt link : links){
                    if(link.Section_Order__c == i){
                        if(sectionMap.get(String.ValueOf(link.Section_Name__c)) != null){
                            sectionMap.get(String.ValueOf(link.Section_Name__c)).add(link);
                        }else{
                            List<Portal_Footer_Links__mdt> lnks = new List<Portal_Footer_Links__mdt>();
                            lnks.add(link);
                            sectionMap.put(String.ValueOf(link.Section_Name__c),lnks);
                        }
                    }
                }
                sectionListMap.put(String.ValueOf(i),sectionMap);
            }
        }catch (Exception e){
			//execute the Error Logger object
			ErrorLogger.createLog('PortalFooterController', 'getFooterLinks', e, '', 'Apex Class');
		}
        
        

        return sectionListMap;
    }
}