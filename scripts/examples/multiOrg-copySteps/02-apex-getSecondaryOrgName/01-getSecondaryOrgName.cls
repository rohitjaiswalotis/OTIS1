
/*
* Exception with predefined name to be thrown to return value from apex script.
* Message should be a serialized json object, i.e. key-value pairs.
*/
public class ApexScriptReturnValueException extends Exception {  }



Map<String, Object> orgData = 
	new Map<String, Object> {
		'SF_SR_VAR_SECONDARY_ORG_ID'		=>		UserInfo.getOrganizationId(),
		'SF_SR_VAR_SECONDARY_ORG_NAME'		=>		UserInfo.getOrganizationName()
	}
;

throw new ApexScriptReturnValueException(JSON.serialize(orgData));


