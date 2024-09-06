@isTest
public class FSL_AssignedResourceOnDeleteTest {
    
    @TestSetup
    static void setup() {
        
        User adminUser = UTIL_TestDataFactory.createUser(
            UTIL_Constants.SYSTEM_ADM_PROFILE,
            UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX
        );
        insert adminUser;
        
        
        List<Database.SaveResult> results =
            UTIL_TestDataFactory.assignPermissionSets(
                adminUser.Id,
                new Set<String> {
                    'FSL_Resource_Permissions',
                    'FSL_Dispatcher_Permissions'
                }
            )
        ;
        
        System.runAs(adminUser) {
            
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
         
            
            Account acc=UTIL_TestDataFactory.createAccount('TestAccount');
            insert acc;
            
            Contact ct =UTIL_TestDataFactory.createContact(acc.id,'TestContact');
            ct.Phone='1234567890';
            insert ct;
            
     
            List<WorkType> workTypeList = new List<WorkType>();
            WorkType wType = UTIL_TestDataFactory.createWorkType('Test WorkType', 1, 'Hours', True);
            wType.Description = 'Test Description on WorkType';
            wType.TaskType__c = 'Test';
            workTypeList.add(wType);
            
            
            insert workTypeList;  
           
    
            List<WorkOrder> workOrdersMt = UTIL_TestDataFactory.createWorkOrders(acc.Id, ct.Id, null, assetForMT.id, null, null, null, recordTypeIdMt, 1);
            workOrdersMt[0].workTypeId=workTypeList[0].Id;
            allWo.addAll(workOrdersMt);
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
            ServiceAppointment sa = UTIL_TestDataFactory.createServiceAppointment(workOrdersMt[0].id,'None', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
            insert sa;
            
        }
        
    }
    
   /* 
	@isTest
    public static void deleteAssignedResourceTest() {
        
        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            
            // Create test data
            serviceResource sr = [Select Id,name from ServiceResource where Name ='Test' Limit 1];
            ServiceAppointment sa =[Select Id from ServiceAppointment Order By CreatedDate Desc  Limit 1];
            AssignedResource testResource = new AssignedResource();
            testResource.ServiceResourceId=sr.Id;
            testResource.ServiceAppointmentId = sa.id;
            insert testResource;
            
            // Create FlowInputs instance
            FSL_AssignedResourceOnDelete.FlowInputs flowInput = new FSL_AssignedResourceOnDelete.FlowInputs();
            flowInput.assResource = testResource;
            
            // Create a list of FlowInputs
            List<FSL_AssignedResourceOnDelete.FlowInputs> flowInputsList = new List<FSL_AssignedResourceOnDelete.FlowInputs>();
            flowInputsList.add(flowInput);
            
            // Call the method to test
            Test.startTest();
                
                FSL_AssignedResourceOnDelete.deleteAssignedResource(flowInputsList);
                
            Test.stopTest();
            
        }
		
    }
    */
    
}