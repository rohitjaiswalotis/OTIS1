/**=========================================================================================
Created by - Jaya Prasanth
Created date - 05/07/2024
Description - Test class for OverdueWorkOrderCalculationBatch class.
=========================================================================================*/
@isTest(SeeAllData=false)
public class OverdueWorkOrderCalculationBatchTest {
    @testSetup
        static void setupTestData() {  
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        
        Branch__c officeRecord = UTIL_TestDataFactory.createBranch('Demo Office','Branch',null);
        officeRecord.FSLEnabled__c=true;
        insert officeRecord;
        
        Asset testAsset=UTIL_TestDataFactory.createAsset('TestUnit',null,null);
        testAsset.Branch__c=officeRecord.Id;
        insert testAsset;
        
        Account testAccount = UTIL_TestDataFactory.createAccount('Test Account');
        insert testAccount;
        
        
        WorkType wType = new WorkType();
        wType = UTIL_TestDataFactory.createWorkType('Test WorkType', 1, 'Hours', True);
        wType.Frequency__c = 90;
        wType.TaskType__c = 'SUV';
        wType.ProcedureCode__c = '970H';
        insert wType;
        
        WorkOrder closedWorkOrder = new WorkOrder();
        closedWorkOrder = FSL_TestDataFactory.createWorkOrder(testAccount.Id,null, null, testAsset.id, null, null, null, recordTypeIdMt, wType.Id);
        closedWorkOrder.Status = 'Closed';
        closedWorkOrder.FS_WorkOderType__c = 'Maintenance';
        closedWorkOrder.WorkOrderClosureDate__c = system.Today()+1;
        insert closedWorkOrder;
         
        WorkOrder openWorkOrder = new WorkOrder();
        openWorkOrder = FSL_TestDataFactory.createWorkOrder(testAccount.Id,null, null, testAsset.id, null, null, null, recordTypeIdMt, wType.Id);
        openWorkOrder.Status = 'Assigned';
        openWorkOrder.FS_WorkOderType__c = 'Maintenance';
        insert openWorkOrder;
    }
    
    @isTest
    static void updateVisitTypeOnWorkOrder(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        WorkOrder wo = [SELECT Id,Status,WorkTypeId,WorkOrderClosureDate__c,visitType__c,FS_Priority__c FROM WorkOrder WHERE Status ='Closed' Order by CreatedDate DESC Limit 1 ];                          
        WorkType wt =[SELECT Id,Frequency__c,ProcedureCode__c,TaskType__c FROM WorkType Order by CreatedDate DESC Limit 1];
        OverdueWorkOrderCalculationBatch batch = new OverdueWorkOrderCalculationBatch();
        
        Test.startTest();
        Database.executebatch(batch);
        Test.stopTest();     
    }
    @isTest
    static void updateOpenWorkOrder(){
         Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
         WorkOrder woOpen = [SELECT Id,Status,WorkTypeId,visitType__c,FS_Priority__c FROM WorkOrder WHERE Status!='Closed' Order by CreatedDate DESC Limit 1 ];                             
         WorkType wt =[SELECT Id,Frequency__c,ProcedureCode__c,TaskType__c FROM WorkType Order by CreatedDate DESC Limit 1];
         OverdueWorkOrderCalculationBatch batch = new OverdueWorkOrderCalculationBatch();
        
         Test.startTest();
         Database.executebatch(batch);
         Test.stopTest();   
    }
}
