/*=======================================================================================================
Developed by - Cognizant
Created date - 08/07/2024
Description: This class is used to call aggregateTimeEntriesOnWorkOrder method from FSL_TimeSheetEntryTriggerHandlerService class.
==========================================================================================================*/

public without sharing class FSL_TimeSheetEntryTriggerHandler extends TriggerHandler {

    public override void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        FSL_TimeSheetEntryTriggerHandlerService.aggregateTimeEntriesOnWorkOrder(newList);
    }

    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
         FSL_TimeSheetEntryTriggerHandlerService.aggregateTimeEntriesOnWorkOrder(newMap.values());
    }
    
    public override void beforeInsert(List<SObject> newList){
        FSL_TimeSheetEntryTriggerHandlerService.assignOriginalStartAndEndDate(newList);
    }
    
    public override void beforeUpdate(Map<Id,SObject> newMap, Map<Id,SObject> oldMap){
        FSL_TimeSheetEntryTriggerHandlerService.updateOriginalStartAndEndDate((Map<Id, TimeSheetEntry>)oldMap,newMap.values());
    }
}