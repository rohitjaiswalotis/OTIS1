/*
Developed by - Cognizant 
Created date -  05/07/2024
Description: Test Class for FSL_ExpenseHandlerService.
*/

@isTest
public class FSL_ExpenseHandlerServiceTest {
    
    @testSetup
    public static void setup() {
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
        
         Contact ct =FSL_TestDataFactory.createContactwithBusinessPhone(acc.id,'TestContact',998783473);
        insert ct;
       
        Case cs = UTIL_TestDataFactory.createCase('New','Email',ct.Id);
        cs.Priority = 'S3 - Normal';
        insert cs;
        
        
        List<WorkType> workTypeList = new List<WorkType>();
        WorkType wType = UTIL_TestDataFactory.createWorkType('Test WorkType', 1, 'Hours', True);
        wType.Description = 'Test Description on WorkType';
        wType.TaskType__c = 'Test';
        workTypeList.add(wType);
       
    
        List<WorkOrder> workOrdersSr = UTIL_TestDataFactory.createWorkOrders(acc.Id,ct.Id, cs.Id, assetForMT.id, null, null, null, recordTypeIdSr, 1);
        List<WorkOrder> workOrdersMt = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, null, assetForMT.id, null, null, null, recordTypeIdMt, 1);
        workOrdersMt[0].workTypeId=workTypeList[0].Id;
  
         allWo.addAll(workOrdersSr);
        allWo.addAll(workOrdersMt);
       
          insert allWo;
        CS_TriggerSettings__c setting3=UTIL_TestDataFactory.createTriggerSettings('Expense');
        insert setting3;
        
        // Create User records
        User manager = UTIL_TestDataFactory.createUserRec('uManager','manager@test.com','UTF-8','Manager','en_US','en_US','Standard User', 'America/Los_Angeles','saibalray@test.com','');
        insert manager;
        
        User mechanic = UTIL_TestDataFactory.createUserRec('uMech','mechanic@test.com','UTF-8','Mechanic','en_US','en_US','Standard User', 'America/Los_Angeles','fsmechanicUser@test.com', manager.Id);
        insert mechanic;
        
        user mechanic2 = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','user1ToUpdate@test.com', manager.Id);
        insert mechanic2;
        
        user mechanic3 = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','user2ToUpdate@test.com', manager.Id);
        insert mechanic3;

        // Create ServiceResource related to the mechanic
        ServiceResource serviceResource = UTIL_TestDataFactory.createServiceResource('TestingResource', mechanic.Id ,'1234567890','test@gmail.com');
        serviceResource.JobTitle__c = 'Service Mechanic';
        serviceResource.Branch__c = officeRecord.Id;
        serviceResource.Company__c = 'OTIS NAA';
        insert serviceResource; 
        
       OTIS_Expense_Setting__c otisExpSet = FSL_TestDataFactory.createOtisExpenseSetting('Otis Sample Data','OTIS NAA',999.99,999.99,999.99,999.99,999.99);
        insert otisExpSet;
        
        InternalResource__c internalResource = UTIL_TestDataFactory.createInternalResource('mechanic2',officeRecord.Id,Null,'Service Mechanic','test@gmail.com');
        internalResource.User__c= mechanic2.Id;
        insert internalResource;
		
        InternalResource__c internalResource1 = UTIL_TestDataFactory.createInternalResource('mechanic3',officeRecord.Id,Null,'Service Mechanic','test1@gmail.com');
        internalResource1.User__c= mechanic3.Id;
        insert internalResource1;
        
        BranchMemberRole__c officeMember1 = UTIL_TestDataFactory.createOfficeMember(officeRecord.id,internalResource.id,Null);
        insert officeMember1;
        
        BranchMemberRole__c officeMember = UTIL_TestDataFactory.createOfficeMember(officeRecord.id,internalResource1.id,Null);
        insert officeMember;
        
        BranchMemberRole__c officeMember2 = UTIL_TestDataFactory.createOfficeMember(officeRecord.id,Null,serviceResource.Id);
        insert officeMember2;
        
        List<Expense> expenses = FSL_TestDataFactory.createExpense(serviceResource.Id, Date.Today(), 'Mileage', 100, 1);
        expenses[0].WorkOrderId = allWo[0].Id;
        insert expenses;
        List<Expense> expensesTwo = FSL_TestDataFactory.createExpense(serviceResource.Id, Date.Today(), 'Zone', 200, 1);
        expensesTwo[0].WorkOrderId = allWo[0].Id;
        insert expensesTwo;
    }

    @isTest
    public static void afterInsertMethod() {
        List<Expense> expenses = [SELECT Id , Amount, WorkOrderId FROM Expense LIMIT 1];
        WorkOrder workOrder = [SELECT Id, TotalExpenses__c FROM WorkOrder LIMIT 1];
        
        // Call the method under test and pass the updated list of Expense records
        Test.startTest();
        FSL_ExpenseHandlerService.aggregateExpenseOnWorkOrder(expenses);
        Test.stopTest();
        
        // Verify the updated state of TotalExpense__c
        workOrder = [SELECT Id, TotalExpenses__c FROM WorkOrder LIMIT 1];
        System.assertEquals(300, workOrder.TotalExpenses__c);
    }
    @isTest
    public static void afterUpdateMethod() {
        List<Expense> expensestoUpdate = [SELECT Id , Amount, WorkOrderId FROM Expense LIMIT 1];
        
        // Update one of the Expense records
        expensestoUpdate[0].Amount = 50;
        update expensestoUpdate;
        
        WorkOrder workOrder = [SELECT Id, TotalExpenses__c FROM WorkOrder LIMIT 1];
        // Call the method under test and pass the updated list of Expense records
        Test.startTest();
        FSL_ExpenseHandlerService.aggregateExpenseOnWorkOrder(expensestoUpdate);
        Test.stopTest();
        
        // Verify the updated state of TotalExpense__c on WorkOrder
        workOrder = [SELECT Id, TotalExpenses__c FROM WorkOrder LIMIT 1];
        System.assertEquals(250, workOrder.TotalExpenses__c);
    }
    @isTest
    static void expenseShareTest(){
        user manager =[SELECT Id FROM user WHERE username='saibalray@test.com'];
        ServiceResource serRes= [Select Id FROM ServiceResource WHERE Name='TestingResource'];
        
        List<Expense> listOfExp = FSL_TestDataFactory.createExpense(serRes.Id,Date.Today(),'Zone',10,1);
        Test.startTest();
        insert listOfExp;
        Test.stopTest();
        
        ExpenseShare[] expList = [SELECT Id FROM ExpenseShare where ParentId=:listOfExp[0].Id];
        System.assertEquals(True,expList!=Null);
    }
}