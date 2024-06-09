
/*
* Exception with predefined name to be thrown to return value from apex script.
* Message should be a serialized json object, i.e. key-value pairs.
*/
public class ApexScriptReturnValueException extends Exception {  }



Map<String, Object> propToValue = 
	new Map<String, Object> {
		'SF_SR_VAR_APEX1'			=>		'dummy_apex_name test',
		'SF_SR_VAR_APEX2'			=>		'dummy_apex_type',
		'SF_SR_VAR_APEX_RECORD'		=>		'firstName:John;lastName:Smith',
		'SF_SR_VAR_APEX_IDS'		=>		'id1,id2, id3'
	}
;

throw new ApexScriptReturnValueException(JSON.serialize(propToValue));


