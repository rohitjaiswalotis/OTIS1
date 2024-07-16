trigger OfficeTrigger on Branch__c (before insert, before update, after update) {
    TriggerDispatcher.run(new OfficeTriggerHandler(), Branch__c.getSObjectType().getDescribe().getName());
}