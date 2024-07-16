/**=========================================================================================
Developed by - Anubrata Sanyal
Created date - 4/07/2024
Description - Test class for FSL_ServiceAppointmentService class.
=========================================================================================*/
@IsTest(SeeAllData=false)
public class FSL_ServiceAppointmentServiceTest {
    
    @TestSetup
    public static Void setup(){
		
		FSL.SettingsAPI.setCustomSettings(
            'Drip_Feed_Config__c', 
            new Map<String, Object> {
                'Value__c'	=>	false
            }
        );
		
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT
        ).getRecordTypeId();
        
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            FSLConstantClass.WORK_ORDER_MAINTENANCE_RT
        ).getRecordTypeId();
        
        WorkType wt= UTIL_TestDataFactory.createWorkType('Test Work Type', 4, 'Hours', True);
        insert wt;
        
        User  mechanicUser = UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert mechanicUser;   
        ServiceResource sr= UTIL_TestDataFactory.createServiceResource('Test',mechanicUser.id,'1234',null,'1234',true);
        insert sr;
        OperatingHours opHours= UTIL_TestDataFactory.createOperatingHours('Test' , 'Test', 'America/Los_Angeles');
        insert opHours;        
        ServiceTerritory serTerr= UTIL_TestDataFactory.createTerritory('Test', opHours.id, null, null);
        insert serTerr;  
        ServiceTerritoryMember stm = FSL_TestDataFactory.createServiceTerritoryMember(opHours.id,sr.id,serTerr.id,Datetime.now());
        insert stm;
        List<WorkOrder> workOrdersSrToCreate = new List<WorkOrder>();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        List<WorkOrder> allworkOrdersToCreate = new List<WorkOrder>();
        List<ServiceAppointment> allSaToCreate = new List<ServiceAppointment>();
        
        Branch__c officeRecord = UTIL_TestDataFactory.createBranch('Demo Office','Branch',null);
        officeRecord.FSLEnabled__c=true;
        insert officeRecord;
        
        Asset assetForMT=UTIL_TestDataFactory.createAsset('TestUnit',null,null);
        assetForMT.Branch__c=officeRecord.Id;
        assetForMT.FS_UnitCompany__c ='OTIS Switzerland';
        insert assetForMT;
        
        Asset assetForMTNew=UTIL_TestDataFactory.createAsset('TestUnit1',null,null);
        assetForMTNew.Branch__c=officeRecord.Id;
        assetForMTNew.FS_UnitCompany__c ='OTIS Switzerland';
        insert assetForMTNew;
        
        Account acc=UTIL_TestDataFactory.createAccount('TestAccount');
        insert acc;
        
        Contact ct =UTIL_TestDataFactory.createContact(acc.id,'TestContact');
        ct.Phone ='8772876847';
        insert ct;
        
        Case cr=UTIL_TestDataFactory.createCase(null, null, ct.id);
        insert cr;
        
        WorkPlanTemplate workPlanTemplate = FSL_TestDataFactory.createWorkPlanTemplate('Test Work Plan Template','Test Work Plan Template Description',1 ,true);
        insert workPlanTemplate; 
        WorkStepTemplate workStepTemplate = FSL_TestDataFactory.createWorkStepTemplate('Test Work Step Template','Test Work Step Template Description',true ,true);
        insert workStepTemplate;
        WorkPlanTemplateEntry workPlanTemplateEntry = FSL_TestDataFactory.createWorkPlanTemplateEntry(workPlanTemplate.Id,workStepTemplate.id,1);
        insert workPlanTemplateEntry;
        WorkPlanSelectionRule workPlanSelectionRule = FSL_TestDataFactory.createWorkPlanSelectionRule(workPlanTemplate.Id,wt.id,true );
        insert workPlanSelectionRule;
        
        List<WorkOrder> workOrdersSr = FSL_TestDataFactory.createWorkOrders(
            acc.Id, ct.Id, cr.Id, assetForMT.Id, serTerr.Id, null, null, recordTypeIdSr,wt.Id, 1);
        
        List<WorkOrder> workOrdersMt = FSL_TestDataFactory.createWorkOrders(
            acc.Id, ct.Id, null , assetForMT.Id, serTerr.Id, null, null, recordTypeIdMt,wt.Id, 1);
        
        insert workOrdersSr; 
        insert workOrdersMt;
        
        List<WorkOrder> workOrdersMt1 = FSL_TestDataFactory.createWorkOrders(
            acc.Id, ct.Id, null , assetForMTNew.Id, serTerr.Id, null, null, recordTypeIdMt,null, 1);
        insert workOrdersMt1;
        
        ServiceAppointment sa = UTIL_TestDataFactory.createServiceAppointment(workOrdersMt1[0].id,'Completed', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
        insert sa;
        
        WorkPlan createWorkPlan = FSL_TestDataFactory.createWorkPlan('Test WP',mechanicUser.id,workOrdersMt1[0].Id);
        insert createWorkPlan;
        
        WorkStep workSteps = FSL_TestDataFactory.createWorkSteps('Test WSteps',createWorkPlan.id,'Completed',true);
        insert workSteps;
	}
    
    @IsTest
    static void serviceAppointmentHandlerInsertUpdateSetPriorityTest(){
        
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId =:recordTypeIdMt AND AssetId=:asRecord.Id Order by createddate desc limit 1];
        ServiceAppointment ser = [SELECT Id, Status, EarliestStartTime,DueDate,SchedStartTime,SchedEndTime,ServiceTerritoryId,WorkOrder__c FROM ServiceAppointment where ParentRecordId = :allWoRecord[0].Id Order by createddate desc limit 1];
 
        
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        for(WorkOrder woRec: allWoRecord){
            woRec.Fixed_Issue__c='No';
            woRec.FS_Priority__c ='Missed Visit';
            workOrdersMtToCreate.add(woRec);
        }
        Test.startTest();
        update workOrdersMtToCreate;
        
        ser.Status='Scheduled';
        ser.SchedStartTime = datetime.now();
        ser.SchedEndTime = datetime.now()+1;
        ser.AssignedServiceResource__c = sr[0].id;
        update ser;
        
        
        FSL_ServiceAppointmentService.setPriorityOnServiceAppointment(null,workOrdersMtToCreate);
        Test.stopTest();
    } 
    
    @IsTest
    static void setSATimestampsTest(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId =:recordTypeIdMt AND AssetId=:asRecord.Id  Order by createddate desc limit 1];
        ServiceAppointment ser = [SELECT Id, Status, EarliestStartTime,DueDate,SchedStartTime,SchedEndTime,ServiceTerritoryId,WorkOrder__c FROM ServiceAppointment where ParentRecordId = :allWoRecord[0].Id Order by createddate desc limit 1];
       
        
        FSL.GlobalAPIS.addStatusTransition('None', 'Dispatched');
        
        Test.startTest();
        List<ServiceAppointment> updatedSa= new  List<ServiceAppointment>();
        ser.Status='Dispatched';
        ser.SchedStartTime = datetime.now();
        ser.SchedEndTime = datetime.now()+1;
        ser.Description='Dispatched';
        ser.AssignedServiceResource__c = sr[0].id;
        update ser;
        
        for(ServiceAppointment updatedServiceappoinment :[SELECT Dispatch_Date_Time__c, Travel_Date_Time__c, Onsite_Date_Time__c, Completed_Date_Time__c, Incomplete_Date_Time__c, Cancelled_Date_Time__c FROM ServiceAppointment offset 6 ]){
            System.assertNotEquals(Null, updatedServiceappoinment.Dispatch_Date_Time__c);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSetWorkPlanScheduledToDispatched(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId =:recordTypeIdMt AND AssetId=:asRecord.Id Order by createddate desc limit 1];
        ServiceAppointment ser = [SELECT Id, Status, EarliestStartTime,DueDate,SchedStartTime,SchedEndTime,ServiceTerritoryId,WorkOrder__c FROM ServiceAppointment where ParentRecordId = :allWoRecord[0].Id Order by createddate desc limit 1];
        
        
        //FSL.GlobalAPIS.addStatusTransition('None', 'Completed');
        
        Test.startTest();
        List<ServiceAppointment> updatedSa= new  List<ServiceAppointment>();
        ser.Status='Scheduled';
        ser.SchedStartTime = datetime.now();
        ser.SchedEndTime = datetime.now()+1;
        ser.Description='Scheduled';
        ser.AssignedServiceResource__c = sr[0].id;
        update ser;
        
        ser.Status='Dispatched';
        update ser;
        
        Test.stopTest();
    }
    
    @IsTest
    static void testStatusTransitionForSR(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId =:recordTypeIdSr AND AssetId=:asRecord.Id Order by createddate desc limit 1];
        ServiceAppointment ser = [SELECT Id, Status, EarliestStartTime,DueDate,SchedStartTime,SchedEndTime,ServiceTerritoryId,WorkOrder__c FROM ServiceAppointment where ParentRecordId = :allWoRecord[0].Id Order by createddate desc limit 1];
        
        
        FSL.GlobalAPIS.addStatusTransition('None', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Onsite');
        FSL.GlobalAPIS.addStatusTransition('Onsite', 'Completed');
        
        Test.startTest();
        List<ServiceAppointment> updatedSa= new  List<ServiceAppointment>();
       // ser.Status='Scheduled';
        ser.SchedStartTime = datetime.now();
        ser.SchedEndTime = datetime.now()+1;
        ser.Description='Scheduled';
        //ser.AssignedServiceResource__c = sr[0].id;
        update ser;
        AssignedResource assignedR = new AssignedResource();
        assignedR.ServiceResourceId=sr[0].id;
        assignedR.ServiceAppointmentId=ser.id;
        insert assignedR;
        
        ser.Description='Onsite';
        ser.Status='Onsite';
        update ser;
        
        ser.Description='Completed';
        ser.Status='Completed';
		
        update ser;
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSetWorkPlanCompleted(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        Asset asRecord = [select id,name from Asset where Name='TestUnit1' LIMIT 1];
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId =:recordTypeIdMt AND AssetId=: asRecord.Id Order by createddate desc limit 1];
        ServiceAppointment ser = [SELECT Id, Status, EarliestStartTime,DueDate,SchedStartTime,SchedEndTime,ServiceTerritoryId,WorkOrder__c FROM ServiceAppointment where ParentRecordId = :allWoRecord[0].Id AND Status='Completed' Order by createddate desc limit 1];
       
        
        FSL.GlobalAPIS.addStatusTransition('None', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Onsite');
        FSL.GlobalAPIS.addStatusTransition('None', 'Completed');
        FSL.GlobalAPIS.addStatusTransition('Onsite', 'Completed');
        
        Test.startTest();
        List<ServiceAppointment> updatedSa= new  List<ServiceAppointment>();
        ser.SchedStartTime = datetime.now();
        ser.SchedEndTime = datetime.now()+1;
        ser.Description='Completed';
        ser.AssignedServiceResource__c = sr[0].id;
        update ser;
        
        Test.stopTest();
    }
    
}