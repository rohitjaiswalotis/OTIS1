public class OfficeTriggerhandler  extends TriggerHandler
{
    public override void beforeInsert(List<SObject> newList){
        UTIL_RecordOwner.changeOwnerToGBO(newList, null, 'GBO__c');
        OfficeTriggerService.populateOfficeHierarchy(newList,null);
        OfficeTriggerService.setGbo((List<Branch__c>) newList, null);
    }

    public override void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        UTIL_RecordOwner.changeOwnerToGBO(newMap.values(), oldMap, 'GBO__c');
        OfficeTriggerService.populateOfficeHierarchy(newMap.values(), (Map<Id, Branch__c>)oldMap);
        OfficeTriggerService.setGbo((List<Branch__c>) newMap.values(), (Map<Id, Branch__c>) oldMap);
        OfficeTriggerService.populateLastUpdatedDate((List<Branch__c>) newMap.values(), (Map<Id, Branch__c>) oldMap);
    }

    public override void afterUpdate(Map<Id, SObject> newMap,Map<Id, SObject> oldMap){
        OfficeTriggerService.populateChildHierarchyRecords((Map<Id,Branch__c>)newMap,(Map<Id, Branch__c>) oldMap);
    }

}