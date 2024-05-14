/**=========================================================================================
@Description: Trigger Handler for all Work Order operations.
Trigger can process all Work Order records, excluding those with the "Classic CC" record type.
=========================================================================================*/
public without sharing class FS_WorkOrderTriggerHandler extends TriggerHandler {
    /*=========================================================================================
    Context Methods for Trigger Handler
    =========================================================================================*/

    public override void beforeInsert(List<SObject> newList) {

        List<WorkOrder> newWorkOrders = RecordTypeUtilities.filterRecordsByRecordTypeName(
            (List<WorkOrder>) newList, UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
        );

        if (newWorkOrders.isEmpty()) {
            return;
        }
    }

    public override void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {

        List<WorkOrder> newWorkOrdersList = RecordTypeUtilities.filterRecordsByRecordTypeName(
            (List<WorkOrder>) newList, UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
        );

        if (newWorkOrdersList.isEmpty()) {
            return;
        }

        Map<Id, WorkOrder> newWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
            )
        );
    }

    public override void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){

        Map<Id, WorkOrder> newWorkOrders = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
            )
        );

        if (newWorkOrders.isEmpty()) {
            return;
        }

        Map<Id, WorkOrder> oldWorkOrders = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) oldMap.values(), UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
            )
        );
    }

    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){

        Map<Id, WorkOrder> newWorkOrders = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
            )
        );

        if (newWorkOrders.isEmpty()) {
            return;
        }

        Map<Id, WorkOrder> oldWorkOrders = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) oldMap.values(), UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE, false
            )
        );
    }
}