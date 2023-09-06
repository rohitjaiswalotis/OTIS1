
/*
* Exception with predefined name to be thrown to return value from apex script.
* Message should be a serialized json object, i.e. key-value pairs.
*/
public class ApexScriptReturnValueException extends Exception {  }

Organization org = [ SELECT Id, IsSandbox FROM Organization LIMIT 1];


Map<String, Object> propToValue = 
	new Map<String, Object> {
		'SF_SR_VAR_GLOBAL_IS_SANDBOX'			=>		org.IsSandbox
	}
;

throw new ApexScriptReturnValueException(JSON.serialize(propToValue));


