trigger FSL_TimeSheetEntryTrigger on TimeSheetEntry (after insert,after update, before insert, before update) {
 TriggerDispatcher.fsl_run(new FSL_TimeSheetEntryTriggerHandler(),TimeSheetEntry.getSObjectType().getDescribe().getName());
}