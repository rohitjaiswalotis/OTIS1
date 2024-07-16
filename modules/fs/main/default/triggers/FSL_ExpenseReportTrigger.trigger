trigger FSL_ExpenseReportTrigger on ExpenseReport(after insert) {
    TriggerDispatcher.fsl_run(new FSL_ExpenseReportTriggerHandler(),ExpenseReport.getSObjectType().getDescribe().getName());
}