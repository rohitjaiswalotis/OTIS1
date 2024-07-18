/**=========================================================================================
* Author : Sayanton Sadhu
* Version : 01
* Description: Service Appointment Handler Class to store all business logic methods
* Created Date : 03-07-2024
=========================================================================================*/
public inherited sharing class FSL_ServiceAppointmentService {
    /*
    * @Description:to set the priority of Service Appointment for Service Request & Maintenance Work Order record type from SA Prioritization Matrix metadata
    * @Param : List of ServiceAppointment , Map Of ServiceAppointment with ID and a boolean variable to check if the record is updated or not . 
    */
    public static void setPriorityOnServiceAppointment(List<ServiceAppointment> listOfServiceAppointment,List<WorkOrder> listOfWO){
        //Service Appointment Priority field update for Service request Records
        try{
            Map<Id,WorkOrder> saRelatedWoRecords;
            List<Id> woIds= new List<Id>();
            if(!listOfServiceAppointment.isEmpty()){
                for(ServiceAppointment sa: listOfServiceAppointment){
                    woIds.add(sa.WorkOrder__c);
                }
                saRelatedWoRecords= new Map<Id,WorkOrder>([Select Id, FS_Priority__c from WorkOrder where id in:woIds]);
            }else if(!listOfWO.isEmpty()){
                saRelatedWoRecords= new Map<Id,WorkOrder>();
                for(WorkOrder wo: listOfWO){
                    woIds.add(wo.Id);
                    saRelatedWoRecords.put(wo.Id,wo);
                }
                List<ServiceAppointment> saList = [select id,FS_SA_Priority__c,WorkOrder__c  from ServiceAppointment where (status='None' or status='Scheduled' or status='Dispatched')  and WorkOrder__c IN :woIds];
                listOfServiceAppointment.addAll(saList);
                
            }
            Map<String, FS_SAPrioritizationMatrix__mdt> saPrioritizationMatrixMap = new Map<String, FS_SAPrioritizationMatrix__mdt>();
            for(FS_SAPrioritizationMatrix__mdt obj: FS_SAPrioritizationMatrix__mdt.getAll().values()){
                saPrioritizationMatrixMap.put(obj.Label,obj);
            }
            List<ServiceAppointment> updatedsa= new List<ServiceAppointment>();
            for(ServiceAppointment sa:listOfServiceAppointment){
                If(saRelatedWoRecords.containsKey(sa.WorkOrder__c)){
                    if(saRelatedWoRecords.get(sa.WorkOrder__c).FS_Priority__c!=null && saRelatedWoRecords.get(sa.WorkOrder__c).FS_Priority__c==saPrioritizationMatrixMap.get(saRelatedWoRecords.get(sa.WorkOrder__c).FS_Priority__c).Label){
                        sa.FS_SA_Priority__c=saPrioritizationMatrixMap.get(saRelatedWoRecords.get(sa.WorkOrder__c).FS_Priority__c).FS_Value__c;
                        updatedsa.add(sa);
                    }
                }  
            }
            if(!listOfWO.isEmpty()){
                if (WorkOrder.sObjectType.getDescribe().isUpdateable()){
                    update updatedsa;
                }
            }
            
        }catch(Exception e){
            Logger.error(e.getMessage());
        }
    }
    
    /*
    * @Description:to set the Work Plan
    * @Param : List of ServiceAppointment , Map Of ServiceAppointment old value with ID and a ServiceAppointment variable to check if the record 
    */
    public static void setWorkPlanFromServiceAppointment(List<ServiceAppointment> listOfALLRecords,Map<Id,ServiceAppointment> oldMap){
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> workOrderIdToUpdate = new Set<Id>();
        boolean allMajorTasksCompleted = false;
        Set<Id> serId= new Set<Id>();
        Id arId;                
        for (ServiceAppointment sa : listOfALLRecords) {
            if (sa.Status == UTIL_Constants.SERVICE_APPOINTMENT_STATUS_COMPLETED) {
                workOrderIds.add(sa.ParentRecordId);
            }
            if (sa.Status == UTIL_Constants.SERVICE_APPOINTMENT_STATUS_DISPATCHED && oldMap.get(sa.Id).Status == UTIL_Constants.SERVICE_APPOINTMENT_STATUS_SCHEDULED) {
                serId.add(sa.id);
                workOrderIdToUpdate.add(sa.ParentRecordId);
            }
        }    
        for(AssignedResource ar: [Select Id,ServiceAppointmentId,ServiceResourceId,ServiceResource.RelatedRecordId from AssignedResource where ServiceAppointmentId IN:serId])
        {
            arId=ar.ServiceResource.RelatedRecordId;
        }                
        List<WorkPlan> workPlantoUpdate= new List<WorkPlan>();
        List<WorkPlan> workPlan = [
            SELECT Id, 	WorkOrderId, OwnerId 
            FROM WorkPlan 
            WHERE WorkOrderId IN :workOrderIdToUpdate
        ];
        for(WorkPlan wp: workPlan){
            WorkPlan wpUpdate= new WorkPlan();
            wpUpdate.id=wp.id;
            wpUpdate.OwnerId=arId;
            workPlantoUpdate.add(wpUpdate);
        }
        try {
            update workPlantoUpdate;
        } catch (Exception e) {
            
        }
        if (workOrderIds.isEmpty()) {
            return;
        }
        Map<Id, Integer> majorTypeWSCount = new Map<Id, Integer>();
        Map<Id, Integer> completedWSCount = new Map<Id, Integer>();
        List<WorkStep> workSteps = [SELECT Id, WorkOrderId, MajorTask__c, Status FROM WorkStep WHERE WorkOrderId IN :workOrderIds];
        for(WorkStep ws: workSteps){
            if(ws.MajorTask__c == true){
                if(!majorTypeWSCount.containsKey(ws.WorkOrderId)){
                    majorTypeWSCount.put(ws.WorkOrderId,0);
                }
                majorTypeWSCount.put(ws.WorkOrderId,majorTypeWSCount.get(ws.WorkOrderId)+1);
            }
            if(ws.Status == UTIL_Constants.TASK_STATUS_COMPLETED){
                if(!completedWSCount.containsKey(ws.WorkOrderId)){
                    completedWSCount.put(ws.WorkOrderId,0);
                }
                completedWSCount.put(ws.WorkOrderId,completedWSCount.get(ws.WorkOrderId)+1);
            }
        }
        for (Id woId : majorTypeWSCount.keySet()) {
            if (majorTypeWSCount.get(woId) == completedWSCount.get(woId)) {
                allMajorTasksCompleted = true;
                break;
            }
        }
        Map<Id,WorkOrder> woToUpdate= new Map<Id,WorkOrder>();
        List<ServiceAppointment> serviceappRecords = [
            SELECT Id,WorkOrder__r.FS_WorkOderType__c, WorkOrder__c,WorkOrder__r.Fixed_Issue__c, WorkOrder__r.Status, WorkOrder__r.FS_System_Reason__c, WorkOrder__r.FS_Mark_For_Supervisor_Review__c,status 
            FROM ServiceAppointment 
            WHERE WorkOrder__c IN :workOrderIds
        ];                
        for (ServiceAppointment ser : serviceappRecords) {
            Id woId= ser.WorkOrder__c;
            if(woId!=null){
                if(!woToUpdate.containsKey(woId)){
                    woToUpdate.put(woId, new WorkOrder(id=woId));
                }
            }
            if (ser.status == UTIL_Constants.TASK_STATUS_COMPLETED)
            {
                if(allMajorTasksCompleted == false && (ser.WorkOrder__r.Fixed_Issue__c == UTIL_Constants.UNIT_ELITE_NO || ser.WorkOrder__r.Fixed_Issue__c == UTIL_Constants.WORKORDER_FIXEDISSUE_PARTIALLY))
                {
                    woToUpdate.get(woId).FS_System_Reason__c = UTIL_Constants.WORK_ORDER_SYSTEM_REASON;
                    woToUpdate.get(woId).FS_Mark_For_Supervisor_Review__c = true;
                    woToUpdate.get(woId).Status = UTIL_Constants.WORK_ORDER_STATUS_CANNOT_COMPLETE;
                } 
                else 
                {
                    if(allMajorTasksCompleted == true && ser.WorkOrder__r.Fixed_Issue__c == 'Yes')
                    {
                        woToUpdate.get(woId).Status = (ser.WorkOrder__r.FS_WorkOderType__c != 'Open Order') ? 'Closed' : 'Cannot Complete';
                        woToUpdate.get(woId).FS_Mark_For_Supervisor_Review__c = false;
                    }
                   // woToUpdate.get(woId).Status = UTIL_Constants.WORK_ORDER_STATUS_CLOSED;
                }
        	}
        }
       
        if(!woToUpdate.isEmpty()){
            try {
                if (WorkOrder.sObjectType.getDescribe().isUpdateable()){
                    update woToUpdate.values();
                }
            } catch (Exception e) {
                Logger.error(e.getMessage());
            }
        }
    }
    
    /*
    * @Description:to set the SA Time Stamps
    * @Param : List of ServiceAppointment , Map Of ServiceAppointment old value with ID and a ServiceAppointment variable to check if the record 
    */
    public static void setSATimestamps(List<ServiceAppointment> newList, Map<Id,ServiceAppointment> oldMap) {
                List<ServiceAppointment> saList = new List<ServiceAppointment>();
        Boolean futureFlag = FSLUtility.getFeatureStatus('Capture_SA_Status_Transition_Timestamp', false, true);
        for(ServiceAppointment sa : newList) {
                        if(futureFlag){
                saList.add(sa);
            }
            
        }
        if(!saList.isEmpty()) {
           map<id,decimal> appointmentVSEstimatedTravelTime= getAppointmentVSEstimatedTravelTime(saList);
            for(ServiceAppointment saApp : saList) {
                if((saApp.Status != 'Scheduled' && saApp.Status != 'Rejected') && saApp.Status != oldMap.get(saApp.Id).Status) {
                    switch on saApp.Status {
                        when 'Dispatched', 'Accepted' {
                            saApp.Dispatch_Date_Time__c = System.now();
                        }
                        when 'Enroute' {
                            saApp.Travel_Date_Time__c = System.now();
                            saApp.TravelTimeStamp__c =system.now();
                            saApp.Estimated_Travel_Time__c = appointmentVSEstimatedTravelTime.containskey(saApp.id)?appointmentVSEstimatedTravelTime.get(saApp.id):0;  
                        }
                        when 'Onsite' {
                            saApp.Onsite_Date_Time__c = System.now();
                            saApp.OnSiteTimeStamp__c = system.now();
                        }
                        when 'Completed' {
                            saApp.Completed_Date_Time__c = System.now();
                            saApp.CompletionTimeStamp__c = system.now();
                        }
                        when 'Cannot Complete' {
                            saApp.Incomplete_Date_Time__c = System.now();
                        }
                        when 'Canceled' {
                            saApp.Cancelled_Date_Time__c = System.now();
                        }
                        when else {
                            // No action needed for other statuses
                        }
                        
                    }
                                     }
            }
        }
    }
    
    /*
    * @Description:Method for Status Transition for Record Type WorkOrder
    * @Param : List of ServiceAppointment when WO recordtype is SR
    */
    public static void updateServiceRequestWorkOrder(List<ServiceAppointment> updatedSARecord) {
        
        List<WorkOrder> updatedWOs = new List<WorkOrder>();
        List<WOrkOrder>listToBeUpdated=new List<WorkOrder>();
         List<SF2WSOtisNoteEvent__e> eventsToPublish = new List<SF2WSOtisNoteEvent__e>();
        Set<Id> relatedWOId = new Set<Id>();
        Map<Id , WorkOrder> saRelatedWOMap = new Map<Id , WorkOrder>();
        
        for(ServiceAppointment sa :updatedSARecord ){
            relatedWOId.add(sa.WorkOrder__c);
        }
        
        //Calling a method for Getting Related WO List
        updatedWOs=FSL_WorkOrderService.getWorkOrderListFormWorkOrderIdSet(relatedWOId,'Get_WorkOrderWithId');
        
        //Assigning Value in the List
        for(WorkOrder wo :updatedWOs){
            id woID = wo.id;
            saRelatedWOMap.put(woId,wo);
        }
        
        //Iterating Each SA to Check Status
        for(ServiceAppointment sa : updatedSARecord){
            WorkOrder wo = saRelatedWOMap.get(sa.WorkOrder__c);
            FSLConstantClass.SAStatus currentSAStatus = FSLConstantClass.SAStatus.valueOf(sa.Status.deleteWhiteSpace());
            
            //Initiazing Switch Case
            switch on (currentSAStatus){
                
                when Scheduled,Dispatched {
                    wo.Status = 'Assigned';
                }
                when Enroute {
                    wo.Status = 'InProgress';
                }
                when Onsite {
                    wo.Status = 'InProgress';
                   eventsToPublish.addAll(generatePlatformEvent(wo, 'OnSite'));
                }
                when Canceled {
                    wo.Status = 'Canceled';
                    wo.FS_CancellationReason__c = 'Contract cancelled on site (not updated in our system)';
                }
                when CannotComplete {
                    wo.Status = 'Cannot Complete';
                }
                when Completed {
                    if (wo.TrappedPassengerReleasedByOTIS__c &&
                        wo.Priority == 'S3 - Normal' &&
                        (wo.Reason__c == 'Need Supervisor Review and Action' ||
                         wo.Reason__c == 'Need New Visit On Site')) {
                             wo.Status = 'Cannot Complete';
                             wo.FS_Priority__c = 'S3';
                         } else if (wo.Fixed_Issue__c == 'No' ||
                                    wo.Fixed_Issue__c == 'Partially' ||
                                    wo.UnitStatusOnSiteDeparture__c == 'Shutdown' ||
                                    wo.FS_Mark_For_Supervisor_Review__c) {
                                        wo.Status = 'Cannot Complete';
                                    } else {
                                        wo.Status = 'Closed';
                                        wo.SvcReqAssignedMechanic__c = sa.AssignedServiceResource__c;
                                    }
                }
            }
            listToBeUpdated.add(wo);
        }
        if (listToBeUpdated != null) {
            try {
                if (WorkOrder.sObjectType.getDescribe().isUpdateable()){
                    update listToBeUpdated;
                }
            } catch (Exception e) {
                Logger.error(e.getMessage());
            } 
        }
        if (!eventsToPublish.isEmpty()) {
            EventBus.publish(eventsToPublish);
            
        }
  }
    
    /*
    * @Description:Method for Status Transition for Record Type WorkOrder
    * @Param : List of ServiceAppointment when WO recordtype is Maintenance
    */
    public static void updateMaintenanceWorkOrder(List<ServiceAppointment> updatedSARecord) {
        
        List<WorkOrder> updatedWOs = new List<WorkOrder>();
        List<WOrkOrder>listToBeUpdated=new List<WorkOrder>();
        Set<Id> relatedWOId = new Set<Id>();
        Map<Id , WorkOrder> saRelatedWOMap = new Map<Id , WorkOrder>();
        
        for(ServiceAppointment sa :updatedSARecord ){
            relatedWOId.add(sa.WorkOrder__c);
        }
        
        //Calling a method for Getting Related WO List
        updatedWOs=FSL_WorkOrderService.getWorkOrderListFormWorkOrderIdSet(relatedWOId,'Get_WorkOrderWithId');
        
        //Assigning Value in the List
        for(WOrkOrder wo :updatedWOs){
            id woID = wo.id;
            saRelatedWOMap.put(woId,wo);
        }
        
        //Iterating Each SA to Check Status
        for(ServiceAppointment sa : updatedSARecord){
            WorkOrder wo = saRelatedWOMap.get(sa.WorkOrder__c);
            FSLConstantClass.SAStatus currentSAStatus = FSLConstantClass.SAStatus.valueOf(sa.Status.deleteWhiteSpace());
            
            //Initiazing Switch Case
            switch on (currentSAStatus){
                when Scheduled ,Dispatched {
                    wo.Status = 'Assigned';
                }
                when Enroute {
                    wo.Status = 'InProgress';
                }
                when Onsite {
                    wo.Status = 'InProgress';
                }
                when Canceled {
                    wo.Status = 'Canceled';
                    wo.FS_CancellationReason__c = 'Contract cancelled on site (not updated in our system)';
                }
                when CannotComplete {
                    wo.Status = 'Cannot Complete';
                }
                when Completed {
                    wo = FSLUtility.updateWorkOrderStatusForComplete(wo,sa);
                }
            }
            listToBeUpdated.add(wo);
        }
        if (listToBeUpdated != null) {
            try {
                if (WorkOrder.sObjectType.getDescribe().isUpdateable()){
                    update listToBeUpdated;
                }
            } catch (Exception e) {
                Logger.error(e.getMessage());
            } 
        }
    } 
    
    /*
    * @Description:Method TO CREATE PLATFORM EVENT
    * @Param : Work Order and Context
    */   
    public static List<SF2WSOtisNoteEvent__e> generatePlatformEvent(WorkOrder wo, String context){
            List<SF2WSOtisNoteEvent__e> events = new List<SF2WSOtisNoteEvent__e>();
            SF2WSOtisNoteEvent__e event = new SF2WSOtisNoteEvent__e();
        Asset assets = [SELECT Id, OperationalStatusReason__c FROM Asset WHERE Id = :wo.AssetId LIMIT 1];
        
            if(context == 'OnSite' && wo != NULL){
                event.CallbackKey__c = wo.SvcReqCallBackKey__c;    
                event.MechanicArrivalTime__c = System.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                event.TimeZone__c = wo.TimeZone__c;
                event.WorkOrderStatus__c = wo.Status;
                
                events.add(event);
            }
            else {
                event.CallbackKey__c = wo.SvcReqCallBackKey__c;
                event.OperationalStatusReason__c = FSLUtility.transformUnitOperationalStatus(assets.OperationalStatusReason__c);
                event.TimeZone__c = wo.TimeZone__c;
                Date closureDate = Date.valueOf(wo.WorkOrderClosureDate__c);
                DateTime closureDateTime = DateTime.newInstance(closureDate,Time.newInstance(0,0,0,0));
                String format = closureDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                event.WorkOrderClosureDate__c = format;
               
                event.WorkOrderStatus__c = wo.Status;
                events.add(event);
            }
        
            return events;
        }
    /*
    * @Description:Method TO populate values in WorkOrder field & WorkOrderRecordType Id values
    * @Param : List of ServiceAppointment.
    */
    public static List<ServiceAppointment> setWorkOrderIdWhileCreateSA(List<ServiceAppointment> saList){
        List<Id> updatedSAList = new List<Id>();
        List<ServiceAppointment> updatedSAListWithRecordTypeId = new List<ServiceAppointment>();
        Map<Id,WorkOrder> mapOfIdAndWorkOrder;
        if(saList!=null){
            for(ServiceAppointment sa : saList){
                if(String.valueOf(sa.ParentRecordId).startsWith('0WO')){
                    updatedSAList.add(sa.ParentRecordId);
                }
            }
            
            if(updatedSAList!=null){
                mapOfIdAndWorkOrder = new Map<Id,WorkOrder>([select Id, RecordTypeId, RecordType.DeveloperName from WorkOrder where Id IN :updatedSAList AND (RecordTypeId=:FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID OR RecordTypeId=:FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID)]);
                
                for(ServiceAppointment sa : saList){
                    if(String.valueOf(sa.ParentRecordId).startsWith('0WO') && mapOfIdAndWorkOrder.containsKey(sa.ParentRecordId) && (mapOfIdAndWorkOrder.get(sa.ParentRecordId).RecordTypeId == FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID || mapOfIdAndWorkOrder.get(sa.ParentRecordId).RecordTypeId ==FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID)){
                        sa.WorkOrder__c=sa.ParentRecordId;
                        sa.WorkOrderRecordTypeId__c = mapOfIdAndWorkOrder.get(sa.ParentRecordId).RecordTypeId;
                        updatedSAListWithRecordTypeId.add(sa);
                    }
                }
            }
        }
        return updatedSAListWithRecordTypeId;
    }
     /*
    * @Description:Method TO populate values in WorkOrder field & WorkOrderRecordType Id values
    * @Param : List of ServiceAppointment.
    */
    public static List<ServiceAppointment> setWORTIdWhileUpdateSA(List<ServiceAppointment> saList){
        List<Id> updatedSAList = new List<Id>();
        List<ServiceAppointment> updatedSAListWithRecordTypeId = new List<ServiceAppointment>();
        Map<Id,WorkOrder> mapOfIdAndWorkOrder;
        if(saList!=null){
            for(ServiceAppointment sa : saList){
                if(sa.WorkOrderRecordTypeId__c==null){
                    updatedSAList.add(sa.ParentRecordId);
                }
            }
            
            if(updatedSAList!=null && !updatedSAList.isEmpty()){
                mapOfIdAndWorkOrder = new Map<Id,WorkOrder>([select Id, RecordTypeId, RecordType.DeveloperName from WorkOrder where Id IN :updatedSAList AND (RecordTypeId=:FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID OR RecordTypeId=:FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID)]);
                
                for(ServiceAppointment sa : saList){
                    if(String.valueOf(sa.ParentRecordId).startsWith('0WO') && mapOfIdAndWorkOrder.containsKey(sa.ParentRecordId) && (mapOfIdAndWorkOrder.get(sa.ParentRecordId).RecordTypeId == FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID || mapOfIdAndWorkOrder.get(sa.ParentRecordId).RecordTypeId ==FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID)){
                        sa.WorkOrderRecordTypeId__c = mapOfIdAndWorkOrder.get(sa.ParentRecordId).RecordTypeId;
                        updatedSAListWithRecordTypeId.add(sa);
                    }
                }
            }else{
                updatedSAListWithRecordTypeId = new List<ServiceAppointment>(FSLUtility.filterSAByRelatedWorkOrderRecordTypeId(saList,null,true));
            }
        }
        return updatedSAListWithRecordTypeId;
    }

   //Method to get Service Appointment List using query helper metadata      
   public static List<ServiceAppointment> getServiceAppointmentListFormWorkOrderIdList(List<string> WorkOrderIdList, String whereClauseLogic){
        // Build the query from Query Helper metadata and where clause logic sent as parameter.
        
        //Fetch the Queryhelper record
        FSL_QueryHelper__mdt queryHelperRecord = FSLUtility.getRecordQueryHelperMetadata('Get_ServiceAppointmentWithWOId'); 
        
        //Query formation
        String soqlQuery = 'SELECT ' + queryHelperRecord.Field_API_Names__c + ' FROM ' + queryHelperRecord.sObject__c + ' WHERE ParentRecordId IN (\'' + String.join(workOrderIdList, '\',\'') + '\')';
        if (whereClauseLogic != null) {
            soqlQuery += ' AND ' + whereClauseLogic;   
        }
        return Database.query(soqlQuery);
    } 
    
    /*
    * @Description:Method to create timesheet entry on SA update
    * @Param : List of ServiceAppointment  and Map of id and Service appointment and event type 
    */
    public static void createTimeSheetEntryOnAppointmentUpdate(List<ServiceAppointment> saList ,Map<Id,ServiceAppointment> oldMap){
        List<ServiceAppointment> listOfCompletedSA= new List<ServiceAppointment>();
        for(ServiceAppointment sa: saList){
            if((sa.Status == 'Completed' || sa.Status == 'Cannot Complete') && sa.status!=oldMap.get(sa.id).status){
                listOfCompletedSA.add(sa);
            }
        }
        if(!listOfCompletedSA.IsEmpty() && listOfCompletedSA !=null){
            ServiceAppointmentQueuable queueableJob = new ServiceAppointmentQueuable(listOfCompletedSA, oldMap);
            System.enqueueJob(queueableJob);
        }
    }
    
    private static map<id,decimal> getAppointmentVSEstimatedTravelTime(list<serviceAppointment> saList){
        map<id,decimal> AppointmentVSEstimatedTravelTime = new  map<id,decimal>();
        list<assignedResource> assignedResourceList=getAssignedResource(saList);
        for(assignedResource resources :assignedResourceList){
            AppointmentVSEstimatedTravelTime.put(resources.ServiceAppointmentId,resources.EstimatedTravelTime);
        }
        return AppointmentVSEstimatedTravelTime;
    }
    
    private static list<assignedResource> getAssignedResource(list<serviceAppointment> saList){
       return [select id,ServiceAppointmentId,EstimatedTravelTime from assignedResource 
                                         where ServiceAppointmentId in:saList];
    }
}