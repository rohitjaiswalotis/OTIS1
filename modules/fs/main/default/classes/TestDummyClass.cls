public class TestDummyClass {
    public static FSL_QueryHelper__mdt getRecordQueryHelperMetadata(String metadataName){
        List<FSL_QueryHelper__mdt> queryHelper = new List<FSL_QueryHelper__mdt>();
        queryHelper = [select id,isActive__c,Name__c,SObject__c,Field_API_Names__c from FSL_QueryHelper__mdt where Name__c =:metadataName];
        return queryHelper[0];
        
    }
    
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
                mapOfIdAndWorkOrder = new Map<Id,WorkOrder>([select Id, RecordTypeId, RecordType.DeveloperName from WorkOrder where Id IN :updatedSAList AND (RecordTypeId=:FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID OR RecordType.DeveloperName=:FSLConstantClass.WORK_ORDER_MAINTENANCE_RT_ID)]);
                
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
    
    public static void setPriorityOnWorkOrder(List<WorkOrder> listOfSRWorkOrder,List<WorkOrder> listOfMPWorkOrder,Map<Id,WorkOrder> oldMap,boolean isRecordUpdated) {
        List<String> unitUsage = new List<String>();
        Map<Integer,String> saPrioritizationValueToLabel= new Map<Integer,String>();
        List<Integer> priotityValue= new List<Integer>();
        Set<Id> unitIds = new Set<Id>();
        Set<Id> woCaseIds = new Set<Id>();
        Map<Id,String> woAssetIdUnitUsageMap= new Map<Id,String>();
        Map<Id,Case> woCaseIdCaseMap= new Map<Id,Case>();
        String unitUsageFromUnit = null;
        List <WorkOrder> updatedWoPriority = new List<WorkOrder>();
 
        try{
            //When Work Orders are Service Request...
            if(listOfSRWorkOrder!=null){
                for(WorkOrder wo :listOfSRWorkOrder){
                    woCaseIds.add(wo.CaseId);
                }
                
                Map<Id,Case> woCaseIdCaseMapQueryData= new Map<Id,Case>([SELECT id,Priority from Case where Id IN : woCaseIds]);
                
                if(!woCaseIdCaseMapQueryData.values().isEmpty()){
                    for (WorkOrder woRecord:listOfSRWorkOrder){
                        if(woCaseIdCaseMapQueryData.containsKey(woRecord.CaseId)){
                            woCaseIdCaseMap.put(woRecord.CaseId, woCaseIdCaseMapQueryData.get(woRecord.CaseId));
                        }
                    }
                }
                for(WorkOrder wo: listOfSRWorkOrder){
                    if(wo.Status!='Closed'  && wo.SvcReqAssignedMechanic__c==Null && wo.RecordTypeId!=Null){
                        if(wo.RecordTypeId==FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT_ID && wo.CaseId!=null && woCaseIdCaseMap.get(wo.CaseId).id==wo.CaseId && ((oldMap.keyset().size()>0 && wo.Priority!=oldMap.get(wo.id).Priority)||oldMap.isEmpty())){
                            if (!oldMap.isEmpty() && woCaseIdCaseMap.get(wo.CaseId).Priority=='S1 - Emergency' && wo.Priority=='S3 - Normal' && wo.Priority!=oldMap.get(wo.id).Priority) { 
                                if (wo.FS_Priority__c=='S1') { 
                                    wo.FS_Priority__c= 'S3'; 
                                }
                                else { 
                                    wo.FS_Priority__c= 'S1'; 
                                }
                            }
                            else if (!oldMap.isEmpty() && woCaseIdCaseMap.get(wo.CaseId).Priority=='S1 - Emergency' && wo.Priority=='S2 - High' && wo?.Priority!=oldMap.get(wo.id).Priority) { 
                                if (wo.FS_Priority__c=='S1') { 
                                    wo.FS_Priority__c= 'S2'; 
                                }
                                else { 
                                    wo.FS_Priority__c= 'S1'; 
                                } 
                            }
                            else if (woCaseIdCaseMap.get(wo.CaseId).Priority.equals('S1 - Emergency') ){
                                 wo.FS_Priority__c= 'S1'; 
                            }
                            else if (woCaseIdCaseMap.get(wo.CaseId).Priority.equals('S2 - High') ){
                                wo.FS_Priority__c= 'S2'; 
                            }
                            else if (woCaseIdCaseMap.get(wo.CaseId).Priority.equals('S3 - Normal') ) { 
                                wo.FS_Priority__c= 'S3'; 
                            }
                            else if (woCaseIdCaseMap.get(wo.CaseId).Priority.equals('S4 - Low') ) { 
                                wo.FS_Priority__c= 'S4'; 
                            } else { 
                                wo.FS_Priority__c= null; 
                            } 
                        } 
                    }
                }
            }
            //When Work Orders are Maintenance Plan...        
            if(listOfMPWorkOrder!=null){
                Map<String, FS_SAPrioritizationMatrix__mdt> saPrioritizationMatrixMap = new Map<String, FS_SAPrioritizationMatrix__mdt>();
                for(WorkOrder wo :listOfMPWorkOrder){
                    unitIds.add(wo.AssetId);
                }
                Map<Id,Asset> unitRecordMap =new Map<Id,Asset>([SELECT id,FS_MissedVisit__c,FS_CancellationAlert__c,FS_ProductionUnitMaintenance__c,FS_HighFrequencyUnit__c,FS_LowUsage__c,FS_CriticalUnit__c,FS_RebelUnit__c,CadencedVisits__c,ContractPenaltyUnit__c   from Asset where Id in : unitIds]);
                if(!unitRecordMap.values().isEmpty()){
                    for(WorkOrder wo : listOfMPWorkOrder){
                        if(unitRecordMap.containsKey(wo.AssetId)){
                            woAssetIdUnitUsageMap.put(wo.AssetId,FSLUtility.getUnitUsageFromUnit(unitRecordMap.get(wo.AssetId)));
                        }
                    }
                }
                
                
                for(WorkOrder wo :listOfMPWorkOrder){
                    if(woAssetIdUnitUsageMap.size()>0 && woAssetIdUnitUsageMap.containsKey(wo.AssetId)){
                        for(String unitUsageSplit : woAssetIdUnitUsageMap.get(wo.AssetId).split(',')){
                            unitUsage.add(unitUsageSplit);
                        }
                        if(wo.FS_MissedVisit__c=='Missed Visit' || wo.FS_MissedVisit__c=='Timeframe Extended'){
                            unitUsage.add('Missed Visit');
                        }
                        if(wo.VisitType__c == 'Overdue Visit' || wo.FS_Priority__c == 'Overdue Visit'){
                            unitUsage.add('Overdue Visit');
                        }
                        for(FS_SAPrioritizationMatrix__mdt obj: FS_SAPrioritizationMatrix__mdt.getAll().values()){
                            saPrioritizationMatrixMap.put(obj.Label,obj);
                        }
                        for(String eachUnitUsage:unitUsage){
                            if(saPrioritizationMatrixMap.containsKey(eachUnitUsage) && eachUnitUsage==saPrioritizationMatrixMap.get(eachUnitUsage).Label){
                                priotityValue.add(Integer.valueOf(saPrioritizationMatrixMap.get(eachUnitUsage).FS_Value__c));
                                saPrioritizationValueToLabel.put(Integer.valueOf(saPrioritizationMatrixMap.get(eachUnitUsage).FS_Value__c), saPrioritizationMatrixMap.get(eachUnitUsage).Label);
                            }   
                        }
                    }
                }
                
                if(priotityValue != NULL){
                    //sort priority value according to the number
                    priotityValue.sort();
                    //assign the value
                    for(WorkOrder wo :listOfMPWorkOrder){
                        wo.FS_Priority__c=  saPrioritizationValueToLabel.get(priotityValue.get(0));
                        updatedWoPriority.add(wo);
                    }
                    //executeInsertUpdatesetVisitTypeOnWorkOrder(updatedWoPriority,new map<Id,WorkOrder>(),isRecordUpdated);
                }
            }
        }catch(Exception e){
            Logger.logException(e);
            updatedWoPriority.clear();
        }
    }
}