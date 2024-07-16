/**=========================================================================================
* Author : 
* Version : 01
* Description: OTIS Route Reassignment Handler Class to store all business logic methods
* Created Date : 10-07-2024
* Last Modified Date: 
=========================================================================================*/
public class FSLRouteReassignmentHandlerQueueable implements Queueable{
    public List<Asset> newAssetRecords;
    public Map<Id,Asset> oldAssetRecMap;
    static final List<String> workOrdRTNames = new List<String> {'Service Request','Maintenance'};
    static Map<Id,List<RouteResource__c>> unitIdVsListServResIdMap = new Map<Id,List<RouteResource__c>> ();
    
    public FSLRouteReassignmentHandlerQueueable(List<Asset> newAsstRecds, Map<Id,Asset> oldAsstRecMap){
        this.newAssetRecords = newAsstRecds;
        this.oldAssetRecMap = oldAsstRecMap; 
    }
    
    public void execute(QueueableContext context) {
        system.debug('****newAssetRecords'+newAssetRecords);
        system.debug('****oldAssetRecMap'+oldAssetRecMap);
        handleRouteReassignmentOperation(newAssetRecords,oldAssetRecMap,null);
    }
    
/**=========================================================================================
* Method Author : Yaswanth
* Method Description: Utility Method for handling Resource Preferences Modification
=========================================================================================*/
    public static void handleResourcePreferenceOperations(Set<Id> recordIds,String operation,Map<Id,List<RouteResource__c>> unitIdVsListServResIdMap){
        if(operation.equalsIgnoreCase('Delete'))        {
            List<ResourcePreference> resPrefRecords = [Select Id from ResourcePreference where RelatedRecordId In :recordIds];
            system.debug('****resPrefRecords'+resPrefRecords);
            Database.Delete(resPrefRecords);
        }
        else if(operation.equalsIgnoreCase('Create')){
            List<ResourcePreference> newResPrefList = new List<ResourcePreference>();
            for (Id unitId : unitIdVsListServResIdMap.keySet()){
                for(RouteResource__c routeRes : unitIdVsListServResIdMap.get(unitId)){
                    newResPrefList.add(new ResourcePreference(RelatedRecordId = unitId,
                                                              PreferenceType = routeRes.PreferenceType__c,
                                                              ServiceResourceId = routeRes.ServiceResource__c));
                }
            }
            Database.SaveResult[] saveResult = Database.Insert(newResPrefList,false);
            system.debug('saveResult ::'+saveResult);
        }
    }
    /**=========================================================================================
* Method Author : Rajat Jaiswal 
* Method Description: Automation for handling common actions for Route Reassignment
=========================================================================================*/
    public static void handleCommonRouteReassignmentOperations(List<Asset> newUnitRecords){
        Map<Id,Asset> newAssetMap = new Map<Id,Asset>(newUnitRecords);
        system.debug('$$$newAssetMap--'+newAssetMap);
        Map<Id,List<String>> routeIdVsListUnitIdMap = new Map<Id,List<String>> ();
        
        for (Asset unitRec : newUnitRecords){
            if(unitRec?.NextRoute__c != unitRec?.Account?.Next_Route__c && unitRec?.NextRoute__c != unitRec?.Location?.NextRoute__c){
                if(!routeIdVsListUnitIdMap.containskey(unitRec?.NextRoute__c)){
                    routeIdVsListUnitIdMap.put(unitRec.NextRoute__c,new List<String>{unitRec.Id});
                }
                else{
                    List<String> unitIds = new List<String>{unitRec.Id};
                        unitIds.addAll(routeIdVsListUnitIdMap.get(unitRec?.NextRoute__c));
                    routeIdVsListUnitIdMap.put(unitRec.NextRoute__c,unitIds);
                }
            }
        }
        
        system.debug('routeIdVsListUnitIdMap ::'+routeIdVsListUnitIdMap);
        
        for (RouteResource__c routeResRec : [Select Id,ServiceResource__c,Route__c,PreferenceType__c from RouteResource__c Where Route__c IN :routeIdVsListUnitIdMap.keySet()]){
            if(routeIdVsListUnitIdMap.containsKey(routeResRec?.Route__c) && String.isNotBlank(routeResRec?.ServiceResource__c)){
                for(String assetId : routeIdVsListUnitIdMap.get(routeResRec.Route__c)){
                    if(!unitIdVsListServResIdMap.containsKey(assetId)){
                        unitIdVsListServResIdMap.put(assetId,new List<RouteResource__c>{routeResRec});
                    }
                    else{
                        List<RouteResource__c> routeResRecs = new List<RouteResource__c>{routeResRec};
                            routeResRecs.addAll(unitIdVsListServResIdMap.get(assetId));
                        unitIdVsListServResIdMap.put(assetId,routeResRecs);
                    }
                }
            }
        }
        system.debug('unitIdVsListServResIdMap ::'+unitIdVsListServResIdMap);
    }
    /**=========================================================================================
* Method Author : Udit Sharma
* Method Description: Automation for handling impacted Work Order and Service Appointments
=========================================================================================*/
    public static void handleImpactedWOAndSARecords(List<WorkOrder> woList){
        System.debug('^^^woList: '+woList);
        List<ResourcePreference> clonedResPrefList = new List<ResourcePreference>();
        Map<Id,Id> woIdVsRelID = new Map<Id,Id>();
        Map<Id,List<ResourcePreference>> reIDvListRP = new Map<Id,List<ResourcePreference>>();
        Set<Id> workOrdIds = new Set<Id>();
        for(WorkOrder wo: woList){
            workOrdIds.add(wo.id);
        }
        System.debug('^^^workOrdIds: '+workOrdIds);
        
        if(!workOrdIds.isEmpty()){
            handleResourcePreferenceOperations(workOrdIds,'Delete',null);
        }
        
        //Set the RelatedRecordId to further Fetch the Resource Preference.
        for(WorkOrder workOrder: woList){           
            if(workOrder?.Asset?.NextRoute__c == workOrder?.Asset?.Account?.Next_Route__c){
                woIdVsRelID.put(workOrder.Id,workOrder?.Asset?.Location?.Account__c);
                System.debug('^^^Inside Account Condition');
            }
            else if(workOrder?.Asset?.NextRoute__c == workOrder?.Asset?.Location?.NextRoute__c){
                woIdVsRelID.put(workOrder.Id,workOrder?.Asset?.LocationId);
                System.debug('^^^Inside Building Condition');
            }
            else{
                System.debug('^^^Inside Unit Condition');
                woIdVsRelID.put(workOrder.Id,workOrder?.AssetId);
            }
        }
        System.debug('^^^woIdVsRelID: '+woIdVsRelID);
        //Get all the Resource Preference from the Related Record Id.
        
        for(ResourcePreference resPref : [SELECT Id,PreferenceType,RelatedRecordId,ResourcePreferenceNumber,ServiceResource.Name,ServiceResourceId FROM ResourcePreference where RelatedRecordId =:woIdVsRelID.values()]){
            Id relatedRec = resPref.RelatedRecordId;
            if(reIDvListRP.containsKey(relatedRec)){
                reIDvListRP.get(relatedRec).add(resPref);
            }
            else{
                reIDvListRP.put(relatedRec, new List<ResourcePreference>{resPref});
            }
        }
        System.debug('^^^reIDvListRP: '+reIDvListRP);
        
        //Loop the WorkOrder KeySet from Map
        for(Id wo: woIdVsRelID.KeySet()){
            Id relatedRec = woIdVsRelID.get(wo);
            if(reIDvListRP.containsKey(relatedRec)){
                List<ResourcePreference> rpListNew = reIDvListRP.get(relatedRec);
                for(ResourcePreference rpClone : rpListNew){
                    ResourcePreference newRp = rpClone.clone(false, true, false, false);               
                    newRp.RelatedRecordId = wo;
                    clonedResPrefList.add(newRp);
                }
            }
        }
        System.debug('^^^clonedResPrefList: '+clonedResPrefList);
        
        //Insert the Cloned Resource Prefrence for Each Work ORder.
        Database.insert(clonedResPrefList,false);
    }
    
