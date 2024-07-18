/*=======================================================================================================
Developed by - Cognizant
Created date - 08/07/2024
Description: This class is used to aggregate DurationInMinutes field on Expense record and update it on TotalTimeSpentMins__c on WO.
========================================================================================================*/
public inherited sharing class FSL_TimeSheetEntryTriggerHandlerService {
    
    // List of allowed Work Order Record Types
    public static final List<String> ALLOWED_WO_RECORD_TYPES = new List<String>{
        FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT, 
        FSLConstantClass.WORK_ORDER_MAINTENANCE_RT
    };

    /**
     * Aggregates the DurationInMinutes field from TimeSheetEntry records
     * and updates the TotalTimeSpentMins__c field on the related WorkOrder.
     *
     * @param timeSheetEntries List of TimeSheetEntry records to process.
     */
    public static void aggregateTimeEntriesOnWorkOrder(List<TimeSheetEntry> timeSheetEntries) {
        try {
            Set<Id> workOrderIds = new Set<Id>();
            Map<Id, Integer> workOrderTimeMap = new Map<Id, Integer>();

            // Collect Work Order IDs and aggregate DurationInMinutes
            for (TimeSheetEntry entry : timeSheetEntries) {
                if (entry.WorkOrderId != null && entry.DurationInMinutes != null) {
                    workOrderIds.add(entry.WorkOrderId);
                    if (!workOrderTimeMap.containsKey(entry.WorkOrderId)) {
                        workOrderTimeMap.put(entry.WorkOrderId, 0);
                    }
                    workOrderTimeMap.put(entry.WorkOrderId, workOrderTimeMap.get(entry.WorkOrderId) + entry.DurationInMinutes);
                }
            }

            // Fetch Work Orders to update
            List<WorkOrder> workOrders = [
                SELECT Id, TotalTimeSpentMins__c 
                FROM WorkOrder 
                WHERE Id IN :workOrderIds AND RecordType.DeveloperName IN :ALLOWED_WO_RECORD_TYPES
            ];

            // Update TotalTimeSpentMins__c on each Work Order
            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            for (WorkOrder wo : workOrders) {
                if (workOrderTimeMap.containsKey(wo.Id)) {
                    Integer newTotalTimeSpent = workOrderTimeMap.get(wo.Id);
                    if (wo.TotalTimeSpentMins__c == null) {
                        wo.TotalTimeSpentMins__c = 0;
                    }
                    wo.TotalTimeSpentMins__c += newTotalTimeSpent;
                    workOrdersToUpdate.add(wo);
                }
            }

            // Perform update if there are Work Orders to update
            if (!workOrdersToUpdate.isEmpty() && WorkOrder.sObjectType.getDescribe().isUpdateable()) {
                update workOrdersToUpdate;
            }
        }catch(Exception ex){
             Logger.logException(ex);
        }
    }
    
    /**
     * Populates Original Start and End Time on TimeSheetEntry during creation.
     *
     * @param listOfCreateTse List of new TimeSheetEntry records to process.
     */
    public static void assignOriginalStartAndEndDate(List<TimeSheetEntry> listOfCreateTse) {
        if (!listOfCreateTse.isEmpty() && listOfCreateTse != null) {
            for (TimeSheetEntry tse : listOfCreateTse) {
                tse.OriginalStartTime__c = tse.StartTime != null ? tse.StartTime : tse.OriginalStartTime__c;
                tse.OriginalEndTime__c = tse.EndTime != null ? tse.EndTime : tse.OriginalEndTime__c;
            }
        }
    }
    
    /**
     * Updates Original Start and End Time on TimeSheetEntry during update.
     *
     * @param oldMap Map of old TimeSheetEntry records.
     * @param newList List of new TimeSheetEntry records to process.
     */
    public static void updateOriginalStartAndEndDate(Map<Id, TimeSheetEntry> oldMap, List<TimeSheetEntry> newList) {
        if ((!oldMap.isEmpty() && oldMap != null) && (!newList.isEmpty() && newList != null)) {
            for (TimeSheetEntry tse : newList) {
                tse.OriginalStartTime__c = oldMap.get(tse.Id).StartTime == null ? tse.StartTime : tse.OriginalStartTime__c;
                tse.OriginalEndTime__c = oldMap.get(tse.Id).EndTime == null ? tse.EndTime : tse.OriginalEndTime__c;
            }
        }
    }
}