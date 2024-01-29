//Disabling Automation Processes
insert new CS_KillSwitch__c(
    DisableFlows__c = true,
    Disable_SMS__c = true,
    DisableProcessBuilders__c = true,
    DisableTriggers__c = true,
    DisableValidationRules__c = true
);

// Update current user to bypass Lookup filters for successful data importing
update new User(Id = UserInfo.getUserId(), Bypass_Lookup_Filters__c = true);

