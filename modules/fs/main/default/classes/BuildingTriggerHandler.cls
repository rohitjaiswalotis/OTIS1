/*
Created by - Existing
LastModified By - Cognizant
LastModified On - 6/2/2024
US#951659.This handler class is created for building trigger functionality.Cognizant team has used afterInsert,afterUpdate,afterDelete
  method to provide access to the office members using UpdateAccessDataOnBranch class
*/
public with sharing class BuildingTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(List<SObject> newList){
        UTIL_RecordOwner.changeOwnerToGBO(newList, null, 'BranchName__c');
        BuildingTriggerService.setBuildingAddressField(newList);
        BuildingTriggerService.setGBONameField(newList);
        BuildingTriggerService.setTimeZoneField(newList, null);
    }
    //US#951659.this will be used for location sharing to office members.
    public override void afterInsert(List<SObject> newList,Map<Id, SObject> newMap)
    {
        UpdateAccessDataOnBranch.updateBuildingDetails(newList,'Insert'); 
    }
    
    
    
    public override void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        UTIL_RecordOwner.changeOwnerToGBO(newMap.values(), oldMap, 'BranchName__c');
        BuildingTriggerService.setBuildingAddressField(newMap.values());
        BuildingTriggerService.setDateLastUpdatedField(newMap.values(), (Map<Id, Schema.Location>) oldMap);
        BuildingTriggerService.setGBONameField(newMap.values(), (Map<Id, Schema.Location>) oldMap);
        BuildingTriggerService.setTimeZoneField(newMap.values(), (Map<Id, Schema.Location>) oldMap);
    }
    
    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        //US#951659.this will be used for location sharing to office members.
        UpdateAccessDataOnBranch.updateBuildingDetails(trigger.new,'Insert'); 
        this.setMaxLoopCount(1);
        if (!new PackageUtilities().isJapanLocalization()) {
            BuildingTriggerService.syncBuildingsWithSameBuildingNumber(newMap.values(), (Map<Id, Schema.Location>) oldMap);
        }
    }
    
    //US#951659.this will be used for location sharing to office members.
    public override void afterDelete(Map<Id, SObject> oldMap)
    {
        UpdateAccessDataOnBranch.updateBuildingDetails(trigger.old,'Delete'); 
    }
}