/**
* Description : Work Order trigger. Executes under the context: Before and After of Insert, Update, delete and Undelete
* Author : Anubrata Sanyal
* Version : 01
* Created Date : 02-07-2024
*
*/
trigger FS_WorkOrderNewTrigger on WorkOrder (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.fsl_run(new FSL_WorkOrderHandler(), WorkOrder.getSObjectType().getDescribe().getName());
}