@isTest
public class TestDummyClassTest {

    @testSetup
    static void setup() {
        // Insert standard data required for the tests
        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType, FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType, FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact ct = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert ct;

        Case cs = new Case(Origin = 'Email', Status = 'New', Priority = 'S3 - Normal', ContactId = ct.Id);
        insert cs;

        Asset assetForMT = new Asset(Name = 'TestUnit', FS_UnitCompany__c = 'OTIS Switzerland');
        insert assetForMT;

        WorkOrder workOrder1 = new WorkOrder(
            RecordTypeId = recordTypeIdSr,
            Status = 'Unassigned',
            CaseId = cs.Id,
            AccountId = acc.Id,
            AssetId = assetForMT.Id
        );
        insert workOrder1;

        ServiceAppointment sa1 = new ServiceAppointment(
            ParentRecordId = workOrder1.Id
        );
        insert sa1;
    }

    @isTest
    static void testGetRecordQueryHelperMetadata() {
        String metadataname = 'Get_WorkOrderWithId';
        Test.startTest();
        FSL_QueryHelper__mdt querymeta = TestDummyClass.getRecordQueryHelperMetadata(metadataName);
        Test.stopTest();
        }

    @isTest
    static void testSetWorkOrderIdWhileCreateSA() {
        List<ServiceAppointment> saList = [SELECT Id, ParentRecordId FROM ServiceAppointment];

        Test.startTest();
        List<ServiceAppointment> result = TestDummyClass.setWorkOrderIdWhileCreateSA(saList);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should not be null');
        if (!result.isEmpty()) {
            System.assertEquals(1, result.size(), 'There should be one ServiceAppointment updated');
            System.assertNotEquals(null, result[0].WorkOrder__c, 'WorkOrder__c should be set');
        }
    }

    @isTest
    static void testSetPriorityOnWorkOrder() {
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        Contact ct = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id ORDER BY CreatedDate DESC LIMIT 1];
        Case testCase = new Case(Priority = 'S1 - Emergency', Origin = 'Phone', Status = 'New', ContactId = ct.Id);
        insert testCase;

        Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType, FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        WorkOrder wo = new WorkOrder(
            RecordTypeId = recordTypeIdSr,
            CaseId = testCase.Id,
            Status = 'Unassigned',
            AccountId = testCase.AccountId
        );
        insert wo;

        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>([SELECT Id, Priority FROM WorkOrder WHERE Id = :wo.Id]);

        List<WorkOrder> listOfSRWorkOrder = new List<WorkOrder>{wo};
        List<WorkOrder> listOfMPWorkOrder = new List<WorkOrder>();

        Test.startTest();
       
        TestDummyClass.setPriorityOnWorkOrder(listOfSRWorkOrder, listOfMPWorkOrder, oldMap, true);
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Id, FS_Priority__c FROM WorkOrder WHERE Id = :wo.Id];
        
    }

    @isTest
    static void testSetPriorityOnWorkOrder_MP() {
       
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        Asset assetForMT = [SELECT Id, Name FROM Asset WHERE Name = 'TestUnit' LIMIT 1];

        Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType, FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        WorkOrder wo = new WorkOrder(
            RecordTypeId = recordTypeIdMt,
            Status = 'Open',
            AccountId = acc.Id,
            AssetId = assetForMT.Id,
            FS_MissedVisit__c = 'Missed Visit'
        );
        insert wo;

        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>([SELECT Id, Priority FROM WorkOrder WHERE Id = :wo.Id]);

        List<WorkOrder> listOfSRWorkOrder = new List<WorkOrder>();
        List<WorkOrder> listOfMPWorkOrder = new List<WorkOrder>{wo};

        Test.startTest();
        
        TestDummyClass.setPriorityOnWorkOrder(listOfSRWorkOrder, listOfMPWorkOrder, oldMap, true);
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Id, FS_Priority__c FROM WorkOrder WHERE Id = :wo.Id];
        
    }
}