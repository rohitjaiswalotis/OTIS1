
/*
* Exception with predefined name to be thrown to return value from apex script.
* Message should be a serialized json object, i.e. key-value pairs.
*/
public class ApexScriptReturnValueException extends Exception {  }

Map<String, Object> propToValue = new Map<String, Object>();


// get default mobile settings
Id defaultFSMobileSettingId = [ 
	SELECT Id, DeveloperName, MasterLabel, IsDefault FROM FieldServiceMobileSettings WHERE IsDefault = true ORDER BY CreatedDate DESC LIMIT 1 
]?.Id;


propToValue.put(
	'SF_SR_VAR_MOBILE_SETTING_ID', 
	defaultFSMobileSettingId == null ? '' : defaultFSMobileSettingId
);


// get KPI Dashboards Mechanics
Id kpiDashboardMechanicsId = [ 
	SELECT Id, FolderName, Title, DeveloperName FROM Dashboard 
	WHERE FolderName = 'KPI Dashboards for Mechanics' AND Title = 'KPI Dashboards Mechanics' 
	ORDER BY CreatedDate DESC LIMIT 1 
]?.Id;


if (kpiDashboardMechanicsId != null) {
	propToValue.put(
		'SF_SR_VAR_KPI_DASHBOARDS_MECHANICS_ID', 
		kpiDashboardMechanicsId
	);
}


throw new ApexScriptReturnValueException(JSON.serialize(propToValue));


