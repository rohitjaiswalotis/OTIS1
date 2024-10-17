
/*
* Exception with predefined name to be thrown to return value from apex script.
* Message should be a serialized json object, i.e. key-value pairs.
*/
public class ApexScriptReturnValueException extends Exception {  }

Organization org = [ SELECT Id, IsSandbox FROM Organization LIMIT 1];


Map<String, Object> propToValue = 
	new Map<String, Object> {
		'SF_SR_VAR_GLOBAL_ORG_ID_18'							=>		org.Id,
		'SF_SR_VAR_GLOBAL_ORG_ID_15'							=>		org.Id?.toString().left(15),
		'SF_SR_VAR_GLOBAL_IS_SANDBOX'							=>		org.IsSandbox,
		'SF_SR_VAR_GLOBAL_FS_INTEGRATION_PS_DESCRIPTION'		=> 		[ SELECT Id, Description FROM PermissionSet WHERE Name = 'sfdc_fieldservice' AND NamespacePrefix = 'sfdcInternalInt' ]?.Description
	}
;

if (org.IsSandbox == true) {
	propToValue.put(
		'SF_SR_VAR_GLOBAL_SANDBOX_NAME',
		(getSandboxName() ?? '')
	);
}

throw new ApexScriptReturnValueException(JSON.serialize(propToValue));



private static String getSandboxName() {
	
	try {
		
		String myDomainHostname = DomainCreator.getOrgMyDomainHostname();
		
		if (String.isNotBlank(myDomainHostname)) {
			
			return
				DomainParser.parse(
					myDomainHostname
				)?.getSandboxName()
			;
			
		}
		
	} catch (Exception exp) {
		
		// deliberately suppressing all exceptions
		
	}
	
	
	return null;
	
}