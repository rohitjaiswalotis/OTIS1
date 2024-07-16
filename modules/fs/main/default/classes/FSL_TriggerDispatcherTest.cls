/**=========================================================================================
    @Description: Test class for TriggerDispatcher
    =========================================================================================*/
@isTest
private with sharing class FSL_TriggerDispatcherTest{
    @testSetup
    public static void setupTestData(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        /*add kill switch*/
        CS_KillSwitch__c killSwitch = new CS_KillSwitch__c(
                DisableFlows__c = false, DisableProcessBuilders__c = false, DisableTriggers__c = false
        );
        insert killSwitch;
        
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
        
        List<WorkOrder> workOrdersMt = FSL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, null, assetForMT.id, null, null, null, recordTypeIdMt,null, 100);

        /* Insert 100 WorkOrders so that we can test the framework for bulk records*/
        
        insert workOrdersMt;
    }

    static testMethod void beforeContextTest(){
        List<WorkOrder> woList = new List<WorkOrder>([SELECT Id, Description FROM WorkOrder LIMIT 50]);
        for(WorkOrder wo : woList){
            wo.Description = 'Test Description';
        }

        Test.startTest();

        update woList;

        System.assertEquals(50, woList.size());
        Test.stopTest();
    }

    static testMethod void afterContextTest(){
        List<WorkOrder> woList = new List<WorkOrder>([SELECT Id, Description FROM WorkOrder LIMIT 30]);

        Test.startTest();

        System.assertEquals(30, woList.size());
        delete woList;
        List<WorkOrder> woListUnDelete = new List<WorkOrder>([SELECT Id, Description FROM WorkOrder LIMIT 30 ALL ROWS]);
        undelete woListUnDelete;

        Test.stopTest();
    }
	
}