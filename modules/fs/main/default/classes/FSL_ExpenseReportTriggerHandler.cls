/**=========================================================================================
@Description: Trigger Handler for all Expense Report record events.
=========================================================================================*/
public without sharing class FSL_ExpenseReportTriggerHandler extends TriggerHandler {
	
	/**
	* After Insert
	*/
	public override void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        FSL_ExpenseReportTriggerHandlerService.createExpenseReportShare(newList);
    }
}