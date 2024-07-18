trigger FSL_TimesheetTrigger on TimeSheet (after insert) {
  TriggerDispatcher.fsl_run(new FSL_TimesheetTriggerHandler(), Schema.TimeSheet.getSObjectType().getDescribe().getName());  
}