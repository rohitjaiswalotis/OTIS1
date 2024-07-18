/*=======================================================================================================
Developed by - Cognizant
Created date - 27/06/2024
LastModified On - 08/07/2024
LastModified By - Aditya Kannaujia
Description: This class is used to call Trigger Handler for all Expense record events.
==========================================================================================================*/
public without sharing class FSL_ExpenseTriggerHandler extends TriggerHandler {

    public override void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        FSL_ExpenseHandlerService.aggregateExpenseOnWorkOrder(newList);
        FSL_ExpenseHandlerService.createExpenseShareRecord(newList);
    }

    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        FSL_ExpenseHandlerService.aggregateExpenseOnWorkOrder(newMap.values());
    }

}