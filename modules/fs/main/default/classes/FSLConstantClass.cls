/**=========================================================================================
@Description: Utility class to store all programmatic constant variables
* Author : Debjyoti Munshi & Anubrata Sanyal
* Version : 01
* Created Date : 12-06-2024
* Last Modified By: Debjyoti Munshi
* Last Modified Date: 25-06-2024
* Last Modified By: Naga Swapna Nakka
* Last Modified Date: 26-06-2024
=========================================================================================*/
public without sharing class FSLConstantClass {
    public enum TransactionType {Insert_Record,Update_Record,Delete_Record}
    public enum SAStatus {None,Scheduled,Dispatched,Enroute,Onsite,Completed,Canceled,CannotComplete,Accepted,Rejected}
    public enum WOStatus {Unassigned,Assigned,InProgress,Canceled,CannotComplete,OnHold,Closed,Accepted,Rejected}
    public static final String WORK_ORDER_OBJECT_NAME = 'WorkOrder';
    public static final String WORK_ORDER_SERVICE_REQUEST_RT = 'Service_Request';
    public static final String WORK_ORDER_MAINTENANCE_RT = 'Maintanance';
    public static final String SERVICE_APPOINTMENT_OBJECT_NAME = 'ServiceAppointment';
    public static final String WORK_ORDER_CLASSIC_RECORD_TYPE = 'Classic_CC';
    public static final Id WORK_ORDER_SERVICE_REQUEST_RT_ID = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
    public static final Id WORK_ORDER_MAINTENANCE_RT_ID = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
    public static final Id WORK_ORDER_CLASSIC_RECORD_TYPE_ID = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_CLASSIC_RECORD_TYPE).getRecordTypeId();
    public static final String SET_PRIORITY_ON_WORKORDER = 'Set_Priority_on_Work_Order';
    public static final String SET_PRIORITY_ON_SERVICEAPPOINTMENT = 'SetPriorityOnServiceAppointment';
    public static final String INSERT_STRING = 'insert';
    public static final String UPDATE_STRING = 'update';
    public static final String Delete_STRING = 'delete';
    public static final String FALSE_STRING = 'False' ;
    public static final String Scheduled = 'Scheduled';
    public static final String CannotComplete = 'Cannot Complete';
    public static final String Maintenance = 'Maintenance';
    public static final String Open_Order = 'Open Order';
    public static final String Repair = 'Repair';
    public static final String AUTO = 'Auto' ;
    public static final String MANUAL = 'Manual' ;
    public static final String SET_ENTITLEMENTS_On_WORKORDER= 'Set_Entitlements_On_WorkOrder';
    public static final String FEATURE_POPULATE_CLOSURE_DATE_ON_WORKORDER = 'PopulateClosureDateOnWorkOrder';
    public static final String FEATURE_COMPANY_WIDE_DEFAULT_ENTITLEMENTS = 'UseCompanyWideDefaultEntitlementsOnly';
    public static final String CALCULATE_OVERDUE_PRIORITY = 'Calculate_Overdue_Priority';
    public static final String WORK_ORDER_STATUS_CLOSED = 'Closed';
    public static final String FEATURE_ROUTE_REASSIGNMENT_OPERATION = 'RouteReassignmentOperation';
    public static final String SERVICE_APPOINTENT_STATUS_ENROUTE ='Enroute';
    public static final String SERVICE_APPOINTENT_STATUS_ONSITE ='Onsite';
    public static final String SERVICE_APPOINTENT_STATUS_COMPLETED ='Completed';
    public static final String WORK_ORDER_STATUS_CANCELED = 'Canceled';
    public static final String WORK_ORDER_STATUS_INPROGRESS = 'In Progress';
    public static final String SYSTEM_ADMINISTRATOR = 'System Administrator';
    public static final String FS_ADMIN = 'Field Service Admin';
}