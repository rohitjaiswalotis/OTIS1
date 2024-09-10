
final String WORK_TYPE_NAME = 'Default Work Type';


// check if work type with predefined name already exist
Id workTypeId = [ SELECT Id FROM WorkType WHERE Name = :WORK_TYPE_NAME ORDER BY CreatedDate ASC LIMIT 1 ]?.Id;


// create new predefined work type if not exist
if (workTypeId == null) {
	
	WorkType newWorkType =  
		new WorkType(
			Name = WORK_TYPE_NAME,
			EstimatedDuration = 1,
			DurationType = 'Hours',
			ShouldAutoCreateSvcAppt = true
		)
	;
	
	insert newWorkType;
	
	workTypeId = newWorkType.Id;
	
}


// create/update settings
{
	
	OTISCustomSettings__c otisSettings = OTISCustomSettings__c.getOrgDefaults();
	
	otisSettings.DefaultWorkTypeId__c = 
		otisSettings.DefaultWorkTypeId__c ?? workTypeId
	;
	
	otisSettings.ImageUploadLimitInSA__c = 
		otisSettings.ImageUploadLimitInSA__c ?? 3
	;
	
	otisSettings.Optimizer_Finish_Date__c = 
		otisSettings.Optimizer_Finish_Date__c ?? 3
	;
	
	upsert otisSettings;
	
}

