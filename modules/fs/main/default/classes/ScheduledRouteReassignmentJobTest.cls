/*=======================================================================================================
Developed by - Agnibha
Created date - 03/07/2024
LastModified By - Agnibha
LastModified On - 03/07/2024
Description -  Test class for ScheduledRouteReassignmentJobTest.
==========================================================================================================*/
@isTest(seeAllData=false)
public class ScheduledRouteReassignmentJobTest {
    
    @testSetup
    static void setup(){
        
        //Building data creation
        Schema.Location building=UTIL_TestDataFactory.createLocation('Building','');
        insert building;
        //mech user creation
        User  mechanicUserRec = UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert mechanicUserRec;  
        //Service Resource Record Creation.
        ServiceResource sr= UTIL_TestDataFactory.createServiceResource('Test',mechanicUserRec.id,'1234',null,'1234',true);
        insert sr;
        //Operating Hours Record Creation.
        OperatingHours opHours= UTIL_TestDataFactory.createOperatingHours('Test' , 'Test', 'America/Los_Angeles');
        insert opHours; 
        //Branch/Office Record Creation.
        Branch__c officeRecord = UTIL_TestDataFactory.createBranch('Demo Office','Branch',null);
        officeRecord.FSLEnabled__c=true;
        insert officeRecord; 
        //ServiceTerritory Record Creation.
        ServiceTerritory serTerr= UTIL_TestDataFactory.createTerritory('Test', opHours.id, null, null);
        serTerr.Branch__c = officeRecord.Id;
        insert serTerr;
        ServiceTerritory serTerr1= UTIL_TestDataFactory.createTerritory('Test1', opHours.id, null, null);
        serTerr1.Branch__c = officeRecord.Id;
        insert serTerr1;
        
        //STM Record Creation.
        ServiceTerritoryMember stm = FSL_TestDataFactory.createServiceTerritoryMember(opHours.id,sr.id,serTerr.id,Datetime.now());
        insert stm;     
        
        //OTIS Route Record Creation.
        List<OTISRoute__c> routeList=new List<OTISRoute__c>();
        OTISRoute__c otisRoute = UTIL_TestDataFactory.createOtisRoute(serTerr.id, 'Sample OTIS Route 1',True);
        routeList.add(otisRoute);
        OTISRoute__c otisRoute2 = UTIL_TestDataFactory.createOtisRoute(serTerr.id, 'Sample OTIS Route 2',True);
        routeList.add(otisRoute2);
        
        insert routeList;
        
        //Asset/Unit Record Creation.
        
        List<Asset> assetForMT=UTIL_TestDataFactory.createAssets('TestUnit',null,null,2);
        assetForMT.get(0).Branch__c=officeRecord.Id;
        assetForMT.get(0).Route__c = otisRoute.Id;
        assetForMT.get(0).NextRoute__c = otisRoute.Id;
        assetForMT.get(0).FS_Effective_Date__c = Date.today().addDays(1);
        assetForMT.get(0).RouteName__c = serTerr.id;
        assetForMT.get(1).Branch__c=officeRecord.Id;
        assetForMT.get(1).Route__c = otisRoute.Id;
        assetForMT.get(1).RouteName__c = serTerr1.id;
        assetForMT.get(1).NextRoute__c = otisRoute2.Id;
        assetForMT.get(1).FS_Effective_Date__c = Date.today().addDays(1);
       
        insert assetForMT;
           
    }
     @isTest
    static void testBatchJobExecution() {
        Test.startTest();
        
        // Schedule the job
        String jobId = System.schedule('Test Scheduled Job', '0 0 0 ? * *', new ScheduledRouteReassignmentJob());

        // Execute the batch job
        Database.executeBatch(new ScheduledRouteReassignmentJob());
        
        Test.stopTest();

        // Validate the updates
        List<Asset> updatedAssets = [SELECT Id, Route__c, FS_Effective_Date__c, NextRoute__c FROM Asset WHERE NextRoute__c = null];
       // System.assertEquals(0, updatedAssets.size());


    }

}