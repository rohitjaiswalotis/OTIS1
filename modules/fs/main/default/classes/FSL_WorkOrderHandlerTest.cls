/**=========================================================================================
Developed by - Anubrata Sanyal
Created date - 4/07/2024
Description - Test class for FSLWorkOrderHandler class.
=========================================================================================*/
@isTest(SeeAllData=false)
public class FSL_WorkOrderHandlerTest {
    @testSetup
    static void setup(){
        List<WorkOrder> allWo = new List<WorkOrder>();
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        
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
        ct.Phone='1234567890';
        insert ct;
        
        
        Case cs = UTIL_TestDataFactory.createCase('New','Email',ct.Id);
        cs.Priority = 'S3 - Normal';
        insert cs;
        
        
        List<WorkType> workTypeList = new List<WorkType>();
        WorkType wType = UTIL_TestDataFactory.createWorkType('Test WorkType', 1, 'Hours', True);
        wType.Description = 'Test Description on WorkType';
        wType.TaskType__c = 'Test';
        workTypeList.add(wType);
        
        insert workTypeList;
        
        
    }
    
    @isTest    
    static Void handleBeforeAfterInsert(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        List<WorkOrder> woList = new List<WorkOrder>();
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Account acc = [select id from Account Order by createddate desc limit 1];
        Contact con = [select id,AccountId from Contact where AccountId=:acc.Id Order by createddate desc limit 1];
        Case cs = [select id,ContactId from Case where ContactId=:con.Id Order by createddate desc limit 1];
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        WorkType wt = [select id from WorkType where Name='Test WorkType' Order by createddate desc limit 1];
        
        
        List<WorkOrder> workOrdersSr = FSL_TestDataFactory.createWorkOrders(acc.Id, con.Id, cs.Id, asRecord.id, null, null, null, recordTypeIdSr,null, 1);
        List<WorkOrder> workOrdersMt = FSL_TestDataFactory.createWorkOrders(acc.Id, con.Id, null, asRecord.id, null, null, null, recordTypeIdMt,wt.Id, 1);
        woList.addAll(workOrdersSr);
        woList.addAll(workOrdersMt);
        
        Test.startTest();
        insert woList;
        Test.stopTest();
        
    }
    
    @isTest
    static void handleBeforeAfterUpdate(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        List<WorkOrder> woList = new List<WorkOrder>();
        List<WorkOrder> woListUpdate = new List<WorkOrder>();
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Account acc = [select id from Account Order by createddate desc limit 1];
        Contact con = [select id,AccountId from Contact where AccountId=:acc.Id Order by createddate desc limit 1];
        Case cs = [select id,ContactId from Case where ContactId=:con.Id Order by createddate desc limit 1];
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        WorkType wt = [select id from WorkType where Name='Test WorkType' Order by createddate desc limit 1];
        
        
        List<WorkOrder> workOrdersSr = FSL_TestDataFactory.createWorkOrders(acc.Id, con.Id, cs.Id, asRecord.id, null, null, null, recordTypeIdSr,null, 1);
        List<WorkOrder> workOrdersMt = FSL_TestDataFactory.createWorkOrders(acc.Id, con.Id, null, asRecord.id, null, null, null, recordTypeIdMt,wt.Id, 1);
        woList.addAll(workOrdersSr);
        woList.addAll(workOrdersMt);
        
        Test.startTest();
        insert woList;
        for(WorkOrder wo : woList){
            wo.Description='Before After Update';
            woListUpdate.add(wo);
        }
        update woListUpdate;
        Test.stopTest();
    }
}