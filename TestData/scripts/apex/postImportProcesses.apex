// enabling Automation Processes
CS_KillSwitch__c csKillSwitch = CS_KillSwitch__c.getOrgDefaults();
csKillSwitch.DisableFlows__c = false;
csKillSwitch.Disable_SMS__c = false;
csKillSwitch.DisableProcessBuilders__c = false;
csKillSwitch.DisableTriggers__c = false;
csKillSwitch.DisableValidationRules__c = false;
update csKillSwitch;

// contracts activation
List<Contract> contracts = [SELECT Id, Status FROM Contract];
for (Contract contract : contracts) {
    contract.Status = 'Active';
}
update contracts;


String OBFUSCATION_SUFFIX = '.invalid';

String obfuscatedUserEmail = 
	UserInfo.getUserEmail() 
	+ 
	(
		UserInfo.getUserEmail().endsWithIgnoreCase(OBFUSCATION_SUFFIX) 
		? 
			'' 
			: 
			OBFUSCATION_SUFFIX
	)
;


// adding generic settings
insert new Otis_Settings__c(
    OrgWidefromaddress__c = 'messagefromotisline@otis.com',
    OrgwideEmailDisplay__c = 'Do-Not-Reply',
    LogToEmailAddress__c = obfuscatedUserEmail,
    TextMessageErrorEmail__c = obfuscatedUserEmail,
    Schedule_Job_User__c = UserInfo.getUserId(),
    SendCustomerEmail__c = true,
    OtisREMEngineerContactId__c = [SELECT Id FROM Contact WHERE Name = 'OTIS REM-ROLE Engineer' LIMIT 1]?.Id,
    Integration_User_ProfileName__c = 'Otis System Integration'
);

// route coverages creation
List<ServiceTerritory> routes = [SELECT Id FROM ServiceTerritory WHERE RecordType.Name = 'Route'];
for(ServiceTerritory route: routes){
    ShiftCoverageGenerationInitial.createInitialCoverages(route.Id);
}

// update current user to bypass Lookup filters for successful data importing
update new User(Id = UserInfo.getUserId(), Bypass_Lookup_Filters__c = false);
