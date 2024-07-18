@isTest
public class ServiceAppointmentQueuableTest {
 
     @TestSetup
    public static Void setup(){
        FSL.SettingsAPI.setCustomSettings(
            'Drip_Feed_Config__c', 
            new Map<String, Object> {
                'Value__c'	=>	false
            }
        );
        CS_TriggerSettings__c setting=UTIL_TestDataFactory.createTriggerSettings('ServiceAppointment');
        insert setting;
        
        FSL.GlobalAPIS.addStatusTransition('None', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('None', 'Dispatched');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Onsite');
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Enroute');
        FSL.GlobalAPIS.addStatusTransition('Enroute', 'Onsite');
        FSL.GlobalAPIS.addStatusTransition('Onsite', 'Completed');
        FSL.GlobalAPIS.addStatusTransition('Onsite', 'Cannot Complete');
        
         Id recordTypeIdSr = RecordTypeUtilities.getRecordTypeInfo( WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT).getRecordTypeId();
        
         Id recordTypeIdMt = RecordTypeUtilities.getRecordTypeInfo(WorkOrder.SObjectType,FSLConstantClass.WORK_ORDER_MAINTENANCE_RT).getRecordTypeId();
        
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
               
        Branch__c officeRecord = UTIL_TestDataFactory.createBranch('Demo Office','Branch',null);
        officeRecord.FSLEnabled__c=true;
        insert officeRecord;
        
        Asset assetForMT=UTIL_TestDataFactory.createAsset('TestUnit',null,null);
        assetForMT.Branch__c=officeRecord.Id;
        assetForMT.FS_UnitCompany__c='OTIS NAA'; 
        insert assetForMT;
        //
        Account acc=UTIL_TestDataFactory.createAccount('TestAccount');
        insert acc;
        
        Contact ct =UTIL_TestDataFactory.createContact(acc.id,'TestContact');
        ct.Phone ='8772876847';
        insert ct;
        
        Case cr=UTIL_TestDataFactory.createCase(null, null, ct.id);
        insert cr;

         List<TimeSheet> ts = UTIL_TestDataFactory.createTimeSheet('New',sr.id,date.Today()+1 ,date.Today()-2,1); 
        insert ts;
        

        
         WorkOrder allWorkOrders = UTIL_TestDataFactory.createWorkOrder( 
         acc.id, ct.id, cr.id, assetForMT.id,  serTerr.id, officeRecord.id, datetime.now(), recordTypeIdSr);
         allWorkOrders.SvcReqAssignedMechanic__c = sr.Id;
         insert allWorkOrders;
 
        
        
       
         
         ServiceAppointment serviceAppo = UTIL_TestDataFactory.createServiceAppointment(allWorkOrders.id,'none', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
         serviceAppo.AssignedServiceResource__c=sr.id;
         insert serviceAppo;
        
         ServiceAppointment serviceAppo1 = UTIL_TestDataFactory.createServiceAppointment(allWorkOrders.id,'none', datetime.now() ,datetime.now()+1,datetime.now(),datetime.now()+1, serTerr.id);
         serviceAppo1.AssignedServiceResource__c=sr.id;
         insert serviceAppo1;
        
}


@isTest
    public static void testMethod1(){
                
    
        ServiceAppointment servAppoRec = [Select Id,AssignedServiceResource__c, Status, ParentRecordId, EarliestStartTime, DueDate,
                                                    SchedStartTime, SchedEndTime,ServiceTerritoryId,TravelTimeStamp__c,Estimated_Travel_Time__c,
                                                    WorkOrder__c,OnSiteTimeStamp__c
                                                    from ServiceAppointment  LIMIT 1];
        Test.startTest();
        servAppoRec.Status='Dispatched';
        update servAppoRec;
        
        servAppoRec.Status='Enroute';
        update servAppoRec;
        
         servAppoRec.Status='Onsite';
        update servAppoRec;
        
        ServAppoRec.Status='Completed';
        servAppoRec.CompletionTimeStamp__c = system.now();
        update servAppoRec;
        Test.StopTest();
        
        System.AssertEquals('Completed',servAppoRec.Status);
      
    }    
    
    @isTest
    public static void testCompletedMethod2(){
                
        ServiceResource serRes = [Select Id from ServiceResource LIMIT 1];
        TimeSheet timesheet = [SELECT Id FROM TimeSheet where ServiceResourceId =: serRes.Id];
        ServiceAppointment servAppoRec = [Select Id,AssignedServiceResource__c, Status, ParentRecordId, EarliestStartTime, DueDate,
                                                    SchedStartTime, SchedEndTime,ServiceTerritoryId,TravelTimeStamp__c,Estimated_Travel_Time__c,
                                                    WorkOrder__c,OnSiteTimeStamp__c
                                                    from ServiceAppointment where Status != 'Complete' Limit 1];
        Test.startTest();
        servAppoRec.Status='Dispatched';
        update servAppoRec;
        
        servAppoRec.Status='Enroute';
        update servAppoRec;
        
         servAppoRec.Status='Onsite';
        update servAppoRec;
        
        servAppoRec.Status='Cannot Complete';
        servAppoRec.CompletionTimeStamp__c = system.now();
        update servAppoRec;
        Test.StopTest();
        List<TimesheetEntry> listOfTse = [SELECT Id FROM TimesheetEntry Where TimesheetId =:timesheet.Id];
        Assert.isTrue(listOfTse.size()>0);
    }    
}