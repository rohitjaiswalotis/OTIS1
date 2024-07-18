/**=========================================================================================
* Author : 
* Version : 01
* Description: OTIS Route Reassignment Handler Test Class to Cover all main class methods.
* Created Date : 02-07-2024
* Last Modified Date: 
=========================================================================================*/
@IsTest(SeeAllData=false)
public class FSLRouteReassignmentHandlerTest {
    
    @TestSetup
    public static Void setup(){
        //RecordType Creation for Service Request
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT
        ).getRecordTypeId();
        
        //RecordType Creation for Maintanance
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            FSLConstantClass.WORK_ORDER_MAINTENANCE_RT
        ).getRecordTypeId();
        
        //WorkType Record Creation.
        WorkType wt= UTIL_TestDataFactory.createWorkType('Test Work Type', 4, 'Hours', True);
        insert wt;    
        //User Record Creation.
        User  mechanicUser = UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert mechanicUser;
        
        User  mechanicUserRec = UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert mechanicUserRec;
        
        //Service Resource Record Creation.
        ServiceResource sr= UTIL_TestDataFactory.createServiceResource('Test',mechanicUser.id,'1234',null,'1234',true);
        insert sr;
        
        ServiceResource srRec= UTIL_TestDataFactory.createServiceResource('Test SR',mechanicUserRec.id,'12345',null,'12345',true);
        insert srRec;
        
        //Operating Hours Record Creation.
        OperatingHours opHours= UTIL_TestDataFactory.createOperatingHours('Test' , 'Test', 'America/Los_Angeles');
        insert opHours; 
        //Branch/Office Record Creation.
        Branch__c officeRecord = UTIL_TestDataFactory.createBranch('Demo Office','Branch',null);
        officeRecord.FSLEnabled__c=true;
        insert officeRecord; 
        //ServiceTerritory Record Creation.
        ServiceTerritory serTerr= UTIL_TestDataFactory.createTerritory('Test', opHours.id, null, null);
        serTerr.Branch__c = officeRecord.Id;
        insert serTerr;
        ServiceTerritory serTerr1= UTIL_TestDataFactory.createTerritory('Test1', opHours.id, null, null);
        serTerr1.Branch__c = officeRecord.Id;
        insert serTerr1;
        
        //STM Record Creation.
        ServiceTerritoryMember stm = FSL_TestDataFactory.createServiceTerritoryMember(opHours.id,sr.id,serTerr.id,Datetime.now());
        insert stm;     
        
        //OTIS Route Record Creation.
        OTISRoute__c otisRoute = UTIL_TestDataFactory.createOtisRoute(serTerr.id, 'Sample OTIS Route 1',True);
        insert otisRoute;
        
        OTISRoute__c otisRoute1 = UTIL_TestDataFactory.createOtisRoute(serTerr.id, 'Sample OTIS Route 2',True);
        insert otisRoute1;
        //Asset/Unit Record Creation.
        
        List<Asset> assetForMT=UTIL_TestDataFactory.createAssets('TestUnit',null,null,2);
        assetForMT.get(0).Branch__c=officeRecord.Id;
        assetForMT.get(0).Route__c = otisRoute.Id;
        assetForMT.get(0).NextRoute__c = otisRoute1.Id;
        assetForMT.get(0).RouteName__c = serTerr.id;
        assetForMT.get(1).Branch__c=officeRecord.Id;
        assetForMT.get(1).Route__c = otisRoute.Id;
        assetForMT.get(1).NextRoute__c = otisRoute1.Id;
        assetForMT.get(1).RouteName__c = serTerr1.id;
        insert assetForMT;
        
        //ResourcePreference rp = UTIL_TestDataFactory.createResourcePreference('Preferred',assetForMT.get(0).Id,sr.id);
        //insert rp;
        
        //Account Record Creation.
        Account acc=UTIL_TestDataFactory.createAccount('TestAccount');
        insert acc;
        //Contact Record Creation.        
        Contact ct =UTIL_TestDataFactory.createContact(acc.id,'TestContact');
        ct.Phone ='8772876847';
        insert ct;  
        //Case Record Creation.
        Case cr=UTIL_TestDataFactory.createCase(null, null, ct.id);
        insert cr;
        
        //Work Order and SA Creation Ser Req.
        WorkOrder woRecSerReq=UTIL_TestDataFactory.createWorkOrder(acc.Id,ct.Id,cr.Id,assetForMT.get(0).Id,serTerr.Id,officeRecord.Id,datetime.Now(),recordTypeIdSr);
        woRecSerReq.SvcReqAssignedMechanic__c=sr.Id;
        woRecSerReq.status='Assigned';
        insert woRecSerReq;
        
        ServiceAppointment saRecSerReq= UTIL_TestDataFactory.createServiceAppointment(woRecSerReq.id,'None', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
        saRecSerReq.Status = 'None';
        insert saRecSerReq;
        
        //Work Order and SA Creation Maint.
        WorkOrder woRecMaint=UTIL_TestDataFactory.createWorkOrder(acc.Id,ct.Id,cr.Id,assetForMT.get(1).Id,serTerr.Id,officeRecord.Id,datetime.Now(),recordTypeIdMt);
        woRecMaint.SvcReqAssignedMechanic__c=sr.Id;
        woRecMaint.status='Assigned';
        insert woRecMaint;
        
        ServiceAppointment saRecMaint= UTIL_TestDataFactory.createServiceAppointments(woRecMaint.id,'Dispatched', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id,sr.Id);
        saRecMaint.FSL__Schedule_Mode__c='Automatic';
        saRecMaint.FSL__Pinned__c=true;
        insert saRecMaint;
        
        RouteResource__c routeRes =UTIL_TestDataFactory.CreateRouteResource(otisRoute.Id,sr.Id,'Preferred','Primary Mechanic',serTerr.Id);
        insert routeRes;
        
        RouteResource__c routeRec =UTIL_TestDataFactory.CreateRouteResource(otisRoute.Id,srRec.Id,'Required','Other Mechanic',serTerr.Id);
        insert routeRec;
    }
    
    @isTest
    public static void testHandleRouteReassignmentOperation(){
        List<WorkOrder> woList = [Select id,AssetId,Status, ServiceTerritoryId from WorkOrder where Status NOT IN ('In Progress' , 'Closed' , 'Cannot Complete')];
        List<ServiceAppointment> saList = [Select Id,WorkOrder__c,Status,parentRecordId from ServiceAppointment where WorkOrder__c in : woList and Status NOT IN ('Completed' , 'Cancelled')];
        List<Asset> astList = [Select id,RouteName__c,Route__c from Asset];
        List<ServiceTerritory> stList = [Select id from ServiceTerritory];
        Map<id,Asset> oldAssetMap = new Map<Id,Asset>();
        for(Asset ast : astList){
            oldAssetMap.put(ast.id, new Asset(RouteName__c=ast.RouteName__c,id=ast.Id,Route__c=ast.Route__c));
        }
        if(astList.get(0).RouteName__c == stList.get(0).id){
            astList.get(0).RouteName__c = stList.get(1).id;
        }
        else{
            astList.get(0).RouteName__c = stList.get(0).id;
        }
        update astList.get(0);
        Test.startTest();
        FSLRouteReassignmentHandlerQueueable.handleRouteReassignmentOperation(astList,oldAssetMap,null);
        Test.stopTest();        
    }
    
    @IsTest
    public static void testResetWOAndSARecords() {
        List<Asset> astList =[Select Id,Route__c,Account.Next_Route__c ,Location.NextRoute__c,NextRoute__c,NextRoute__r.ServiceTerritory__c from Asset];
        List<WorkOrder> workOrders = [Select Id,AssetId,Status,Asset.Account.Next_Route__c,Asset.Location.NextRoute__c,Asset.AccountId,Asset.Route__c,Asset.LocationId,Asset.Location.Route__c,Asset.Location.Account__c,Asset.Location.Account__r.Route__c,RecordType.Name,Asset.NextRoute__r.ServiceTerritory__c,(Select Id,WorkOrder__c,Status,ParentRecordId,FSL__Schedule_Mode__c,FSL__Pinned__c,SchedStartTime,AssignedServiceResource__c,ArrivalWindowStartTime,ArrivalWindowEndTime,SchedEndTime from ServiceAppointments WHERE Status NOT IN ('Completed','Cancelled','Enroute','Onsite')) from Workorder];      //  List<Asset> asset = [SELECT Id,Name FROM Asset order by createddate limit 1];
        Map<Id, ServiceAppointment> woIdVsSAMap = new Map<Id, ServiceAppointment>();
        for(ServiceAppointment sa :[select Id, AppointmentNumber, Status, ParentRecordId, FSL__Schedule_Mode__c, FSL__Pinned__c,SchedStartTime,SchedEndTime from ServiceAppointment where ParentRecordId IN: workOrders]){
            woIdVsSAMap.put(sa.ParentRecordId,sa);
        }
        Test.startTest();
        FSLRouteReassignmentHandlerQueueable.resetWOAndSARecords(workOrders, woIdVsSAMap,astList,true);
        FSLRouteReassignmentHandlerQueueable.resetWOAndSARecords(workOrders, woIdVsSAMap,astList,false);
        Test.stopTest();
        
        List<ServiceAppointment> updatedServiceAppointments = [SELECT Id,ParentRecordId, ArrivalWindowStartTime, ArrivalWindowEndTime, FSL__Pinned__c,SchedStartTime,SchedEndTime, AssignedServiceResource__c,FSL__Schedule_Mode__c FROM ServiceAppointment];
        for (ServiceAppointment sa : updatedServiceAppointments) {
            //System.assertEquals(sa.FSL__Pinned__c, false);
            //System.assertEquals(sa.AssignedServiceResource__c, null);
        }
        
        Set<Id> parentRecordIds = new Set<Id>();
        for (ServiceAppointment sa : updatedServiceAppointments) {
            parentRecordIds.add(sa.ParentRecordId);
        }
    }
    
    @IsTest
    static void handleImpactedWOAndSARecordsTest(){
        
        List<WorkOrder> workOrders = [Select Id,AssetId,Status,Asset.Account.Next_Route__c,Asset.Location.NextRoute__c,Asset.AccountId,Asset.Route__c,Asset.LocationId,Asset.Location.Route__c,Asset.Location.Account__c,Asset.Location.Account__r.Route__c,RecordType.Name,Asset.NextRoute__r.ServiceTerritory__c,(Select Id,WorkOrder__c,Status,ParentRecordId,FSL__Schedule_Mode__c,FSL__Pinned__c,SchedStartTime,AssignedServiceResource__c,ArrivalWindowStartTime,ArrivalWindowEndTime,SchedEndTime from ServiceAppointments WHERE Status NOT IN ('Completed','Cancelled','Enroute','Onsite')) from Workorder];      //  List<Asset> asset = [SELECT Id,Name FROM Asset order by createddate limit 1];
        // List<ResourcePreference> resPref = [SELECT Id,PreferenceType,RelatedRecordId,ServiceResourceId FROM ResourcePreference];
        Test.StartTest();
        FSLRouteReassignmentHandlerQueueable.handleImpactedWOAndSARecords(workOrders);
        Test.StopTest();
    }
    
    @IsTest
    static void testProcessData(){
        List<Asset> assets = [Select Id,Route__c,RouteName__c,Account.Next_Route__c ,Location.NextRoute__c,NextRoute__c,NextRoute__r.ServiceTerritory__c from Asset];
        FSLRouteReassignmentHandler.FlowInputs flwInput = new FSLRouteReassignmentHandler.FlowInputs();
        flwInput.newUnitRecord = assets[0];
        flwInput.oldUnitRecord = assets[0];
        Test.startTest();
        FSLRouteReassignmentHandler.processData(new List<FSLRouteReassignmentHandler.FlowInputs>{flwInput});
        Test.stopTest();
    }
    
    @isTest
    static void forDeleteOperation()
    {
        String Operation = 'Delete';
        OTISRoute__c otisRoute = [Select Id from OTISRoute__c where Name = 'Sample OTIS Route 1'];
        
        List<Asset> unitList =  [Select Id,Route__c,Account.Next_Route__c ,Location.NextRoute__c,NextRoute__c,NextRoute__r.ServiceTerritory__c from Asset where Route__r.Id =: otisRoute.Id];
        List<WorkOrder> workOrders = [Select Id,AssetId,Status,Asset.Account.Next_Route__c,Asset.Location.NextRoute__c,Asset.AccountId,Asset.Route__c,Asset.LocationId,Asset.Location.Route__c,Asset.Location.Account__c,Asset.Location.Account__r.Route__c,RecordType.Name,Asset.NextRoute__r.ServiceTerritory__c,(Select Id,WorkOrder__c,Status,ParentRecordId,FSL__Schedule_Mode__c,FSL__Pinned__c,SchedStartTime,AssignedServiceResource__c,ArrivalWindowStartTime,ArrivalWindowEndTime,SchedEndTime from ServiceAppointments WHERE Status NOT IN ('Completed','Cancelled','Enroute','Onsite')) from Workorder Where Route__c =: otisRoute.Id];
        List<Id> recordList = new List<Id>();
        Map<Id,List<String>> routeIdVsListUnitIdMap = new Map<Id,List<String>> ();
        Map<Id,List<RouteResource__c>> unitIdVsListServResIdMap = new Map<Id,List<RouteResource__c>> ();
        
        for(Asset assetRec : unitList)
        {
            recordList.add(assetRec.Id);
            routeIdVsListUnitIdMap.put(assetRec.NextRoute__c,new List<String>{assetRec.Id});
        }
        for(WorkOrder woId : workOrders)
        {
            recordList.add(woId.Id);
        }
        
        List<ServiceResource> srList = [Select Id from ServiceResource];
        List<Id> resourceList = new List<Id>();
        for(ServiceResource srId : srList)
        {
            resourceList.add(srId.Id);
        }
        
        for (RouteResource__c routeResRec : [Select Id,ServiceResource__c,Route__c,PreferenceType__c from RouteResource__c Where Route__c = :otisRoute.Id]){
            if (routeIdVsListUnitIdMap.containsKey(routeResRec.Route__c)) {
                for(String assetId : routeIdVsListUnitIdMap.get(routeResRec.Route__c)){
                    unitIdVsListServResIdMap.put(assetId,new List<RouteResource__c>{routeResRec});
                }
            }
        }
        
        FSLRouteReassignmentHandlerQueueable.handleResourcePreferenceOperations((new Set<Id>(recordList)), Operation, unitIdVsListServResIdMap);
        
        List<ResourcePreference> existingRPList = [Select Id from ResourcePreference where RelatedRecordId in :recordList];
       // System.assertEquals(0,existingRPList.size());
        
    }
    
    @isTest
    static void forCreateOperation()
    {
        String Operation = 'Create';
        OTISRoute__c otisRoute = [Select Id from OTISRoute__c where Name = 'Sample OTIS Route 1'];
        List<Asset> unitList = [Select Id,NextRoute__c from Asset where Route__r.Id =: otisRoute.Id];
        List<WorkOrder> workOrders = [Select Id,AssetId,Status,Asset.Account.Next_Route__c,Asset.Location.NextRoute__c,Asset.AccountId,Asset.Route__c,Asset.LocationId,Asset.Location.Route__c,Asset.Location.Account__c,Asset.Location.Account__r.Route__c,RecordType.Name,Asset.NextRoute__r.ServiceTerritory__c,(Select Id,WorkOrder__c,Status,ParentRecordId,FSL__Schedule_Mode__c,FSL__Pinned__c,SchedStartTime,AssignedServiceResource__c,ArrivalWindowStartTime,ArrivalWindowEndTime,SchedEndTime from ServiceAppointments WHERE Status NOT IN ('Completed','Cancelled','Enroute','Onsite')) from Workorder where Route__c =: otisRoute.Id];
        List<Id> recordList = new List<Id>();
        Map<Id,List<String>> routeIdVsListUnitIdMap = new Map<Id,List<String>> ();
        Map<Id,List<RouteResource__c>> unitIdVsListServResIdMap = new Map<Id,List<RouteResource__c>> ();
        for(Asset assetRec : unitList)
        {
            recordList.add(assetRec.Id);
            routeIdVsListUnitIdMap.put(assetRec.NextRoute__c,new List<String>{assetRec.Id});
            
        }
        for(WorkOrder woRec : workOrders)
        {
            recordList.add(woRec.Id);
        }
        List<ServiceResource> srList = [Select Id from ServiceResource];
        List<Id> resourceList = new List<Id>();
        for(ServiceResource srId : srList)
        {
            resourceList.add(srId.Id);
        }
        Map<Id,List<Id>> ServiceResourceMap = new Map<Id,List<Id>>();
        for(Id records : recordList){
            ServiceResourceMap.put(records,resourceList);
        }
        
        for (RouteResource__c routeResRec : [Select Id,ServiceResource__c,Route__c,PreferenceType__c from RouteResource__c Where Route__c = :otisRoute.Id]){
            if (routeIdVsListUnitIdMap.containsKey(routeResRec.Route__c)) {
                for(String assetId : routeIdVsListUnitIdMap.get(routeResRec.Route__c)){
                    unitIdVsListServResIdMap.put(assetId,new List<RouteResource__c>{routeResRec});
                }
            }
        }
        
        FSLRouteReassignmentHandlerQueueable.handleResourcePreferenceOperations((new Set<Id>(recordList)), Operation, unitIdVsListServResIdMap);
        List<ResourcePreference> existingRPList = [Select Id from ResourcePreference where RelatedRecordId in :recordList];
        system.debug('existingRPList'+existingRPList);
       // System.assertEquals(0,existingRPList.size());
    }
}