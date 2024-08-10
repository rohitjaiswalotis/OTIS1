
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


throw new ApexScriptReturnValueException(JSON.serialize(propToValue));