    /**=========================================================================================
* Method Author : Shivam Lachure
* Method Description: Automation to handle WO/SA Reset for Service Territory Change
=========================================================================================*/
    public static void resetWOAndSARecords(List<WorkOrder> wolist, Map<Id,ServiceAppointment> workOrdIdVsSerAppMap,List<Asset> newUnitList,Boolean impactedWO){
        system.debug('***wolist'+wolist);
        system.debug('***workOrdIdVsSerAppMap'+workOrdIdVsSerAppMap);
        system.debug('***newUnitList'+newUnitList);
        
        List<ServiceAppointment> updateSARecs=new List<ServiceAppointment>();
        List<WorkOrder> updateWO=new List<WorkOrder>(); 
        List<Asset> updateUnits=new List<Asset>();
        List<Schema.Location> updateLocations=new List<Schema.Location>();
        List<Account> updateAccounts=new List<Account>();
        
       //Replace the Duplicate WO 
       set<WorkOrder> workReclist=new set<WorkOrder>();
       workReclist.addAll(wolist);
        
        for(WorkOrder workOrdRec: workReclist){
            System.debug('Get Condition: '+workOrdIdVsSerAppMap.containskey(workOrdRec.Id));
            System.debug('Condition 2: '+workOrdIdVsSerAppMap.get(workOrdRec.Id)?.FSL__Pinned__c);
            System.debug('Condition 3'+workOrdIdVsSerAppMap.get(workOrdRec.Id)?.FSL__Schedule_Mode__c.equalsIgnoreCase('Automatic'));
            if (workOrdIdVsSerAppMap.containskey(workOrdRec.Id) && workOrdIdVsSerAppMap.get(workOrdRec.Id)?.FSL__Pinned__c && workOrdIdVsSerAppMap.get(workOrdRec.Id)?.FSL__Schedule_Mode__c.equalsIgnoreCase('Automatic')){
                System.debug('If Condition');
                ServiceAppointment saRec = new ServiceAppointment(Id=workOrdIdVsSerAppMap.get(workOrdRec.Id).Id );
                System.debug('saRec: '+saRec);
                saRec.ServiceTerritoryId = workOrdRec?.Asset?.NextRoute__r?.ServiceTerritory__c;
                saRec.Route__c = workOrdRec?.Asset?.NextRoute__c;
                System.debug('impactedWO: '+impactedWO);
                if(impactedWO){
                    
                    saRec.FSL__Pinned__c= false;
                  //  saRec.AssignedServiceResource__c =null;
                    saRec.ArrivalWindowStartTime = workOrdIdVsSerAppMap.get(workOrdRec.Id)?.SchedStartTime;
                    saRec.ArrivalWindowEndTime = workOrdIdVsSerAppMap.get(workOrdRec.Id)?.SchedEndTime;
                }
                updateSARecs.add(saRec);
            }
            if(workOrdRTNames.contains(workOrdRec.RecordType.Name)){
                workOrdRec.ServiceTerritoryId = workOrdRec?.Asset?.NextRoute__r?.ServiceTerritory__c;
                workOrdRec.Route__c = workOrdRec?.Asset?.NextRoute__c;
                if(impactedWO) workOrdRec.status='Unassigned';
                updateWO.add(workOrdRec);
            }
        }
        Set<Id> locAndAccIds = new Set<Id>();
        for(Asset asset: newUnitList){
            updateUnits.add(new Asset(Id=asset.Id,NextRoute__c=null,FS_Effective_Date__c=null,Route__c=asset.NextRoute__c,RouteName__c = asset?.NextRoute__r?.ServiceTerritory__c));            
            if(!locAndAccIds.contains(asset.locationId) && String.isNotEmpty(asset?.Location?.NextRoute__c)){
                locAndAccIds.add(asset.locationId);
                updateLocations.add(new Schema.Location(Id=asset.locationId,EffectiveDate__c=null,NextRoute__c=null,Route__c=asset.Location.NextRoute__c));
            }
            if(!locAndAccIds.contains(asset.AccountId) && String.isNotEmpty(asset?.Account?.Next_Route__c)){
                locAndAccIds.add(asset.AccountId);
                updateAccounts.add(new Account(Id=asset.AccountId,Route__c= asset.Account.Next_Route__c,EffectiveDate__c=null,Next_Route__c=null));
            }
        }
        handleResourcePreferenceOperations((new Map<Id,Asset>(newUnitList)).keyset(),'Delete',null);
        handleResourcePreferenceOperations((new Map<Id,Asset>(newUnitList)).keyset(),'Create',unitIdVsListServResIdMap);
        
        system.debug('***updateSARecs b'+updateSARecs);
        system.debug('***updateWO b'+updateWO);
        system.debug('***updateUnits b'+updateUnits);
        system.debug('***updateLocations b'+updateLocations);
        system.debug('***updateLocations b'+updateLocations);
        
       // List<Database.SaveResult> result = Database.update(updateSARecs,false);
        List<Database.SaveResult> result2 = Database.update(updateWO,false);
        List<Database.SaveResult> result3 = Database.update(updateUnits,false);
        List<Database.SaveResult> result = Database.update(updateSARecs,false);
        List<Database.SaveResult> result4 = Database.update(updateLocations,false);
        List<Database.SaveResult> result5 = Database.update(updateAccounts,false);
        
        system.debug('***updateSARecs'+updateSARecs +'---'+workOrdIdVsSerAppMap);
        system.debug('***updateWO'+updateWO);
        system.debug('***updateUnits'+updateUnits);
        system.debug('***updateLocations'+updateLocations);
        system.debug('***updateLocations'+updateLocations);
        
        system.debug('***updateSARecs'+result);
        system.debug('***updateWO'+result2);
        system.debug('***updateUnits'+result3);
        system.debug('***updateLocations'+result4);
        system.debug('***updateLocations'+result5);
    }
    /**=========================================================================================
* Method Author : Naga Swapna Nakka
* Method Description: Automation to handle Route Reassignment if Service Territory Change
=========================================================================================**/
    public static void handleRouteReassignmentOperation(List<Asset> newUnitList, Map<Id, Asset> oldAssetMap, SObject obj){
        system.debug('****newUnitList'+newUnitList);
        system.debug('****oldAssetMap'+oldAssetMap);
        system.debug('****obj'+obj);
        FSL_FeatureFlag__mdt RouteReassignmentOperation = FSLUtility.getFeatureFlagDetails(FSLConstantClass.FEATURE_ROUTE_REASSIGNMENT_OPERATION);
        System.debug('^^^RouteReassignmentOperation'+RouteReassignmentOperation);
        if(RouteReassignmentOperation != null && RouteReassignmentOperation.isActive__c){
            
            Set<Id> unitIds = (new Map<Id,Asset> (newUnitList)).keyset();
            System.debug('^^^unitIds'+unitIds);
            List<Asset> assetRecList = [Select Id,Route__c,Account.Next_Route__c ,Location.NextRoute__c,NextRoute__c,NextRoute__r.ServiceTerritory__c,RouteName__c from Asset where Id IN :unitIds];
            handleCommonRouteReassignmentOperations(assetRecList);          
            Set<Id> impactedUnitIdSet = new Set<Id>();
            Set<Id> unImpactedUnitIdSet = new Set<Id>();
            Map<Id,ServiceAppointment> workOrdIdVsSARecMap =new Map<Id,ServiceAppointment>();
            List<WorkOrder> pendingEngagementWorkOrders = new List<WorkOrder>();
            for(Asset ast : assetRecList){
                system.debug('asst ::'+ast.NextRoute__r.ServiceTerritory__c);
                if(ast.NextRoute__r.ServiceTerritory__c!= oldAssetMap.get(ast.Id).RouteName__c){
                    system.debug('if check --->change');
                    impactedUnitIdSet.add(ast.Id); //change
                }else{
                    system.debug('else check ---> No change');
                    unImpactedUnitIdSet.add(ast.Id);  //no change
                }
            }
            
            Map<Id,WorkOrder> workOrdMap = new Map<Id,WorkOrder>([Select Id,AssetId,Status,Asset.Account.Next_Route__c,Asset.Location.NextRoute__c,Asset.AccountId,Asset.Route__c,Asset.LocationId,Asset.Location.Route__c,Asset.Location.Account__c,Asset.Location.Account__r.Route__c,RecordType.Name,Asset.NextRoute__r.ServiceTerritory__c,(Select Id,WorkOrder__c,Status,ParentRecordId,FSL__Schedule_Mode__c,FSL__Pinned__c,SchedStartTime,AssignedServiceResource__c,ArrivalWindowStartTime,ArrivalWindowEndTime,SchedEndTime from ServiceAppointments WHERE Status NOT IN ('Completed','Canceled','Enroute','Onsite')) from Workorder where AssetId IN :unitIds and Status NOT IN ('In Progress' , 'Closed' , 'Cannot Complete','Completed - Shutdown','Canceled by Customer','Canceled','Canceled by Otis')]); 
            system.debug('workOrdMap :::'+workOrdMap);
            for(WorkOrder woRec : workOrdMap.values()){
                for(ServiceAppointment saRec :woRec.ServiceAppointments){
                    workOrdIdVsSARecMap.put(saRec.ParentRecordId,saRec);
                    if(unImpactedUnitIdSet.contains(woRec.AssetId)){
                        pendingEngagementWorkOrders.add(workOrdMap.get(saRec.ParentRecordId));  
                    }
                }
            }
            
            System.debug('^^^pendingEngagementWorkOrders'+pendingEngagementWorkOrders);
            System.debug('^^^workOrdIdVsSARecMap'+workOrdIdVsSARecMap);
            if(!impactedUnitIdSet.isEmpty()){
                handleImpactedWOAndSARecords(workOrdMap.values());
                resetWOAndSARecords(workOrdMap.values(),workOrdIdVsSARecMap,assetRecList,true);
            }
            if(!unImpactedUnitIdSet.isEmpty()){
                system.debug('unImpactedUnitIdSet :::'+unImpactedUnitIdSet);
                handleImpactedWOAndSARecords(pendingEngagementWorkOrders);
                resetWOAndSARecords(pendingEngagementWorkOrders,workOrdIdVsSARecMap,assetRecList,false);
            }   
        }
    }
}