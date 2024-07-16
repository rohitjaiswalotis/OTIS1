/**=========================================================================================
* Author : Sayanton Sadhu
* Version : 01
* Description: Work Order Business Service Class to store all business logic methods
* Created Date : 01-07-2024
* Last  Modified by: Debjyoti Munshi
=========================================================================================*/
/** 
* @description WorkOrder handler class to perform all actions on WorkOrder and related.
*/
public inherited sharing class FSL_WorkOrderService {
    /**  
    @description :to set the priority of work order for Service Request & Maintenance record type from ServiceAppointment Prioritization Matrix metadata
    @param:   List<WorkOrder> listOfSRWorkOrder
    @param:   List<WorkOrder> listOfMPWorkOrder
    @param:   Map<Id,WorkOrder> oldMap
    @param:   boolean isRecordUpdated
    */
    public static void setPriorityOnWorkOrder(List<WorkOrder> listOfSRWorkOrder,List<WorkOrder> listOfMPWorkOrder,Map<Id,WorkOrder> oldMap,boolean isRecordUpdated) {
        List<String> unitUsage = new List<String>();
        Map<Integer,String> saPrioritizationValueToLabel= new Map<Integer,String>();
        List<Integer> priotityValue= new List<Integer>();
        List<string> woCaseIds = new List<string>();
        List<string> woAssetIds = new List<string>();
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
                Map<Id,Case> woCaseIdCaseMapQueryData= new Map<Id,Case>(FSL_WorkOrderService.getCaseListFormWorkOrderIdList(woCaseIds));
                if(!woCaseIdCaseMapQueryData.values().isEmpty()){
                    for (WorkOrder woRecord:listOfSRWorkOrder){
                        if(woCaseIdCaseMapQueryData.containsKey(woRecord.CaseId)){
                            woCaseIdCaseMap.put(woRecord.CaseId, woCaseIdCaseMapQueryData.get(woRecord.CaseId));
                        }
                    }
                }
                for(WorkOrder wo: listOfSRWorkOrder){
                    if(wo.Status!='Closed'  && wo.SvcReqAssignedMechanic__c==Null ){
                        if(!woCaseIdCaseMap.isEmpty() && wo.CaseId!=null && woCaseIdCaseMap.get(wo.CaseId).id==wo.CaseId && ((oldMap.keyset().size()>0 && wo.Priority!=oldMap.get(wo.id).Priority)||oldMap.isEmpty())){
                            setSRPriorityOnWorkOrder(wo,woCaseIdCaseMap,oldMap);
                        } 
                    }
                }
            }
            //When Work Orders are Maintenance Plan...        
            if(listOfMPWorkOrder!=null){
                Map<String, FS_SAPrioritizationMatrix__mdt> saPrioritizationMatrixMap = new Map<String, FS_SAPrioritizationMatrix__mdt>();
                for(WorkOrder wo :listOfMPWorkOrder){
                    woAssetIds.add(wo.AssetId);
                }
                Map<Id,Asset> unitRecordMap =new Map<Id,Asset>(FSL_WorkOrderService.getAssetListFormWorkOrderIdList(woAssetIds));
                if(!unitRecordMap.values().isEmpty()){
                    for(WorkOrder wo : listOfMPWorkOrder){
                        if(unitRecordMap.containsKey(wo.AssetId)){
                            woAssetIdUnitUsageMap.put(wo.AssetId,FSLUtility.getUnitUsageFromUnit(unitRecordMap.get(wo.AssetId)));
                        }
                    }
                }
                for(WorkOrder wo :listOfMPWorkOrder){
                    if(!woAssetIdUnitUsageMap.isEmpty() && woAssetIdUnitUsageMap.size()>0 && woAssetIdUnitUsageMap.containsKey(wo.AssetId)){
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
                            if(!saPrioritizationMatrixMap.isEmpty() && saPrioritizationMatrixMap.containsKey(eachUnitUsage) && eachUnitUsage==saPrioritizationMatrixMap.get(eachUnitUsage).Label){
                                priotityValue.add(Integer.valueOf(saPrioritizationMatrixMap.get(eachUnitUsage).FS_Value__c));
                                saPrioritizationValueToLabel.put(Integer.valueOf(saPrioritizationMatrixMap.get(eachUnitUsage).FS_Value__c), saPrioritizationMatrixMap.get(eachUnitUsage).Label);
                            }   
                        }
                    }
                }
                if(priotityValue != NULL && !priotityValue.isEmpty() && !saPrioritizationValueToLabel.isEmpty()){
                    //sort priority value according to the number
                    priotityValue.sort();
                    //assign the value
                    for(WorkOrder wo :listOfMPWorkOrder){
                        wo.FS_Priority__c=  saPrioritizationValueToLabel.get(priotityValue.get(0));
                        updatedWoPriority.add(wo);
                    }
                    executeInsertUpdatesetVisitTypeOnWorkOrder(updatedWoPriority.size()>0?updatedWoPriority:new List<WorkOrder>(),isRecordUpdated?oldMap:new Map<Id,WorkOrder>(),isRecordUpdated);
                }
            }
        }catch(Exception e){
            Logger.logException(e);
            updatedWoPriority.clear();
        }
    }
    /**
    * @description:This method set Priority on Service Request WorkOrders
    * @param: Work Order variable
    * @param: Map variable of WO case Id(key) and CaseRecord(value)
    * @param: WorkOrder Old Map variable
    */
    public static void setSRPriorityOnWorkOrder(WorkOrder wo,Map<Id,Case> woCaseIdCaseMap,Map<Id,WorkOrder> oldMap) {
        
        if (!oldMap.isEmpty() && woCaseIdCaseMap.get(wo.CaseId).Priority=='S1 - Emergency' && wo.Priority!=oldMap.get(wo.id).Priority){
            switch on wo.Priority{
                when 'S3 - Normal'{
                    switch on wo.FS_Priority__c{
                        when 'S1'{
                            wo.FS_Priority__c='S3'; 
                        }
                        when else{
                            wo.FS_Priority__c='S1';
                        }
                    }
                }
                when 'S2 - High'{
                    switch on wo.FS_Priority__c{
                        when 'S1'{
                            wo.FS_Priority__c='S2'; 
                        }
                        when else{
                            wo.FS_Priority__c='S1';
                        }
                    } 
                }
            }
        }
        else if(oldMap.isEmpty() && wo.FS_Priority__c==Null){
            switch on woCaseIdCaseMap.get(wo.CaseId).Priority{
                when 'S1 - Emergency'{
                    wo.FS_Priority__c='S1';
                }
                when 'S2 - High'{
                    wo.FS_Priority__c='S2';
                }
                when 'S3 - Normal'{
                    wo.FS_Priority__c='S3';
                }
                when 'S4 - Low'{
                    wo.FS_Priority__c='S4';
                }
            }
        }
    }
    /*
    * @Description:This method sets FS_Priority on maintenace Workorder based on TaskType from WorkType, Respecting Prioritization matrix
    * @Param : List of Work Orders , Map Of Work Order with ID and a boolean variable to check if the record is updated or not . 
    */
   	public static void executeInsertUpdatesetVisitTypeOnWorkOrder(List<WorkOrder> woList, Map<id,workorder> oldMap, boolean isRecordUpdated){
        try{
            //Variable declaration
            Set<id> woTypeIds = new Set<id>();
            Set<id> woOldTypeId = new Set<id>();
            Map<String, String> taskTypeToPriority = new Map<String, String>{'Test' => 'Testing Visits','Door Procedure Visit' => 'Door Procedure Visits','Maintenance' => 'Regular Maintenance'};
                Set<String> priorityExceptions = new Set<String>{'Contract Penalty Unit', 'Critical Unit', 'Rebel Unit', 'Cadenced Visits'};   
                    //Checking for priority Change on WO  and adding WoTypeIds
                    for(Workorder wo:woList){
                        if(!oldMap.Values().isEmpty() && wo.FS_priority__c !=oldMap.get(Wo.Id).FS_Priority__c){
                            woTypeIds.add(wo.workTypeId);
                        }else{ 
                            woTypeIds.add(wo.workTypeId);
                        }
                    } 
            Map<Id,WorkType> workTypes = new Map<id, WorkType>([SELECT Id, TaskType__c FROM WorkType WHERE Id IN :woTypeIds]);
            //Logic for record Insert
            If(!workTypes.values().isEmpty()&& !isRecordUpdated){     
                for(WorkOrder wo:woList){
                    WorkType workType = workTypes.get(wo.WorkTypeId);
                    if(!priorityExceptions.contains(wo.FS_Priority__c)){
                        String newPriority = taskTypeToPriority.get(workType.TaskType__c);
                        if(newPriority != null){
                            wo.FS_Priority__c = newPriority;                       
                        } 
                    }
                }
            }
            // Logic for Record is updated
            If(!workTypes.values().isEmpty()&& isRecordUpdated){
                for(WorkOrder wo:woList){
                    WorkType workType = workTypes.get(wo.WorkTypeId);
                    if(!priorityExceptions.contains(Wo.FS_Priority__c)){
                        if(workType.TaskType__c=='Test' || workType.TaskType__c=='Door Procedure Visit'|| workType.TaskType__c=='Maintenance'){  
                            If (workType.TaskType__c=='Test'){    
                                wo.FS_Priority__c='Testing Visits';
                            }
                            else If (wo.FS_Priority__c != 'Overdue Visit' && workType.TaskType__c=='Door Procedure Visit'){    
                                wo.FS_Priority__c='Door Procedure Visits'; 
                            }
                            else if (wo.FS_Priority__c == null && workType.TaskType__c=='Maintenance'){
                                wo.FS_Priority__c = 'Regular Maintenance';
                            }
                        } 
                    }
                }
            }
        }catch(Exception ex){
            Logger.logException(ex);
        }
    }
    
    /*
    * @Description:This method setsSubject of the WO before the Insert
    * @Param : List of Work Orders
    */
    public static void setFSLWorkOrderSubjectBeforeInsert(List<WorkOrder> workOrderList){
        try{
            // Get the IDs of the related WorkType records
            Set<Id> workTypeIds = new Set<Id>();
            
            for (WorkOrder wo : workOrderList) {
                if (wo.WorkTypeId != null) {
                    workTypeIds.add(wo.WorkTypeId);
                }
            }  
            // Query the WorkType records
            Map<Id, WorkType> workTypes = new Map<Id, WorkType>([SELECT Id, Name, Description FROM WorkType WHERE Id IN :workTypeIds]);
            
            // Update the Subject and Description fields of the WorkOrder records
            for (WorkOrder wo : workOrderList) {
                if (wo.WorkTypeId != null) {
                    WorkType wt = workTypes.get(wo.WorkTypeId);
                    if (wt != null) {
                        wo.Subject = wt.Name;
                        wo.Description = wo.Description !=null ? wo.Description: wt.Description;
                    }
                }
            }
        }
        catch(Exception e){
            Logger.logException(e);
        }
    }
    
    /*
    * @Description: This method sets Entitlements on Service Request Workorder
    * @Param : List of Work Orders
    */
   	public static void setEntitlementFieldsOnSRWO(List<WorkOrder> woList){
        try{
            Set<Id> woAssetIds = new Set<Id>();
            List<WorkOrder> updatedwoRecords=new List<WorkOrder>();
            Map<Id,Asset> woIdAssetMap= new Map<Id,Asset>();
            Map<Id,String> accountIdVSaccount= new Map<Id,String>();
            List<workOrder> updateWorkOrder = new List<workOrder>();
            List<Entitlement> enTitlementList= new List<Entitlement>();
            String intOne,intTwo,trapped;
            Map<Id,Entitlement> assetIdToEntitlement=  new Map<Id,Entitlement>();
            if(woList!=null){
                for(WorkOrder wo :woList){
                    woAssetIds.add(wo.AssetId);
                }
            }
            enTitlementList=[Select Id, AssetId from Entitlement where status='Active' And AssetId In: woAssetIds];
            for(Entitlement et:enTitlementList){
                assetIdToEntitlement.put(et.AssetId,et);
            }
            Map<Id,Asset> woIdUnitMapQueryData= new Map<Id,Asset>([SELECT id,Name,AccountId,FS_UnitCompany__c,Account.Name from Asset where Id IN : woAssetIds]);
            if(!woIdUnitMapQueryData.values().isEmpty()){
                for(Asset ast : woIdUnitMapQueryData.values()){
                    accountIdVSaccount.put(ast.AccountId,ast.Account.Name);
                }
            }
            List<ServiceContract> scRelatedToUnit=new List<ServiceContract>([Select id, status,Unit__c from ServiceContract where Unit__c IN :woAssetIds]);
            Map<Id,FS_OTISCompanyWideSettings__mdt> otisCompanyMdt= new Map<Id,FS_OTISCompanyWideSettings__mdt>([Select Id,Label,DeveloperName,FS_DefaultT1Minutes__c,FS_DefaultT2Minutes__c,FS_DefaultTPRMinutes__c from FS_OTISCompanyWideSettings__mdt]);
            Map<String,FS_OTISCompanyWideSettings__mdt> unitCompanyMdt= new Map<String,FS_OTISCompanyWideSettings__mdt>();
            
            for(FS_OTISCompanyWideSettings__mdt obj: otisCompanyMdt.values()){
                unitCompanyMdt.put(obj.Label,obj);
            }            
            if(!woIdUnitMapQueryData.values().isEmpty()){
                for (WorkOrder woRecord:woList){
                    if(woIdUnitMapQueryData.containsKey(woRecord.AssetId)){
                        woIdAssetMap.put(woRecord.AssetId, woIdUnitMapQueryData.get(woRecord.AssetId));
                    }
                }
            }
            
            //if SC Present not present on unit 
            if(scRelatedToUnit.isEmpty()){
                
                //if entitlement is preset 
                if(!enTitlementList.isEmpty()){
                    
                    for(WorkOrder wo:woList){
                        if(assetIdToEntitlement.containsKey(wo.assetId) && (woIdAssetMap.get(wo.Assetid).FS_UnitCompany__c==unitCompanyMdt.get(woIdAssetMap.get(wo.Assetid).FS_UnitCompany__c).Label && wo.AssetId==woIdAssetMap.get(wo.Assetid).Id)){
                            wo.EntitlementId=assetIdToEntitlement.get(wo.assetId).id;
                            wo.T1_mins__c=unitCompanyMdt.get(woIdAssetMap.get(wo.Assetid).FS_UnitCompany__c).FS_DefaultT1Minutes__c;
                            wo.T2_mins__c=unitCompanyMdt.get(woIdAssetMap.get(wo.Assetid).FS_UnitCompany__c).FS_DefaultT2Minutes__c;
                            wo.TPR__c=unitCompanyMdt.get(woIdAssetMap.get(wo.Assetid).FS_UnitCompany__c).FS_DefaultTPRMinutes__c;
                            updateWorkOrder.add(wo);
                        }
                    }
                }
                //If entitlement is not present
                else{
                    updateWorkOrder=createEntitlementRecordOnSRWO(woList,woIdUnitMapQueryData,accountIdVSaccount,assetIdToEntitlement,unitCompanyMdt);
                }
            }
            //if SC Present on unit 
            else{
                Map<Id,Id> assetIdContractId = new Map<Id,Id>();
                Map<Id,List<String>> assetIdWithCliString = new Map<Id,List<String>>();
                for(ServiceContract sc : scRelatedToUnit){
                    assetIdContractId.put(sc.Id,sc.Unit__c);
                }
                List<ContractLineItem> cliList=new List<ContractLineItem>([Select id,assetId, Name__c,FS_SalesContractLineItem__c,FS_SalesContractLineItem__r.FS_OptionCategory__c,ServiceContract.Unit__c from ContractLineItem 
                                                                           where (Name__c LIKE 'TPA%' OR Name__c LIKE 'INT1%' OR Name__c LIKE 'INT2%') AND ServiceContractId in : scRelatedToUnit]);
                String weekDay= FSLUtility.getWeekDay();
                List<String> cliNames= new List<String>();
                string tpr;
                string int1;
                string int2;
                for(ContractLineItem clis :cliList){
                    if((clis.Name__c).contains('MF') && (weekDay=='Mon' || weekDay=='TUE'|| weekDay=='WED'|| weekDay=='THU'|| weekDay=='FRI') && clis.FS_SalesContractLineItem__r.FS_OptionCategory__c=='KeyAccount_SLA' ){
                        cliNames.add(clis.Name__c);
                    }
                    else if((clis.Name__c).contains('SAT') &&  weekDay=='SAT' && clis.FS_SalesContractLineItem__r.FS_OptionCategory__c=='KeyAccount_SLA' ){
                        cliNames.add(clis.Name__c);
                    }
                    else if((clis.Name__c).contains('SUN') &&  weekDay=='SUN' && clis.FS_SalesContractLineItem__r.FS_OptionCategory__c=='KeyAccount_SLA' ){
                        cliNames.add(clis.Name__c); 
                    }
                    assetIdWithCliString.put(assetIdContractId.get(clis.ServiceContractId),cliNames);
                    
                }
                
                for(WorkOrder woUpdate:woList){
                    if(assetIdWithCliString.containsKey(woUpdate.AssetId)){
                        for(String cliName: assetIdWithCliString.get(woUpdate.AssetId)){
                            if(cliname.startsWith('TPA')){
                                tpr= cliName;
                                trapped=tpr.right(2);
                            }else if(cliname.startsWith('INT1')){
                                int1= cliName;
                                intOne=int1.right(2);
                            }else{
                                int2= cliName; 
                                intTwo=int2.right(3);
                            }
                            
                        }
                        woUpdate.T1_mins__c=Integer.valueOf(intOne);
                        woUpdate.T2_mins__c=Integer.valueOf(intTwo);
                        woUpdate.TPR__c=Integer.valueOf(trapped);
                        updatedwoRecords.add(woUpdate);
                    }
                }
            }            
            //Assign Entitilement to Triggering Wo
            List<WorkOrder> updatedWoWithEntitlementList=new List<WorkOrder>();
            for(WorkOrder updatedWoWithEntitlement:updatedwoRecords){
                if(!woIdAssetMap.isEmpty() && woIdAssetMap.containsKey(updatedWoWithEntitlement.AssetId) && updatedWoWithEntitlement.assetId==woIdAssetMap.get(updatedWoWithEntitlement.AssetId).id){
                    if(!assetIdToEntitlement.isEmpty() && assetIdToEntitlement.containsKey(woIdAssetMap.get(updatedWoWithEntitlement.AssetId).id)){
                        updatedWoWithEntitlement.EntitlementId=assetIdToEntitlement.get(updatedWoWithEntitlement.AssetId).Id;
                        updatedWoWithEntitlementList.add(updatedWoWithEntitlement);
                    }
                }
            }
        }
        catch(Exception e){
            Logger.error(e.getMessage());
        }
    }

     /*
    * @Description: This method will create Entitlement
    */    
    public static list<workorder> createEntitlementRecordOnSRWO(list<WorkOrder> woList,Map<Id,Asset> woIdUnitMapQueryData, Map<Id,String> accountIdVSaccount, Map<Id,Entitlement> assetIdToEntitlement,Map<String,FS_OTISCompanyWideSettings__mdt> unitCompanyMdt){
        
        List<Entitlement> insertEntitlementList= new List<Entitlement>();
        List<workorder> updateWorkOrder= new List<workorder>();
        
        //Get SLA ProcessID
        list<SlaProcess> entitlementProcess = new list<SlaProcess>();
        entitlementProcess=[select id , Name , isActive from SlaProcess where Name='emea entitlement process' AND isActive=true LIMIT 1]; 
        //create Entitlement record
        for(WorkOrder wo:woList){
            string assetName = woIdUnitMapQueryData.containskey(wo.AssetId)?(woIdUnitMapQueryData.get(wo.AssetId).Name):'';
            string accountName = woIdUnitMapQueryData.containskey(wo.AssetId)? accountIdVSaccount.get(woIdUnitMapQueryData.get(wo.AssetId).accountId):'';
            If(wo.AssetId==woIdUnitMapQueryData.get(wo.AssetId).id){
                Entitlement et = new Entitlement();
                et.Accountid=wo.accountid;
                et.AssetId=wo.AssetId;
                et.Name= accountName+'-'+assetName+'-'+'SR';
                et.SlaProcessId=EntitlementProcess[0].id;
                et.StartDate=Date.today();  
                insertEntitlementList.add(et);
            }
        }
        if(insertEntitlementList!=null){
            if (Entitlement.sObjectType.getDescribe().isCreateable()){
            	Database.insert(insertEntitlementList,false);
            }
            
        }
        
        for(Entitlement et : insertEntitlementList){
            assetIdToEntitlement.put(et.AssetId,et);
        }
        //Update Inserted WorkOrder   
        for(WorkOrder wo:woList){
            wo.EntitlementId=  assetIdToEntitlement.containskey(wo.AssetId)?assetIdToEntitlement.get(wo.AssetId).id:NULL;
            wo.T1_mins__c=unitCompanyMdt.get(wo.id).FS_DefaultT1Minutes__c;
            wo.T2_mins__c=unitCompanyMdt.get(wo.id).FS_DefaultT2Minutes__c;
            wo.TPR__c=unitCompanyMdt.get(wo.id).FS_DefaultTPRMinutes__c;
            updateWorkOrder.add(wo);
        }
        return updateWorkOrder;
    } 
    
    /*
    * @Description: System to update default values in T1,T2 and TPR fields based on feature flag and Service contract
    */ 

    public static void setDefaultEntitlementFieldsOnSRWO(List<WorkOrder> workorderList){
        Set<Id> unitIDSet = new Set<Id>();
        FSL_FeatureFlag__mdt featureCompanyWideDefaultEntitlement= FSLUtility.getFeatureFlagDetails(FSLConstantClass.FEATURE_COMPANY_WIDE_DEFAULT_ENTITLEMENTS);
        Map<Id,String> unitCountryMap = new Map<Id,String>();
        for(WorkOrder wo : workorderList){
            unitIDSet.add(wo.AssetId);
        }
        Map<Id,Asset> unitMap = new Map<Id,Asset>([Select id, FS_CurrentServiceContract__c,FS_UnitCompany__c from Asset where id in: unitIDSet]);
        
        for(Asset ast : unitMap.values()){
            unitCountryMap.put(ast.Id,ast.FS_UnitCompany__c);
            unitMap.put(ast.ID,ast);
        }
        if(featureCompanyWideDefaultEntitlement !=Null && featureCompanyWideDefaultEntitlement.isActive__c){
            setDefaultAssignments(workorderList,unitCountryMap);
        }else if(featureCompanyWideDefaultEntitlement !=Null && !featureCompanyWideDefaultEntitlement.isActive__c){
            list<WorkOrder> woWithSR = new List<WorkOrder>();
            list<WorkOrder> woWithoutSR = new List<WorkOrder>();
            for(WorkOrder wod : workorderList){
                ID srId = unitMap.get(wod.AssetID).FS_CurrentServiceContract__c;
                if(srId == Null){
                    woWithoutSR.add(wod);
                }else{
                    woWithSR.add(wod);
                }
            }
            if(woWithoutSR != Null && woWithoutSR.size()>0){
                setEntitlementFieldsOnSRWO(woWithoutSR);
            }
            if(woWithSR != Null && woWithSR.size()>0){
                setEntitlementFieldsOnSRWO(woWithSR);
            }            
        }
    }
    
    
    /*
    * @Description: System to update default values
    */ 
    public static void setDefaultAssignments(List<WorkOrder> workorderList, Map<Id,String> unitCountryMap){       
        Map<String,FS_OTISCompanyWideSettings__mdt> CompanyWideSettings= new Map<String,FS_OTISCompanyWideSettings__mdt>();
        for(FS_OTISCompanyWideSettings__mdt obj: FS_OTISCompanyWideSettings__mdt.getAll().values()){
            CompanyWideSettings.put(obj.Label,obj);
        }    
        for(WorkOrder wo : workorderList){
           if(!unitCountryMap.isEmpty() && unitCountryMap.keySet().contains(wo.AssetID) && !CompanyWideSettings.isEmpty() && CompanyWideSettings.get(unitCountryMap.get(wo.AssetId)) != Null && unitCountryMap.get(wo.AssetId) == CompanyWideSettings.get(unitCountryMap.get(wo.AssetId)).Label){
                wo.T1_mins__c=CompanyWideSettings.get(unitCountryMap.get(wo.AssetId)).FS_DefaultT1Minutes__c;
                wo.T2_mins__c=CompanyWideSettings.get(unitCountryMap.get(wo.AssetId)).FS_DefaultT2Minutes__c;
                wo.TPR__c=CompanyWideSettings.get(unitCountryMap.get(wo.AssetId)).FS_DefaultTPRMinutes__c;      
            }
        }        
    }
    
    // Business Logic: When Work Order Status is closed then WorkOrderClosureDate__c will be updated automatically with today's date.
    public static void setWorkOrderClosureDate(List<WorkOrder> recordList,Map<Id,WorkOrder> oldRecordMap,Boolean isInsert, Boolean isUpdate){
        if(FSLUtility.getFeatureStatus(FSLConstantClass.FEATURE_POPULATE_CLOSURE_DATE_ON_WORKORDER, isInsert, isUpdate)){
            for(WorkOrder wo : recordList){
                String OldStatus = oldRecordMap.get(wo.ID).Status;
                if(wo.status== 'Closed' && OldStatus != 'Closed'){
                    wo.WorkOrderClosureDate__c = Date.Today();
                }
                
            }
        }
    }

	/*
	 * @Description : Wrapper Class
	*/    
    public class FSLWorkOrderServiceWrapper{
        public Map<Id,WorkOrder> newMapValues { get; set; }
        public Map<Id,WorkOrder> oldMapValues { get; set; }
        public List<WorkOrder> newListValuesWithCombinedRT { get; set; }
        
        public FSLWorkOrderServiceWrapper(Map<Id,sobject> newMapValues,Map<Id,sobject> oldMapValues){
            this.newMapValues = new Map<Id,WorkOrder>(FSLUtility.convertSobjToRecordObjMap(FSLConstantClass.WORK_ORDER_OBJECT_NAME,newMapValues));
            this.oldMapValues = new Map<Id,WorkOrder>(FSLUtility.convertSobjToRecordObjMap(FSLConstantClass.WORK_ORDER_OBJECT_NAME,oldMapValues));
            this.newListValuesWithCombinedRT = new List<WorkOrder>();
           	
            this.newListValuesWithCombinedRT.addAll(this.newMapValues.values());
        }
        
    }
    
    //Method to get WorkOrder List using query helper metadata      
    public static List<WorkOrder> getWorkOrderListFormWorkOrderIdSet(Set<Id> workOrderIdSet, String queryHelperMetaDataName){
        // Build the query from Query Helper metadata and where clause logic sent as parameter.
        
        //Fetch the Queryhelper record
        FSL_QueryHelper__mdt queryHelperRecord =FSLUtility.getRecordQueryHelperMetadata('Get_WorkOrderWithId');
        
        //Query formation
        String soqlQuery = 'SELECT Id,' + queryHelperRecord.Field_API_Names__c +' FROM ' + queryHelperRecord.sObject__c +' Where Id IN :workOrderIdSet' ;
        
        return Database.query(soqlQuery);
    }
    public static List<Case> getCaseListFormWorkOrderIdList(List<string> caseIdList){
        // Build the query from Query Helper metadata and where clause logic sent as parameter.
        
        //Fetch the Queryhelper record
        FSL_QueryHelper__mdt queryHelperRecord =FSLUtility.getRecordQueryHelperMetadata('Get_case_with_WorkOrderId');
        
        //Query formation
        String soqlQuery = 'SELECT Id,' + queryHelperRecord.Field_API_Names__c +' FROM ' + queryHelperRecord.sObject__c +' WHERE Id IN (\'' + String.join(caseIdList, '\',\'') + '\')';
        
        return Database.query(soqlQuery);
    }
    public static List<Asset> getAssetListFormWorkOrderIdList(List<string> assetIdList){
        // Build the query from Query Helper metadata and where clause logic sent as parameter.
        
        //Fetch the Queryhelper record
        FSL_QueryHelper__mdt queryHelperRecord =FSLUtility.getRecordQueryHelperMetadata('Get_Asset_with_WorkOrderCaseId');
        
        //Query formation
        String soqlQuery = 'SELECT Id,' + queryHelperRecord.Field_API_Names__c +' FROM ' + queryHelperRecord.sObject__c +' WHERE Id IN (\'' + String.join(assetIdList, '\',\'') + '\')';
        
        return Database.query(soqlQuery);
    }
    //This method will set DefaultWorkTypeOnWorkOrder for Service Request Record type if work type is null
    public static void SetDefaultWorkTypeOnWorkOrder(List<WorkOrder> newList){
        List<WorkType> assignWorkTypeList = [SELECT Id,Name FROM WorkType WHERE Name='Default Work Type'];
        if(newList !=null && !newList.IsEmpty()){
            for(WorkOrder wo: newList) {   
                if(FSLUtility.isWOWorkTypePresent(wo)== false && FSLUtility.getWORecordType(wo) == true){
                    wo.WorkTypeId = !assignWorkTypeList.IsEmpty() &&assignWorkTypeList!= Null? assignWorkTypeList[0].id:wo.WorkTypeId;
                }
            }
        }
    }
    
    /*
	* @Description: This method gives an error message when a WO is canceled with Inprogress SA / completed SA
	* @Param : List of Work Orders, Map of id and Workorder
	*/
    public static void showErrorMessageOnWOCancellation(List<WorkOrder> cancelledWOList,Map<Id,WorkOrder> oldRecordMap){
        try{
            List <string> cancelledWOIdList = new List <string>();
            String oldStatus; 
            for( Workorder wo : cancelledWOList){
                oldStatus = oldRecordMap.get(wo.ID).Status;
                if(wo.status == FSLConstantClass.WORK_ORDER_STATUS_CANCELED && oldStatus != FSLConstantClass.WORK_ORDER_STATUS_CANCELED){
                    cancelledWOIdList.add(wo.id);
                }
            }
            List<ServiceAppointment> saFilteredListOfCancelledWo = new List<ServiceAppointment> ();
            if(cancelledWOIdList != null && !cancelledWOIdList.isEmpty()){
                saFilteredListOfCancelledWo = FSL_WorkOrderService.getServiceAppointmentListFromCancelWorkOrder(cancelledWOIdList);
            }     
            if(saFilteredListOfCancelledWo!= null &&!saFilteredListOfCancelledWo.isEmpty()){        
                set<id> cancelledWOIdWithSa = new set<id>();
                for( ServiceAppointment sa : saFilteredListOfCancelledWo){
                    if(cancelledWOIdList.Contains(sa.parentrecordid)){
                        cancelledWOIdWithSa.add(sa.parentrecordid);}
                }
                for (WorkOrder wo : cancelledWOList){
                    if(cancelledWOIdWithSa.contains(wo.id)) {
                        wo.status.addError(Label.Cannot_Cancel_WO_With_Appointment_Validation_Message); 
                    }
                }
            }
        }
        catch(Exception e){
            Logger.error(e.getMessage());
        }
	}
	
	/*
	* @Description: This method gives List of Inprogress SA / completed SA for given list of Workorders
	* @Param : List of Work Orders id as string
	*/
    public static List<ServiceAppointment> getServiceAppointmentListFromCancelWorkOrder( List <string> cancelledWOIdList){
        List<ServiceAppointment> saFilteredList = new List<ServiceAppointment>();
        String StatusWhereClause = ' Status IN (\''+FSLConstantClass.SERVICE_APPOINTENT_STATUS_ENROUTE+'\',\''+FSLConstantClass.SERVICE_APPOINTENT_STATUS_ONSITE+'\',\''+FSLConstantClass.SERVICE_APPOINTENT_STATUS_COMPLETED+'\')'; 
        saFilteredList = FSL_ServiceAppointmentService.getServiceAppointmentListFormWorkOrderIdList(cancelledWOIdList,StatusWhereClause);
        return saFilteredList;     
    }

    /*
    @description : This flow is populating Assignment Type in Work Order based on Work Type for Service Request and Maintenance record Type.
    Also set Work Order record type based on FS_WorkOderType__c field of WO.
    @param : List Of WorkOrder and Map of Id and Profiles 
    */
    public static List<WorkOrder> setAssignmentTypeOnWO(List<WorkOrder> listOfAllWorkOrder,Map<Id,Profile> profileDetailsMap){
        Set<id>wTId =new Set<id>();
        List<WorkOrder>allWORecord;
        List<WorkOrder>allWORecordList=new List<WorkOrder>();
        
        
        if(!listOfAllWorkOrder.isEmpty()){
            allWORecord =new List<WorkOrder>(FSLUtility.isWorkOrderAssignmentTypePresent(listOfAllWorkOrder,profileDetailsMap));
            
            for(WorkOrder obj :allWORecord){
                wTId.add(obj.workTypeId);
            }
        }
        
        if(!wTId.isEmpty()){
            Map<Id , WorkType> mapofWorkType = new Map<Id , WorkType>([Select Id,FS_AutoSchedule__c  from WorkType where Id in :wTId]); 
            
            for(WorkOrder wo: allWORecord){
                wo.AssignmentType__c=FSLUtility.getWorkTypeAssignmentType(mapofWorkType.get(wo.WorkTypeId));
                allWORecordList.add(wo);
            }
        }
        
        return allWORecordList;
    }
    
    /*
    * @DesCription: THis Method will Check and filter out Non Classic Record TYpe Record and Set the Record TYpe
    *@param : List of WorkOrder and Map Of Id and profile
    */
    public static List<WorkOrder> setRecordTypeOnWO(List<WorkOrder> listOfAllWorkOrder,Map<Id,Profile> profileDetailsMap){
        List<Id>listOfWOId = new  List<Id>();  
        List<WorkOrder>listOfWOWithRTId =new  List<WorkOrder>();
        List<WorkOrder>listOfNewWOWithRTID =new  List<WorkOrder>();
        List<WorkOrder>listOfFinalWithRT= new List<WorkOrder>();
       
        
        Map<Id , Asset> mapOfIdWithAsset;
        for(WorkOrder obj: listOfAllWorkOrder){
            if(obj.RecordTypeId!=FSLConstantClass.WORK_ORDER_CLASSIC_RECORD_TYPE_ID){
                listOfWOWithRTId.add(obj);
                listOfWOId.add(obj.AssetId);
            }
        }
        
        if(!listOfWOId.isEmpty()){
            mapOfIdWithAsset=new Map<Id , Asset>([Select Id ,Branch__c , Branch__r.FSLEnabled__c From Asset where Id IN :listOfWOId]);
            System.debug('Map :' +mapOfIdWithAsset );
            if(!listOfWOWithRTId.isEmpty()){
                for(WorkOrder wo : listOfWOWithRTId){
                    if(mapOfIdWithAsset.get(wo.AssetId).Branch__r.FSLEnabled__c){
                        wo.RecordTypeId = FSLUtility.isMaintenanceORServiceRequestWO(wo);
                        listOfNewWOWithRTID.add(wo);
                    }
                }
            }
            
            listOfFinalWithRT = new List<WorkOrder>(setAssignmentTypeOnWO(listOfNewWOWithRTID,profileDetailsMap));
        }
        return listOfFinalWithRT;
    }
}