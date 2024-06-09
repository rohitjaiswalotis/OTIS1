
Set<String> PERMISSION_SETS_TO_ASSIGN = 
	new Set<String> {
		'force.FieldServiceMobileStandardPermSet',
		'FSL_Dispatcher_Permissions',
		'FSL_Dispatcher_License',
		'FSL_Agent_Permissions',
		'FSL_Agent_License',
		'FSL_Admin_Permissions',
		'FSL_Admin_License',
		'Field_Service_Mobile_App_Builder_Permissions',
		'Field_Service_Document_Builder',
		'force.FieldServiceDocumentBuilderDispatcher'
	}
;

List<User> users = 
	new List<User> {
		new User(
			Id = UserInfo.getUserId()
		)
	}
;


// build permission sets registry
Map<String, PermissionSet> fullNameToPermissionSet = new Map<String, PermissionSet>(); {
	
	List<PermissionSet> permissionSets = [
		SELECT
			Id,
			Label,
			Name,
			NamespacePrefix
		FROM
			PermissionSet
	];
	
	
	for (PermissionSet ps : permissionSets) {
		
		fullNameToPermissionSet.put(
			normalize(
				String.isBlank(ps.NamespacePrefix) 
				? 
					ps.Name
					: 
					ps.NamespacePrefix + '.' + ps.Name
			),
			ps
		);
		
	}
	
}


List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();

// collect assignments
for (String psFullName : PERMISSION_SETS_TO_ASSIGN) {
	
	PermissionSet ps = fullNameToPermissionSet.get(normalize(psFullName));
	
	if (ps == null) {
		continue;
	}
	
	for (User usr : users) {
		
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



public static String normalize(Object source) {
	
	return
		(source ?? '').toString().trim().toLowerCase()
	;
	
}

