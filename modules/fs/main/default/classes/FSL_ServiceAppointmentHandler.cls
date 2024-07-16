/**=========================================================================================
* Author : Sayanton Sadhu 
* Version : 01
* Description: Service Appointment Handler Class to store all business logic methods
* Created Date : 02-07-2024
=========================================================================================*/
public without sharing class FSL_ServiceAppointmentHandler extends TriggerHandler{
    
    /*
* @Description:Method For Before Insert
* @Param : List of sObjects 
*/
    public override void beforeInsert(List<SObject> newList) {
        //This list will contains all SA records with Parent RecordType SR or MT
        List<ServiceAppointment> newAllServiceAppointments = new List<ServiceAppointment>(
            FSL_ServiceAppointmentService.setWorkOrderIdWhileCreateSA((List<ServiceAppointment>) newList
            )
        );
        
        List<ServiceAppointment> newMaintenanceServiceAppointments = FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
            newAllServiceAppointments,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID,false
        );
        
        List<ServiceAppointment> newServiceServiceAppointments = FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
            newAllServiceAppointments,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID,false
        );
        
        if (newMaintenanceServiceAppointments.isEmpty() && newServiceServiceAppointments.isEmpty() ) {
            return;
        }
        
        //Invoke the following methods for SR &  MT Record Type
        if(!newAllServiceAppointments.isEmpty()){
            FSL_ServiceAppointmentService.setPriorityOnServiceAppointment(newAllServiceAppointments,new List<WorkOrder>());
        }
        
        //Invoke the following methods for Service Request Record Type
        if(!newServiceServiceAppointments.isEmpty()){
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newMaintenanceServiceAppointments.isEmpty()){
        }
        
        
    }
    
    public override void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        Map<Id, ServiceAppointment> newAllServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),null,true
            )    
        );
        
        Map<Id, ServiceAppointment> newMaintenanceServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID,false
            )    
        );
        
        Map<Id, ServiceAppointment> newServiceServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID,false
            )
        );
        
        if (newMaintenanceServiceAppointmentsMap.isEmpty() && newServiceServiceAppointmentsMap.isEmpty() ) {
            return;
        }
        
        
        if(!newMaintenanceServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newServiceServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
        }
        
        //Invoke the following methods for SR & MT Record Type
        if(!newAllServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
        }
        
    }
    
    public override void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        Map<Id,ServiceAppointment> oldMapValues = new Map<Id,ServiceAppointment>((List<ServiceAppointment>)oldMap.values());
        
        Map<Id, ServiceAppointment> newAllServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSL_ServiceAppointmentService.setWORTIdWhileUpdateSA((List<ServiceAppointment>) newMap.values())    
        );
        
        Map<Id, ServiceAppointment> newMaintenanceServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID,false
            )    
        );
        
        Map<Id, ServiceAppointment> newServiceServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID,false
            )
        );
        
        if (newMaintenanceServiceAppointmentsMap.isEmpty() && newServiceServiceAppointmentsMap.isEmpty() ) {
            return;
        }
        
        
        if(!newMaintenanceServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newServiceServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
        }
        
        //Invoke the following methods for SR & MT Record Type
        if(!newAllServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.setSATimestamps(newAllServiceAppointmentsMap.values() , oldMapValues);
           // FSL_ServiceAppointmentService.createTimeSheetEntryOnAppointmentUpdate(newAllServiceAppointmentsMap.values() , oldMapValues , 'beforeUpdate');
        }
        
    }
    
    
    public override void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        
        Map<Id,ServiceAppointment> oldMapValues = new Map<Id,ServiceAppointment>((List<ServiceAppointment>)oldMap.values());
        
        Map<Id, ServiceAppointment> newAllServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),null,true
            )    
        );
        
        Map<Id, ServiceAppointment> newMaintenanceServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID,false
            )    
        );
        
        Map<Id, ServiceAppointment> newServiceServiceAppointmentsMap = new Map<Id, ServiceAppointment>(
            FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(
                newMap.values(),FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID,false
            )
        );
        
        if (newMaintenanceServiceAppointmentsMap.isEmpty() && newServiceServiceAppointmentsMap.isEmpty() ) {
            return;
        }
        
        if(!newMaintenanceServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.updateMaintenanceWorkOrder(FSLUtility.returnSAWithUpdatedStatus(newMaintenanceServiceAppointmentsMap.values(),oldMapValues));
            FSL_ServiceAppointmentService.setWorkPlanFromServiceAppointment(newMaintenanceServiceAppointmentsMap.values(),oldMapValues);
        }
        
        //Invoke the following methods for Maintenance Record Type
        if(!newServiceServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.updateServiceRequestWorkOrder(FSLUtility.returnSAWithUpdatedStatus(newServiceServiceAppointmentsMap.values(),oldMapValues));
        }
        
        //Invoke the following methods for SR & MT Record Type
        if(!newAllServiceAppointmentsMap.values().isEmpty()){
            //Add all methods that needs to be executed for SR. Sample below:
            FSL_ServiceAppointmentService.createTimeSheetEntryOnAppointmentUpdate(newAllServiceAppointmentsMap.values() , oldMapValues );
        }
    }
    
}