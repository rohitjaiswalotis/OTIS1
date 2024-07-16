/*
    Created by - Cognizant 
    LastModified On - 5/2/2024
   US#951659. updateAccessDataOnBranch.updateBuildingDetails is used to attach the Id of member(related user of member object)  which is created or deleted under the related office record.
    Field used to store Id of Member in the Json format - Member Access
    */

trigger MemberTrigger on BranchMemberRole__c (after update ,after insert, after Delete) {
  TriggerDispatcher.run(new MemberTriggerHandler(), BranchMemberRole__c.getSObjectType().getDescribe().getName());  
}