/**=========================================================================================
Developed by - Anubrata Sanyal
Created date - 4/07/2024
Description - Test class for FSL_WorkOrderService class.
=========================================================================================*/
@isTest(SeeAllData=false)
public class FSL_WorkOrderServiceTest {
    @testSetup
    static void setup(){
        WorkType wt = UTIL_TestDataFactory.createWorkType('Default Work Type',2,'Hours',true);
        insert wt;
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
        
        Asset assetForMT2=UTIL_TestDataFactory.createAsset('TestUnit2',null,null);
        assetForMT2.Branch__c=officeRecord.Id;
        assetForMT2.FS_UnitCompany__c ='OTIS Switzerland';
        insert assetForMT2;
        
        Asset assetForMT3=UTIL_TestDataFactory.createAsset('TestUnit3',null,null);
        assetForMT3.Branch__c=officeRecord.Id;
        assetForMT3.FS_UnitCompany__c ='OTIS Switzerland';
        insert assetForMT3;
        
        Account acc=UTIL_TestDataFactory.createAccount('TestAccount');
        insert acc;
        
        Contact ct =UTIL_TestDataFactory.createContact(acc.id,'TestContact');
        ct.Phone='1234567890';
        insert ct;
        
        Case cs = UTIL_TestDataFactory.createCase('New','Email',ct.Id);
        cs.Priority = 'S3 - Normal';
        insert cs;
        
        Case cs2 = UTIL_TestDataFactory.createCase('NewCase','Chat',ct.Id);
        cs2.Priority = 'S2 - High';
        insert cs2;
        
        Case cs3 = UTIL_TestDataFactory.createCase('NewCase2','Phone',ct.Id);
        cs3.Priority = 'S4 - Low';
        insert cs3;
        
        List<WorkType> workTypeList = new List<WorkType>();
        WorkType wType = UTIL_TestDataFactory.createWorkType('Test WorkType', 1, 'Hours', True);
        wType.Description = 'Test Description on WorkType';
        wType.TaskType__c = 'Test';
        workTypeList.add(wType);
        
        WorkType wType2 = UTIL_TestDataFactory.createWorkType('Test workType1', 2, 'Hours', True);
        wType2.Description = 'Test Description on WorkType';
        wType2.TaskType__c = 'Door Procedure Visit';
        workTypeList.add(wType2);
        
        insert workTypeList;
        
        Entitlement entitle = FSL_TestDataFactory.createEntitlement('Test Entitlement',acc.Id,assetForMT.Id);
        insert entitle;
        
        Entitlement entitle2 = FSL_TestDataFactory.createEntitlement('Test Entitlement2',acc.Id,assetForMT2.Id);
        insert entitle2;
        
        Product2 product = FSL_TestDataFactory.createProduct('Test Product');
        insert product;
        
        PriceBookEntry pbEntry = FSL_TestDataFactory.createPricebookEntry(product);
        insert pbEntry;
        
        ServiceContract sContract = FSL_TestDataFactory.createServiceContract('Test Service Contract',acc.Id,assetForMT.Id, Test.getStandardPricebookId());
        insert sContract;
        
        Contract cont = FSL_TestDataFactory.createContract('CDH06555','00000223',acc.Id);
        insert cont;
        
        ContractLineItem__c contCustom = FSL_TestDataFactory.createContractLineItemsCustom('CDH06888_C888888',assetForMT.Id,cont.Id,'KeyAccount_SLA');
        insert contCustom;
        
        List<ContractLineItem> contList = new List<ContractLineItem>();
        ContractLineItem contStandard1 = FSL_TestDataFactory.createContractLineItemsStandard('INT1MF120',assetForMT.Id,contCustom.Id,pbEntry.Id,sContract.Id);
        contList.add(contStandard1);
        ContractLineItem contStandard2 = FSL_TestDataFactory.createContractLineItemsStandard('INT2MF170',assetForMT.Id,contCustom.Id,pbEntry.Id,sContract.Id);
        contList.add(contStandard2);
        ContractLineItem contStandard3 = FSL_TestDataFactory.createContractLineItemsStandard('TPAMFWorkCLI80',assetForMT.Id,contCustom.Id,pbEntry.Id,sContract.Id);
        contList.add(contStandard3);
        
        insert contList;
   
        List<WorkOrder> workOrdersSr = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, cs.Id, assetForMT.id, null, null, null, recordTypeIdSr, 1);
        //List<WorkOrder> workOrdersSr2 = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, cs.Id, assetForMT2.id, null, null, null, recordTypeIdSr, 1);
        List<WorkOrder> workOrdersSr3 = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, cs.Id, assetForMT3.id, null, null, null, recordTypeIdSr, 1);
        List<WorkOrder> workOrdersMt = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, null, assetForMT.id, null, null, null, recordTypeIdMt, 1);
        workOrdersMt[0].workTypeId=workTypeList[0].Id;
        
        allWo.addAll(workOrdersSr);
        allWo.addAll(workOrdersMt);
       // allWo.addAll(workOrdersSr2);
        allWo.addAll(workOrdersSr3);

        insert allWo;
        
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
        ServiceAppointment sa = UTIL_TestDataFactory.createServiceAppointment(workOrdersSr[0].id,'Completed', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
        insert sa;
        
    }
   
    @isTest    
    static Void handleAfterUpdate(){
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        
        Test.startTest();
        List<WorkOrder> allWORecords= [ SELECT Id,Description,Status from WorkOrder where RecordTypeId= :recordTypeIdMt OR RecordTypeId= :recordTypeIdSr order by createdDate desc limit 2];
        List<WorkOrder> updatedWO= new  List<WorkOrder>();
        
        for( WorkOrder wo: allWORecords){
            wo.Description='Test Update';
            wo.Status='Closed';
            wo.WorkOrderClosureDate__c = Date.today();
            updatedWO.add(wo);
        }
        update updatedWO;
        
        Id woID = updatedWO.get(0).ID;
        Date closedDate = [Select Id,WorkOrderClosureDate__c from WorkOrder where ID =:woID ].get(0).WorkOrderClosureDate__c;
        System.assertEquals(2,allWORecords.size(),'Test Successful');
        Test.stopTest();
        
    }
    
    @isTest
     static void recordsOfMTSetPriority(){
         Test.startTest();
         Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
         
         List<WorkOrder> allMtWoRecords=[Select id from WorkOrder where AssetId!=null AND RecordTypeId= :recordTypeIdMt order by createdDate desc limit 1];
         List<WorkOrder> updatedWO= new  List<WorkOrder>();
         for( WorkOrder wo: allMtWoRecords){
             wo.Description='Test Update';
             wo.FS_MissedVisit__c='Missed Visit';
             updatedWO.add(wo);     
         }
         update updatedWO;
         Test.stopTest();
    }
    
    @isTest
    private static void recordsOfSRSetPriorityS4Low(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Test.startTest();
        WorkOrder woSr=[Select id,CaseId from WorkOrder where caseId!=null AND RecordTypeId= :recordTypeIdSr order by createdDate desc limit 1];
       
        Case cs = [select id,Priority from Case where Id=:woSr.CaseId];
        
        cs.Priority='S4 - Low';
        update cs;
        
        woSr.Description='Test Update';
        update woSr;
        Test.stopTest();
    }          
    
    @isTest
    private static void recordsOfSRSetPriorityS2High(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Test.startTest();
        WorkOrder woSr=[Select id,CaseId from WorkOrder where caseId!=null AND RecordTypeId= :recordTypeIdSr order by createdDate desc limit 1];
       
        Case cs = [select id,Priority from Case where Id=:woSr.CaseId];
        
        cs.Priority='S2 - High';
        update cs;
        
        woSr.Description='Test Update';
        update woSr;
        
        Test.stopTest();
    }
    
    @isTest
    private static void recordsOfSRSetPriorityS1Emergency(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Test.startTest();
        WorkOrder woSr=[Select id,CaseId from WorkOrder where caseId!=null AND RecordTypeId= :recordTypeIdSr order by createdDate desc limit 1];
       
        Case cs = [select id,Priority from Case where Id=:woSr.CaseId];
        
        cs.Priority='S1 - Emergency';
        update cs;
        
        woSr.Priority='S3 - Normal';
        woSr.Status='Assigned';
        update woSr;
        Test.stopTest();
    }
    
    @isTest
    private static void recordsOfSRSetPriorityS3Normal(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Test.startTest();
        WorkOrder woSr=[Select id,CaseId from WorkOrder where caseId!=null AND RecordTypeId= :recordTypeIdSr order by createdDate desc limit 1];
        Case cs = [select id,Priority from Case where Id=:woSr.CaseId];
        cs.Priority='S3 - Normal';
        update cs;
        Test.stopTest();
    }
    /*
        @isTest
        static void executeUpdatesetVisitTypeOnWorkOrderTest(){
            
            Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
            List<WorkOrder> allMtWoRecords=[Select id from WorkOrder where AssetId!=null AND RecordTypeId= :recordTypeIdMt order by createdDate desc limit 1];
            WorkType workType = [select id,TaskType__c,Name from WorkType where TaskType__c='Test' ];
            allMtWoRecords[0].FS_Priority__c='';
            allMtWoRecords[0].Description='Test';
            update allMtWoRecords[0];
            Test.startTest();
            WorkType wt1 = [Select id from WorkType where TaskType__c = 'Door Procedure Visit'];
            allMtWoRecords[0].WorkTypeId= wt1.id;
            update allMtWoRecords[0];
            Test.stopTest();
            
        } */
    /*
    @isTest
    static void setFSLWorkOrderSubjectBeforeInsertTest(){
        Test.startTest();
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        WorkType wType = [Select id from WorkType where TaskType__c = 'Door Procedure Visit'];
        List<WorkOrder> allMtWoRecords=[Select id from WorkOrder where AssetId!=null AND RecordTypeId= :recordTypeIdMt order by createdDate desc limit 1];
        allMtWoRecords[0].WorktypeId = wType.Id;
        update allMtWoRecords;
        Test.stopTest();
    } */
    
    @isTest
    static void runEntitlementWhenSCBlank(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Test.startTest();
        Account acc = [select id from Account where Name='TestAccount'];
        Contact ct = [select id from Contact where AccountId=:acc.Id];
        Case cs = [select id,Priority from Case where ContactId=:ct.Id AND Origin='Email'];
        Asset assetForMT2 = [select id from Asset where Name='TestUnit2'];
        List<WorkOrder> workOrdersSr2 = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, cs.Id, assetForMT2.id, null, null, null, recordTypeIdSr, 1);
        insert workOrdersSr2;
        Test.stopTest();
    }
    
    @isTest
    static void runEntitlementWhenEntitlementBlank(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Test.startTest();
        Account acc = [select id from Account where Name='TestAccount'];
        Contact ct = [select id from Contact where AccountId=:acc.Id];
        Case cs = [select id,Priority from Case where ContactId=:ct.Id AND Origin='Email'];
        Asset assetForMT3 = [select id from Asset where Name='TestUnit3'];
        List<WorkOrder> workOrdersSr2 = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, cs.Id, assetForMT3.id, null, null, null, recordTypeIdSr, 1);
        insert workOrdersSr2;
        Test.stopTest();
    }
    
    @isTest
    static void showErrorMessageOnWOCancellation(){
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        List<WorkOrder> workOrdersMtToCreate = new List<WorkOrder>();
        Asset asRecord = [select id,name from Asset where Name='TestUnit' LIMIT 1];
        List<ServiceResource> sr= [ SELECT id from ServiceResource Order by createddate desc limit 1];
       
        
        List<WorkOrder> allWoRecord = [SELECT Id, WorkTypeId, RecordTypeId,FS_Priority__c FROM WorkOrder where  AssetId=:asRecord.Id Order by createddate desc];
       
        ServiceAppointment ser = [SELECT Id, Status, EarliestStartTime,DueDate,SchedStartTime,SchedEndTime,ServiceTerritoryId,WorkOrder__c FROM ServiceAppointment where ParentRecordId = :allWoRecord[0].Id Order by createddate desc limit 1]; 
        try{
            Test.startTest();
            allWoRecord[0].status= 'Canceled';
            update allWoRecord;
            Test.stopTest();
        }
        catch(Exception e){
            Logger.error(e.getMessage());
        }
    }
    
    
   
}