/*=======================================================================================================
Developed by - Cognizant
Created date -  05/07/2024
Description: Test Class for FSL_TimeSheetEntryTriggerHandlerService.
=======================================================================================================*/

@isTest
public class FSL_TimeSheetEntryHandlerServiceTest {
    
    @testSetup
   public static void setup() {
        // Create Branch and related records
        Branch__c officeRecord = UTIL_TestDataFactory.createBranch('Demo Office','Branch',null);
        officeRecord.FSLEnabled__c=true;
        insert officeRecord;
       
        
        Asset assetForMT = UTIL_TestDataFactory.createAsset('TestUnit',null,null);
        assetForMT.Branch__c = officeRecord.Id;
        assetForMT.FS_UnitCompany__c = 'OTIS Switzerland';
        insert assetForMT;
        
        Account acc = UTIL_TestDataFactory.createAccount('TestAccount');
        insert acc;
        
        Contact ct = FSL_TestDataFactory.createContactwithBusinessPhone(acc.Id,'TestContact',998783473);
        insert ct;
        
        Case cs = UTIL_TestDataFactory.createCase('New','Email',ct.Id);
        cs.Priority = 'S3 - Normal';
        insert cs;
        
        // Create WorkOrders with different record types
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();

        List<WorkOrder> workOrdersSr = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, cs.Id, assetForMT.Id, null, null, null, recordTypeIdSr, 1);
        List<WorkOrder> workOrdersMt = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, null, assetForMT.Id, null, null, null, recordTypeIdMt, 1);

        List<WorkOrder> allWo = new List<WorkOrder>();
        allWo.addAll(workOrdersSr);
        allWo.addAll(workOrdersMt);
       
        insert allWo;

        // Create Trigger Settings for TimeSheetEntry
        CS_TriggerSettings__c setting = UTIL_TestDataFactory.createTriggerSettings('TimeSheetEntry');
        insert setting;
        
        // Create User records
        User manager = UTIL_TestDataFactory.createUserRec('uManager','manager@test.com','UTF-8','Manager','en_US','en_US','Standard User', 'America/Los_Angeles','saibalray@test.com','');
        insert manager;
        
        User mechanic = UTIL_TestDataFactory.createUserRec('uMech','mechanic@test.com','UTF-8','Mechanic','en_US','en_US','Standard User', 'America/Los_Angeles','fsmechanicUser@test.com', manager.Id);
        insert mechanic;
       
        User branchMech = UTIL_TestDataFactory.createUserRec('uMech','mechanic1@test.com','UTF-8','Mechanic','en_US','en_US','Standard User', 'America/Los_Angeles','fsmechanicUser1@test.com', manager.Id);
        insert branchMech;

        // Create ServiceResource related to the mechanic
        ServiceResource serviceResource = UTIL_TestDataFactory.createServiceResource('TestingResource', mechanic.Id ,'1234567890','test@gmail.com');
        serviceResource.JobTitle__c = 'Helper';
        serviceResource.Branch__c = officeRecord.Id;
        serviceResource.Company__c = 'OTIS NAA';
        insert serviceResource; 
       
        InternalResource__c internalResource = UTIL_TestDataFactory.createInternalResource('mechanic2',officeRecord.Id,Null,'Service Mechanic','test@gmail.com');
        internalResource.User__c= branchMech.Id;
        insert internalResource;
         
        BranchMemberRole__c officeMember = UTIL_TestDataFactory.createOfficeMember(officeRecord.id,null,serviceResource.id);
       insert officeMember;
       
        Date startDate = Date.today().addDays(-7);
        Date endDate = Date.today().addDays(7);
        
        // Create TimeSheet records related to the mechanic
        List<TimeSheet> timeSheets = UTIL_TestDataFactory.createTimeSheet('New', serviceResource.Id ,endDate ,startDate, manager.Id, mechanic.Id, 2);
        insert timeSheets;
		List<TimeSheetEntry> timeSheetEntry =FSL_TestDataFactory.createTimeSheetEntry('New', timeSheets[0].Id, Null, Datetime.now().addHours(-2), 1);
       timeSheetEntry[0].WorkOrderId = allWo[0].Id;
		insert timeSheetEntry;
       List<TimeSheetEntry> timeSheetEntryTwo =FSL_TestDataFactory.createTimeSheetEntry('New', timeSheets[0].Id, Datetime.now().addHours(-2), Datetime.now().addHours(-4), 1);
       timeSheetEntryTwo[0].WorkOrderId = allWo[0].Id;
		insert timeSheetEntryTwo;
       
    }

    @isTest
    public static void TimeSheetEntriesAfterInsert() {
        // Query the list of TimeSheetEntry records related to the first WorkOrder
        List<TimeSheetEntry> timeSheetEntries = [SELECT Id, StartTime, EndTime, WorkOrderId FROM TimeSheetEntry LIMIT 1];
        // Call the method under test and pass the list of TimeSheetEntry records
        Test.startTest();
        FSL_TimeSheetEntryTriggerHandlerService.aggregateTimeEntriesOnWorkOrder(timeSheetEntries);
        Test.stopTest();
        
        // Verify the updated state of TotalTimeSpentMins__c on WorkOrder
        WorkOrder workOrder = [SELECT Id, TotalTimeSpentMins__c FROM WorkOrder LIMIT 1];
        System.assertEquals(120, workOrder.TotalTimeSpentMins__c);
    }

    @isTest
    public static void TimeSheetEntriesAfterUpdate() {
        List<TimeSheetEntry> timeSheetEntriesToUpdate = [SELECT Id, StartTime, EndTime, WorkOrderId FROM TimeSheetEntry LIMIT 1];
        // Update one of the TimeSheetEntry records
        timeSheetEntriesToUpdate[0].StartTime = Datetime.now().addHours(-4);
        update timeSheetEntriesToUpdate;
        
        // Call the method under test and pass the updated list of TimeSheetEntry records
        Test.startTest();
        FSL_TimeSheetEntryTriggerHandlerService.aggregateTimeEntriesOnWorkOrder(timeSheetEntriesToUpdate);
        Test.stopTest();
        
        // Verify the updated state of TotalTimeSpentMins__c on WorkOrder
        WorkOrder workOrder = [SELECT Id, TotalTimeSpentMins__c FROM WorkOrder LIMIT 1];
        System.assertEquals(120, workOrder.TotalTimeSpentMins__c);
    }
}