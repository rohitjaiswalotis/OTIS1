trigger FS_WorkOrderTrigger on WorkOrder (before insert, before update, after insert, after update) {
    TriggerDispatcher.run(new FS_WorkOrderTriggerHandler(), WorkOrder.getSObjectType().getDescribe().getName());
}