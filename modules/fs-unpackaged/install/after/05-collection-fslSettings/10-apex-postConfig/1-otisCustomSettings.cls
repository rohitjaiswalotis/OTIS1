
final String SKILL_NAME = 'Repair';


// get repair skill id (if any)
Id skillId = [ SELECT Id FROM Skill WHERE DeveloperName = :SKILL_NAME ORDER BY CreatedDate ASC LIMIT 1 ]?.Id;


// create/update settings
if (skillId != null) {
	
	OTISCustomSettings__c otisSettings = OTISCustomSettings__c.getOrgDefaults();
	
	otisSettings.RepairSkillId__c = (
		otisSettings.RepairSkillId__c == null 
		? 
			skillId 
			: 
			otisSettings.RepairSkillId__c
	);
	
	upsert otisSettings;
	
}

