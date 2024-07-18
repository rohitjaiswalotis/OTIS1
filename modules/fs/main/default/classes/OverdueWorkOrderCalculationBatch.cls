/**=========================================================================================
* Author : Jaya Prasanth 
* Version : 01
* Description: It Updates Visit Type and Priority Fields as'Overdue visit' on WorkOrder
* Created Date : 05-07-2024
**=========================================================================================*/
global class OverdueWorkOrderCalculationBatch implements Database.Batchable<sObject> {
    global Map<Id,WorkType> wtRecordMap;
    global OverdueWorkOrderCalculationBatch(){
        wtRecordMap = new Map<Id,WorkType>([SELECT Id,Frequency__c,ProcedureCode__c FROM WorkType WHERE TaskType__c='SUV' AND ProcedureCode__c != null]); 
    }
    global List<WorkOrder> start(Database.BatchableContext bc) {
        
        Set<Id> setWorkTypeId =new Set<Id>();
        for(WorkType wType : wtRecordMap.values()){
            setWorkTypeId.add(wType.Id); 
        }
        List<WorkOrder> workOrderRecord =[select Id, Status,WorkOrderClosureDate__c,visitType__c,WorkTypeId From WorkOrder WHERE 
                                          Status NOT IN ( 'In Progress', 'Cancelled') AND
                                          RecordType.DeveloperName = 'Maintanance' AND
                                          FS_WorkOderType__c = 'Maintenance'AND
                                          WorkTypeId IN :setWorkTypeId ORDER BY WorkOrderClosureDate__c ASC];      
        return workOrderRecord;
    }
    global void execute(Database.BatchableContext bc, List<WorkOrder> scope) {
        try{
            FSL_FeatureFlag__mdt featureFlagCalculateOverduePriority= FSLUtility.getFeatureFlagDetails(FSLConstantClass.CALCULATE_OVERDUE_PRIORITY);
            if(featureFlagCalculateOverduePriority!=null && featureFlagCalculateOverduePriority.isActive__c && featureFlagCalculateOverduePriority.updateEligible__c){
                
                Map<String,Date> storeProcedureCode = new Map<String,Date>();
                Map<Id,ServiceAppointment> woIdToSarecord= new  Map<Id,ServiceAppointment>();
                Map<String,FS_SAPrioritizationMatrix__mdt> saPriorityMatrix= new Map<String,FS_SAPrioritizationMatrix__mdt>();
                List<Id> woId= new List<Id>();
                List<ServiceAppointment> updatedSaPriority = new List<ServiceAppointment>();
                List<Workorder> mTClosedWorkOrdersId = new List<Workorder>();
                List<Workorder> mTOpenWorkOrdersId = new List<Workorder>();
                List<WorkOrder> woWithUpdatedPrirority= new List<WorkOrder>();
                Map<string,Workorder> mTSingleClosedWorkOrdersId = new Map<string,Workorder>();
                for(FS_SAPrioritizationMatrix__mdt saMdt:FS_SAPrioritizationMatrix__mdt.getAll().values()){
                    saPriorityMatrix.put(saMdt.Label,saMdt);
                }
                
                for(WorkOrder wo: scope){
                    If(wo.Status == FSLConstantClass.WORK_ORDER_STATUS_CLOSED){     
                        mTClosedWorkOrdersId.add(wo);
                    }else{     
                        mTOpenWorkOrdersId.add(wo);
                    }
                }
                for(Workorder wo: mTClosedWorkOrdersId)
                {            
                    if(!wtRecordMap.isEmpty() && wtRecordMap.containsKey(wo.WorkTypeId) &&  wo.WorkTypeId== wtRecordMap.get(wo.WorkTypeId).Id){
                        mTSingleClosedWorkOrdersId.put(wtRecordMap.get(wo.WorkTypeId).ProcedureCode__c,wo);  
                    }
                } 
                for(Workorder wo: mTOpenWorkOrdersId){    
                    if(!wtRecordMap.isEmpty() && wtRecordMap.containsKey(wo.WorkTypeId) &&  wo.WorkTypeId== wtRecordMap.get(wo.WorkTypeId).Id && !mTSingleClosedWorkOrdersId.isEmpty() && mTSingleClosedWorkOrdersId.containsKey(wtRecordMap.get(wo.WorkTypeId).ProcedureCode__c)) {
                        if(wtRecordMap.get(wo.WorkTypeId).Frequency__c < (Date.valueOf(mTSingleClosedWorkOrdersId.get(wtRecordMap.get(wo.WorkTypeId).ProcedureCode__c).WorkOrderClosureDate__c).daysBetween(system.Today()))){
                            wo.VisitType__c = 'Overdue Visit';
                            wo.FS_Priority__c = saPriorityMatrix.get(wo.VisitType__c).Label;
                            woWithUpdatedPrirority.add(wo);   
                        }
                    }
                }
                if(!woWithUpdatedPrirority.isEmpty()){
                    Database.update(woWithUpdatedPrirority,false); 
                }
            }
        }
        
        catch(Exception ex){
            Logger.logException(ex);     
        }
    }
    global void finish(Database.BatchableContext bc) {
    }
}