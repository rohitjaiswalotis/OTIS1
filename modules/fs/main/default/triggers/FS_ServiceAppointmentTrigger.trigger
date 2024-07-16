/**
* Description : Service Appointment trigger. Executes under the context: Before and After of Insert, Update, delete and Undelete
* Author : Debjyoti Munshi
* Version : 01
* Created Date : 12-06-2024
*/
trigger FS_ServiceAppointmentTrigger on ServiceAppointment (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.fsl_run(new FSL_ServiceAppointmentHandler(), ServiceAppointment.getSObjectType().getDescribe().getName());
}