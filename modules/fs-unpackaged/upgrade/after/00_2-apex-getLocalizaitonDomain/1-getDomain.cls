
public class ApexScriptReturnValueException extends Exception {  }

String domain = LocalizationSettings__c.getOrgDefaults()?.Domain__c;

Map<String, Object> propToValue = 
	new Map<String, Object> {
		'SF_SR_VAR_GLOBAL_LOCALIZATION_DOMAIN'
		=>
		domain == null ? '' : domain
	}
;

throw new ApexScriptReturnValueException(JSON.serialize(propToValue));

