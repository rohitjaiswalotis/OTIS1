CS_KillSwitch__c csKillSwitch = CS_KillSwitch__c.getOrgDefaults();
    csKillSwitch.DisableFlows__c = true;
    csKillSwitch.Disable_SMS__c = true;
    csKillSwitch.DisableProcessBuilders__c = true;
    csKillSwitch.DisableTriggers__c = true;
    csKillSwitch.DisableValidationRules__c = true;

if (csKillSwitch.Id != null) {
    update csKillSwitch;
} else {
    insert csKillSwitch;
}

List<Schema.Location> buildings = [SELECT VisitorAddressId FROM Location];
for (Schema.Location building: buildings){
    building.VisitorAddressId = null;
}
update buildings;

Database.delete([SELECT Id FROM Task], false);
Database.delete([SELECT Id FROM AccountResource__c], false);
Database.delete([SELECT Id FROM BranchHoliday__c], false);
Database.delete([SELECT Id FROM BuildingOffice__c], false);
Database.delete([SELECT Id FROM BuildingContact__c], false);
Database.delete([SELECT Id FROM BuildingResource__c], false);
Database.delete([SELECT Id FROM WorkOrder], false);
Database.delete([SELECT Id FROM Case], false);
Database.delete([SELECT Id FROM RouteResource__c], false);
Database.delete([SELECT Id FROM Shift], false);
Database.delete([SELECT Id FROM ShiftPatternEntry], false);
Database.delete([SELECT Id FROM ShiftPattern], false);
Database.delete([SELECT Id FROM ShiftTemplate], false);
Database.delete([SELECT Id FROM InternalResource__c], false);
Database.delete([SELECT Id FROM ServiceCrew], false);
Database.delete([SELECT Id FROM ServiceTerritory], false);
Database.delete([SELECT Id FROM Contact], false);
Database.delete([SELECT Id FROM Contract], false);
Database.delete([SELECT Id FROM Account], false);
Database.delete([SELECT Id FROM Branch__c], false);
Database.delete([SELECT Id FROM OperatingHours WHERE Name = 'America/New York'], false);
Database.delete([SELECT Id FROM Address], false);
Database.delete([SELECT Id, BranchName__c FROM Location], false);
Database.delete([SELECT Id FROM BranchMemberRole__c], false);
Database.delete([SELECT Id FROM Asset], false);
Database.delete([SELECT Id FROM Holiday__c], false);
Database.delete([SELECT Id FROM WorkPerformedCode__c], false);
Database.delete([SELECT Id FROM ComponentCode__c], false);
Database.delete([SELECT Id FROM ContractLineItem__c], false);
Database.delete([SELECT Id FROM Group WHERE DeveloperName ='Salesforce_GBO'], false);
Database.delete([SELECT Id FROM CS_TriggerSettings__c], false);
Database.delete([SELECT Id FROM CS_KillSwitch__c], false);
Database.delete([SELECT Id FROM Otis_Settings__c], false);
