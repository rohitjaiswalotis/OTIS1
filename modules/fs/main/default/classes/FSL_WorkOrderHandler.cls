/**=========================================================================================
* Author : Sayanton Sadhu 
* Version : 01
* Description: Work Order Handler Class to store all business logic methods
* Created Date : 02-07-2024
* Last Modified Date : 10-July-2024
=========================================================================================*/
public without sharing class FSL_WorkOrderHandler extends TriggerHandler{
    
    /*
* @Description:Method For Before Insert
* SetDefaultWorkTypeOnWorkOrder:This method will call the SetDefaultWorkTypeOnWorkOrder method in 
  FSL_WorkOrderService class which will assign the default work type
* @Param : List of sObjects 
*/
    public override void beforeInsert(List<SObject> newList) {
        Map<Id,Profile> getAllUserProfile = new Map<Id,Profile>(FSLUtility.getAllUserProfile());
        
        List<WorkOrder> allWorkOrderRT = FSL_WorkOrderService.setRecordTypeOnWO(
            (List<WorkOrder>) newList, getAllUserProfile
        );

        List<WorkOrder> newMaintenanceWorkOrders = RecordTypeUtilities.filterRecordsByRecordTypeName(
            (List<WorkOrder>) allWorkOrderRT, FSLConstantClass.WORK_ORDER_MAINTENANCE_RT, true, true
        );
        
        List<WorkOrder> newServiceWorkOrders = RecordTypeUtilities.filterRecordsByRecordTypeName(
            (List<WorkOrder>) allWorkOrderRT, FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT, true, true
        );
        
        if (newMaintenanceWorkOrders.isEmpty() && newServiceWorkOrders.isEmpty() ) {
            return;
        }
        
        if(!newServiceWorkOrders.isEmpty()){
            FSL_WorkOrderService.SetDefaultWorkTypeOnWorkOrder(newServiceWorkOrders);
            //This converting Flow FS WO Prioritization FOR SR
            FSL_WorkOrderService.setPriorityOnWorkOrder(newServiceWorkOrders,new List<WorkOrder>(),new Map<Id,WorkOrder>(),false);
            //This converting Entitlement Flow
            FSL_WorkOrderService.setEntitlementFieldsOnSRWO(newServiceWorkOrders);
            FSL_WorkOrderService.setDefaultEntitlementFieldsOnSRWO(newServiceWorkOrders);
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newMaintenanceWorkOrders.isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_WorkOrderService.setFSLWorkOrderSubjectBeforeInsert(newMaintenanceWorkOrders);
            //This converting Flow FS WO Prioritization For MT
            FSL_WorkOrderService.setPriorityOnWorkOrder(new List<WorkOrder>(),newMaintenanceWorkOrders,new Map<Id,WorkOrder>(),false);
        }
    }
    
    public override void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        Map<Id, WorkOrder> newMaintenanceWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), FSLConstantClass.WORK_ORDER_MAINTENANCE_RT, true, true
            )
        );
        
        Map<Id, WorkOrder> newServiceWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT, true, true
            )
        );
        
        if (newServiceWorkOrdersMap.isEmpty() && newServiceWorkOrdersMap.isEmpty() ) {
            return;
        }
        
        if(!newServiceWorkOrdersMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.setPriorityOnServiceAppointment(new List<ServiceAppointment>(),newServiceWorkOrdersMap.values());
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newMaintenanceWorkOrdersMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.setPriorityOnServiceAppointment(new List<ServiceAppointment>(),newMaintenanceWorkOrdersMap.values());
        }
        
        
        
    }
    
    public override void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        
        Map<Id, WorkOrder> newMaintenanceWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), FSLConstantClass.WORK_ORDER_MAINTENANCE_RT, true, true
            ) 
        ); 
        
        Map<Id, WorkOrder> newServiceWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT, true, true
            )
        );
        
        if (newMaintenanceWorkOrdersMap.isEmpty() &&  newServiceWorkOrdersMap.isEmpty()) {
            return;
        }
        
        //Merged SR & MT List & Map using  this wrapper class
        FSL_WorkOrderService.FSLWorkOrderServiceWrapper fslWorkOrderWrapper = new FSL_WorkOrderService.FSLWorkOrderServiceWrapper(newMap,oldMap);
        
        //Invoke the following methods for Service Request Record Type
        if(!newServiceWorkOrdersMap.values().isEmpty()){
            FSL_WorkOrderService.SetDefaultWorkTypeOnWorkOrder(newServiceWorkOrdersMap.values());
            //Add all methods that needs to be executed for SR:
            FSL_WorkOrderService.setPriorityOnWorkOrder(newServiceWorkOrdersMap.values(),new List<WorkOrder>(),fslWorkOrderWrapper.oldMapValues,null);
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newMaintenanceWorkOrdersMap.values().isEmpty()){
            //Add all methods that needs to be executed for MT:
            FSL_WorkOrderService.setPriorityOnWorkOrder(new List<WorkOrder>(),newMaintenanceWorkOrdersMap.values(),new Map<Id,WorkOrder>(),true);
        }
        
        //Invoke the business methods that needs to be executed for Maintenance,Service Request record types
        if(!fslWorkOrderWrapper.newMapValues.values().isEmpty()){
            //Add all methods that needs to be executed for SR & MT:
            if(!fslWorkOrderWrapper.oldMapValues.values().isEmpty()){
                FSL_WorkOrderService.setWorkOrderClosureDate(fslWorkOrderWrapper.newListValuesWithCombinedRT,fslWorkOrderWrapper.oldMapValues,false,true);
                FSL_WorkOrderService.showErrorMessageOnWOCancellation(fslWorkOrderWrapper.newListValuesWithCombinedRT,fslWorkOrderWrapper.oldMapValues);
            }
        }
        
    }
    
    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        Map<Id, WorkOrder> newMaintenanceWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), FSLConstantClass.WORK_ORDER_MAINTENANCE_RT, true, true
            ) 
        ); 
        
        Map<Id, WorkOrder> newServiceWorkOrdersMap = new Map<Id, WorkOrder>(
            (List<WorkOrder>) RecordTypeUtilities.filterRecordsByRecordTypeName(
                (List<WorkOrder>) newMap.values(), FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT, true, true
            )
        );
        
        if (newMaintenanceWorkOrdersMap.isEmpty() &&  newServiceWorkOrdersMap.isEmpty()) {
            return;
        }
        
        //Invoke the following methods for Service Request Record Type
        if(!newServiceWorkOrdersMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.setPriorityOnServiceAppointment(new List<ServiceAppointment>(),newServiceWorkOrdersMap.values());
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newMaintenanceWorkOrdersMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.setPriorityOnServiceAppointment(new List<ServiceAppointment>(),newMaintenanceWorkOrdersMap.values());
        }
    }
}