/**=========================================================================================
Developed by - Anubrata Sanyal
Created date - 4/07/2024
Description - Test class for FSLServiceAppointmentHandler class.
=========================================================================================*/
@IsTest(SeeAllData=false)
public class FSL_ServiceAppointmentHandlerTest {
    
    @TestSetup
    public static Void setup(){
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
        
        Account acc=UTIL_TestDataFactory.createAccount('TestAccount');
        insert acc;
        
        Contact ct =UTIL_TestDataFactory.createContact(acc.id,'TestContact');
        ct.Phone ='8772876847';
        insert ct;
        
        Case cr=UTIL_TestDataFactory.createCase('New','Email',ct.Id);
        insert cr;
        
        
        List<WorkOrder> workOrdersSr = FSL_TestDataFactory.createWorkOrders(
            acc.Id, ct.Id, cr.Id, assetForMT.Id, serTerr.Id, null, null, recordTypeIdSr,wt.Id, 1);
        insert workOrdersSr; 
        
        List<WorkOrder> workOrdersMt1 = FSL_TestDataFactory.createWorkOrders(
            acc.Id, ct.Id, null , assetForMT.Id, serTerr.Id, null, null, recordTypeIdMt,wt.Id, 1);
        insert workOrdersMt1;
        
        
      
    }
    
    @IsTest
    static void serviceAppointmentHandlerMTInsertUpdateTest(){
        List<ServiceAppointment> sAList = new List<ServiceAppointment>();
        
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId=:recordTypeIdMt AND AssetId=:asRecord.Id Order by createddate desc limit 1];
		ServiceTerritory serTerr = [select id from ServiceTerritory where name='Test' limit 1];        
        
        ServiceAppointment sa = UTIL_TestDataFactory.createServiceAppointment(allWoRecord[0].id,'None', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
      
        
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        Test.startTest();
        insert sa;
        
        system.debug('ser rec id: '+sa.Id);
        system.debug('ser rec record type: '+sa.WorkOrderRecordTypeId__c);
        sa.Status='Scheduled';
        sa.SchedStartTime = datetime.now();
        sa.SchedEndTime = datetime.now()+1;
        sa.AssignedServiceResource__c = sr[0].id;
        update sa;    
        
        Test.stopTest();
    }
    
    @IsTest
    static void serviceAppointmentHandlerSRInsertUpdateTest(){
        List<ServiceAppointment> sAList = new List<ServiceAppointment>();
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT
        ).getRecordTypeId();
        
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where RecordTypeId=:recordTypeIdSr AND AssetId=:asRecord.Id Order by createddate desc limit 2];
        ServiceTerritory serTerr = [select id from ServiceTerritory where name='Test' limit 1];        
        
        ServiceAppointment sa2 = UTIL_TestDataFactory.createServiceAppointment(allWoRecord[0].id,'None', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
         
            
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
        
        Test.startTest();
        insert sa2;
        sa2.Status='Scheduled';
        sa2.SchedStartTime = datetime.now();
        sa2.SchedEndTime = datetime.now()+1;
        sa2.AssignedServiceResource__c = sr[0].id;
        update sa2;    
        
        Test.stopTest();
    }
    
    
}