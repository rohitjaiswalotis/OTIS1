/**=========================================================================================
@Description: Class to store all Utility methods
* Author : Debjyoti Munshi & Anubrata Sanyal
* Version : 01
* Created Date : 12-06-2024
* Last Modified By: Naga Swapna Nakka
* Last Modified Date: 28-06-2024
=========================================================================================*/
public with sharing class FSLUtility{
    public static boolean match;
    public static Map<String,List<WorkOrder>> filterDataByFSLRecordType(List<WorkOrder> recordList, String eligibleRecordTypes){
        Map<String,List<WorkOrder>> returnData = new Map<String,List<WorkOrder>>();
        for(String eligibleRT : eligibleRecordTypes.split(';')){
            List<Sobject> wsObjectRecord=RecordTypeUtilities.filterRecordsByRecordTypeName(recordList, eligibleRT,true);
            returnData.put(eligibleRT,(List<WorkOrder>)wsObjectRecord);
        }
        returnData.put('ALL',recordList); //add all eligible records into "ALL" list
        return returnData;
    }
    public static boolean getFeatureStatus(String featureDeveloperName, Boolean isInsert, Boolean isUpdate){
        FSL_FeatureFlag__mdt featureStatus = FSL_FeatureFlag__mdt.getInstance(featureDeveloperName);
        if(featureStatus != Null){
            return (featureStatus.isActive__c && (featureStatus.insertEligible__c == isInsert || featureStatus.updateEligible__c == isUpdate));
        }
        return false;
    }
    public static String getAllFSLWORecordTypes(){
        List<String> recordTypeList = new List<String>();
        recordTypeList.add(FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT);
        recordTypeList.add(FSLConstantClass.WORK_ORDER_MAINTENANCE_RT);
        return String.join(recordTypeList,';');
    }
    public static Map<String,List<ServiceAppointment>> filterByRelatedWorkOrderRecordType(List<ServiceAppointment> recordList){
        Map<String,List<ServiceAppointment>> returnData = new Map<String,List<ServiceAppointment>>();
        List<Id> workOrderIds = new List<Id>();
        Map<Id, ServiceAppointment> workOrderToSAMap = new Map<Id, ServiceAppointment>();
        for(ServiceAppointment obj : recordList){
            if(String.valueOf(obj.ParentRecordId).startsWith('0WO')){
                workOrderIds.add(obj.WorkOrder__c);
                workOrderToSAMap.put(obj.WorkOrder__c, obj);
            }  
        }
      
        //List out Work Orders related to the Service Appointments
        List<WorkOrder> allWorkOrders = [select Id, RecordTypeId, RecordType.DeveloperName from WorkOrder where Id IN :workOrderIds];
        //Initialize List
        returnData.put(FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT,new List<ServiceAppointment>());
        returnData.put(FSLConstantClass.WORK_ORDER_MAINTENANCE_RT,new List<ServiceAppointment>());
        
        //Populate all SA records related to Service Request record type
        List<WorkOrder> wsObjectRecordSR=(List<WorkOrder>)RecordTypeUtilities.filterRecordsByRecordTypeName(allWorkOrders, FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT,true);
        for(WorkOrder obj : wsObjectRecordSR){
            returnData.get(FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).add(workOrderToSAMap.get(obj.Id));
        }
        
        //Populate all SA records related to Maintenance record type
        List<WorkOrder> wsObjectRecordMT=(List<WorkOrder>)RecordTypeUtilities.filterRecordsByRecordTypeName(allWorkOrders, FSLConstantClass.WORK_ORDER_MAINTENANCE_RT,true);
        for(WorkOrder obj : wsObjectRecordMT){
            returnData.get(FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).add(workOrderToSAMap.get(obj.Id));
        }
        
        //Populate all SA records that apply to Service Request and Maintenance record type (for processes that are common between them)
        returnData.put('ALL',recordList); //add all eligible records into "ALL" list
        
        return returnData;
    }
    
    public static String transformUnitOperationalStatus(String status){
        Map<String,String> allTransformationMap = new Map<String,String>();
        for(Unit_Operational_Status_Reason_Mapping__mdt obj : Unit_Operational_Status_Reason_Mapping__mdt.getAll().values()){
            allTransformationMap.put(obj.Unit_Operational_Status_Reason_SF__c, obj.Transformed_Platform_Event_Output__c);
        }
        return allTransformationMap.get(status);
    }
    
    public static String getUnitUsageFromUnit(Asset unitRecord){
        String unitUsages=null;
        String finalUnitUsages= null;
        if(unitRecord.FS_MissedVisit__c) unitUsages='Missed Visit,';
        if(unitRecord.FS_CancellationAlert__c) unitUsages=unitUsages+'Cancellation Alert,';
        if(unitRecord.FS_ProductionUnitMaintenance__c) unitUsages=unitUsages+'Production Unit Maintenance,';
        if(unitRecord.FS_HighFrequencyUnit__c) unitUsages=unitUsages+'High Frequency Unit,';
        if(unitRecord.FS_LowUsage__c) unitUsages=unitUsages+'Low Usage,';
        if(unitRecord.FS_CriticalUnit__c) unitUsages=unitUsages+'Critical Unit,';
        if(unitRecord.FS_RebelUnit__c) unitUsages=unitUsages+'Rebel Unit,';
        if(unitRecord.CadencedVisits__c) unitUsages=unitUsages+'Cadenced Visits,';
        if(unitRecord.ContractPenaltyUnit__c) unitUsages=unitUsages+'Contract Penalty Unit,';
        
        if(!unitRecord.FS_MissedVisit__c && !unitRecord.FS_CancellationAlert__c && !unitRecord.FS_ProductionUnitMaintenance__c && !unitRecord.FS_HighFrequencyUnit__c && !unitRecord.FS_LowUsage__c && !unitRecord.FS_CriticalUnit__c && !unitRecord.FS_RebelUnit__c&& !unitRecord.CadencedVisits__c && !unitRecord.ContractPenaltyUnit__c){
            unitUsages='Regular Maintenance,';
        }
        
        return unitUsages.removeStartIgnoreCase('Null');
        
    }
    
    public static FSL_FeatureFlag__mdt getFeatureFlagDetails(String featureFlag){
        FSL_FeatureFlag__mdt featureFlagWODispatcher= FSL_FeatureFlag__mdt.getInstance(featureFlag);
        return featureFlagWODispatcher;
    }
    //Method to check the old and new Value
    public static List<ServiceAppointment> returnSAWithUpdatedStatus(List<ServiceAppointment> newRecords, Map<Id,ServiceAppointment> oldMap){
        List<ServiceAppointment> returnList = new List<ServiceAppointment>();
        for(ServiceAppointment obj: newRecords){
            if(obj.Status != oldMap.get(obj.Id).Status){
                returnList.add(obj);
            }
        }
        return returnList;
    }
    
    //Return all the Fields of Custom Metadata
    public static FSL_QueryHelper__mdt getRecordQueryHelperMetadata(String metadataName){
        List<FSL_QueryHelper__mdt> queryHelper = new List<FSL_QueryHelper__mdt>();
        queryHelper = [select id,isActive__c,Name__c,SObject__c,Field_API_Names__c from FSL_QueryHelper__mdt where Name__c =:metadataName];
        return queryHelper[0];
        
    }
    
    //Method to carryout different automation on SA completion
    public static WorkOrder updateWorkOrderStatusForComplete(WorkOrder wo, ServiceAppointment sa) {

        if(wo.Fixed_Issue__c == 'Yes'){

            switch on wo.FS_WorkOderType__c {

                when 'Open Order'{

                    WO.Status='Cannot Complete';

                }


                when 'Maintenance'{

                    wo.Status = 'Closed';

                    wo.SvcReqAssignedMechanic__c = sa.AssignedServiceResource__c;

                 

                }

            }

      }

     Else {

         if(wo.FS_WorkOderType__c=='Repair' &&  wo.FS_Work_Completion__c ){

             wo.Status = 'Closed';

             wo.SvcReqAssignedMechanic__c = sa.AssignedServiceResource__c;

            

         }

         else{

             wo.Status='Cannot Complete';

            

         }

        }

        return wo;

    }
    
    public static string getWeekDay(){
        Date d = System.today();
        Datetime dt = (DateTime)d;
        return dt.format('EE').toUpperCase();
    }
    
    public static Map<Id,WorkOrder> convertSobjToRecordObjMap(String sObjectName,Map<Id, SObject> newItems) {
        Map<Id,WorkOrder> woIdWithValuesMap = new Map<Id,WorkOrder>();
        for (Id key: newItems.keySet()){
            if(sObjectName==FSLConstantClass.WORK_ORDER_OBJECT_NAME){
                WorkOrder wo = (WorkOrder)newItems.get(key);
                if(wo.RecordTypeId == FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID || wo.RecordTypeId == FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID){
                    woIdWithValuesMap.put(wo.Id,wo);
                } 
            }
            
        }
        return woIdWithValuesMap;
    }
    
    public static List<ServiceAppointment> filterSAByRelatedWorkOrderRecordTypeId(List<ServiceAppointment> recordList,Id recordTypeId,Boolean allRecords){
        List<ServiceAppointment> segregatedList = new List<ServiceAppointment>();
        for(ServiceAppointment sa : recordList){
            if(recordTypeId!=null && sa.WorkOrderRecordTypeId__c == recordTypeId && !allRecords){
                segregatedList.add(sa);
            }else if(allRecords){
                if(sa.WorkOrderRecordTypeId__c == FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID || sa.WorkOrderRecordTypeId__c == FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID){
                    segregatedList.add(sa);
                }
            }
        }
        return segregatedList;
    }
     // This method will check if Word order record type is present or not
    public static Boolean isWOWorkTypePresent(WorkOrder wo){
        Boolean flag = false;
        if(wo.WorkTypeId != null){
            flag = true; 
        }
        return flag;
    }
    // This method will check if Word order record type is equal to Service_Request
    public static Boolean getWORecordType(WorkOrder wo){
        Boolean flag = false;
        if(wo.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId()){
            flag = true; 
        }
        return flag;
    }
     //Invocable method to get the UTC time value
     @InvocableMethod(Label='GetUTCDateTime')
     public static List<DateTime> getUTCDateTime(List<DateTime> dt){
         List<Datetime> UTCDate = new List<Datetime>();
         UTCDate.add(Datetime.newInstanceGmt(
                             dt[0].year(),
                             dt[0].month(),
                             dt[0].day(),
                             dt[0].hour(),
                             dt[0].minute(),
                             dt[0].second()));
         return UTCDate;
    }

    //get all profile id and name
    public static List<Profile> getAllUserProfile(){
        return new List<Profile>([select id,Name from Profile]);
    }

    // check work order assignment type based on profile  
    public static List<WorkOrder> isWorkOrderAssignmentTypePresent(List <WorkOrder> recordWOList,Map<Id,Profile> profileDetailsMap){
        List<WorkOrder>finaWOList = new List<WorkOrder>();
        if(!profileDetailsMap.isEmpty()){
            for(workOrder wo : recordWOList){
                if(wo.AssignmentType__c == NULL && (profileDetailsMap.get(UserInfo.getProfileId()).Name==FSLConstantClass.SYSTEM_ADMINISTRATOR || profileDetailsMap.get(UserInfo.getProfileId()).Name==FSLConstantClass.FS_ADMIN )){
                    finaWOList.add(wo);
                }
            }
        }
        
        return finaWOList;
    }

    //get work order assignment type from work type 
    public static String getWorkTypeAssignmentType(WorkType wt){
        if(wt!=null && wt.FS_AutoSchedule__c){
           return FSLConstantClass.AUTO ;
        }else{
            return FSLConstantClass.MANUAL ;
        }  
    } 

    //assign WO record type based on the condition
    public Static Id isMaintenanceORServiceRequestWO(WorkOrder wo){
        if(wo!=null && (wo.IsGeneratedFromMaintenancePlan || wo.FS_WorkOderType__c == FSLConstantClass.Maintenance || wo.FS_WorkOderType__c == FSLConstantClass.Repair ||wo.FS_WorkOderType__c == FSLConstantClass.Open_Order)){
            return FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID;
        }else{
            return FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID;
        }
    }
}