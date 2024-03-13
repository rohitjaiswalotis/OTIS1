
Set<String> PERMISSION_SETS_TO_ASSIGN = 
	new Set<String> {
		'FSL_Dispatcher_License',
		'FSL_Agent_Permissions',
		'FSL_Agent_License',
		'FSL_Admin_Permissions',
		'FSL_Admin_License',
		'Field_Service_Mobile_App_Builder_Permissions'
	}
;

List<User> users = 
	new List<User> {
		new User(
			Id = UserInfo.getUserId()
		)
	}
;


// grab permission sets
List<PermissionSet> permissionSets = [
	SELECT
		Id,
		Label,
		Name,
		NamespacePrefix
	FROM
		PermissionSet
	WHERE
		Name IN :PERMISSION_SETS_TO_ASSIGN
		AND
		NamespacePrefix = ''
];


List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();

// collect assignments
for (User usr : users) {
	
	for (PermissionSet ps : permissionSets) {
		
		psa.add(
			new PermissionSetAssignment(
				AssigneeId = usr.Id,
				PermissionSetId = ps.Id
			)
		);
		
	}
	
}


if (psa.isEmpty()) {
	return;
}

// actually create permission set assignments
Database.insert(psa, false);


