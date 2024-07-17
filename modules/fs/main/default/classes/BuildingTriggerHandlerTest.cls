@isTest
public class BuildingTriggerHandlerTest {
	@testSetup 
    public static void setupData(){
		//create trigger settings
		List<CS_TriggerSettings__c> settings = UTIL_TestDataFactory.createTriggerSettings(new List<String>{'Account','ServiceTerritory', 'Branch__c', 'Location'});
		insert settings;
	}
    @isTest 
    public static void updateLocation(){
    	
        Branch__c gbo = UTIL_TestDataFactory.createBranch('Miami', 'MIA', 'GBO', 'America/New_York', '1200 Oak', 'Miami', 'FL', '23456', 'United States');
		insert gbo;

		//Create Branch__c
		Branch__c branch = UTIL_TestDataFactory.createBranch('Miami', 'MIA', 'Branch', 'America/New_York', '1200 Oak', 'Miami', 'FL', '23456', 'United States');
		branch.GBO__c = gbo.Id;
		insert branch;
        
        Branch__c branch1 = UTIL_TestDataFactory.createBranch('Miami', 'MIA', 'Branch', 'America/New_York', '1200 Oak', 'Miami', 'FL', '23456', 'United States');
		branch1.GBO__c = gbo.Id;
		insert branch1;
        
        Schema.Location building = UTIL_TestDataFactory.createLocation('Beta Building','Residential');
        building.BranchName__c = branch.Id;
        insert (SObject)building;
        
        building.BranchName__c = branch1.Id;
        update (SObject)building;
		
	}
}