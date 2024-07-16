/*
Created by - Cognizant
LastModified By - Cognizant
LastModified On - 6/2/2024
US#951659.This handler class is created for member trigger functionality.Cognizant team has used afterInsert,afterUpdate,afterDelete
  method to provide access to the office members using UpdateAccessDataOnBranch class
*/
public with sharing class MemberTriggerHandler extends TriggerHandler {
    public override void afterInsert(List<SObject> newList,Map<Id, SObject> newMap){
                UpdateAccessDataOnBranch.updateMemberDetails(newList,'Insert'); 

    }
    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
                UpdateAccessDataOnBranch.updateMemberDetails(trigger.new,'Insert'); 

    }
    public override void afterDelete(Map<Id, SObject> oldMap){
                UpdateAccessDataOnBranch.updateMemberDetails(trigger.old,'Delete'); 

    }
    
}