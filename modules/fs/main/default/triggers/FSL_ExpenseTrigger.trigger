trigger FSL_ExpenseTrigger on Expense (after insert,after update) {
    TriggerDispatcher.fsl_run(new FSL_ExpenseTriggerHandler(),Expense.getSObjectType().getDescribe().getName());
}