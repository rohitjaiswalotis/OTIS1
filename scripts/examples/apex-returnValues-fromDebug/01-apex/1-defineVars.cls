
Map<String, Object> propToValue = 
	new Map<String, Object> {
		'SF_SR_VAR_APEX1'			=>		'dummy_apex_name test',
		'SF_SR_VAR_APEX2'			=>		'dummy_apex_type',
		'SF_SR_VAR_APEX_RECORD'		=>		'firstName:John;lastName:Smith',
		'SF_SR_VAR_APEX_IDS'		=>		'id1,id2, id3'
	}
;


// DML should not be rolled back since debug statement is used to return values from script, not exception throwing approach
insert new Account(
	Name = 'Test_' + UUID.randomUUID().toString()
);


/*
* Logging debug message with predefined label and format to return value from apex script.
* Message after label should be a serialized json object, i.e. key-value pairs.
*/
System.debug('ApexScriptReturnValue: ' + JSON.serialize(propToValue));


