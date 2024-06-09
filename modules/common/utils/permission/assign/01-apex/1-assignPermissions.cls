
Map<String, String> profileNameToPermSetGroup = 
	new Map<String, String> {
		'System Administrator'				=>		'FS_Admin_Persona',
		'Call Center Admin'					=>		'FS_CallCenterAdmin_Persona',
		'ContractManager'					=>		'FS_ContractManager_Persona',
		'CSR Beginner'						=>		'FS_CSRBeginner_Persona',
		'CSR Expert'						=>		'FS_CSRExpert_Persona',
		'CSR Supervisor'					=>		'FS_CSRSupervisor_Persona',
		'Demo_user'							=>		'FS_DemoUser_Persona',
		'Field Engineer'					=>		'FS_FieldEngineer_Persona',
		'Field Service Admin'				=>		'FS_FieldServiceAdmin_Persona',
		'Field Service Mechanic'			=>		'FS_FieldServiceMechanic_Persona',
		'Field Service Supervisor'			=>		'FS_FieldServiceSupervisor_Persona',
		'FS Office Admin'					=>		'FS_FSOfficeAdmin_Persona',
		'FSL Optimization'					=>		'FS_FSLOptimization_Persona',
		'Mechanic User'						=>		'FS_MechanicUser_Persona',
		'Otis System Integration'			=>		'FS_OtisSystemIntegration_Persona',
		'Read Only_V2'						=>		'FS_ReadOnlyV2_Persona',
		'Remote Engineer'					=>		'FS_RemoteEngineer_Persona',
		'Solution Manager'					=>		'FS_SolutionManager_Persona',
		'Support Analyst - Readonly'		=>		'FS_SupportAnalystReadonly_Persona',
		'Support Analyst - Readonly_BCK'	=>		'FS_SupportAnalystReadOnlyBCK_Persona'
	}
;


// grab permission set groups
List<PermissionSetGroup> permissionSetGroups = [
	SELECT
		Id,
		DeveloperName,
		NamespacePrefix,
		Status
	FROM
		PermissionSetGroup
	WHERE
		DeveloperName IN :profileNameToPermSetGroup.values()
		AND
		NamespacePrefix = ''
];

// index permisson set groups by dev name
Map<String, Id> permSetGroupNameToId = new Map<String, Id>(); {
	
	for (PermissionSetGroup psg : permissionSetGroups) {
		permSetGroupNameToId.put(
			psg.DeveloperName,
			psg.Id
		);
	}
	
}


// collect permission set group assignments
List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>(); {
	
	for (String profileName : profileNameToPermSetGroup.keySet()) {
		
		Id permSetGroupId = (
			permSetGroupNameToId.get(
				profileNameToPermSetGroup.get(
					profileName
				)
			)
		);
		
		if (permSetGroupId == null) {
			continue;
		}
		
		
		// grab active users with specified profile and no permission set group assigned
		List<User> users = [
			SELECT
				Id,
				Name
			FROM
				User
			WHERE
				Profile.Name = :profileName
				AND
				IsActive = true
				AND 
				Id NOT IN (
					SELECT 
						AssigneeId 
					FROM 
						PermissionSetAssignment
					WHERE 
						PermissionSetGroupId = :permSetGroupId
				)
		];
		
		if (users.isEmpty()) {
			continue;
		}
		
		
		// collect assignments
		for (User usr : users) {
			psa.add(
				new PermissionSetAssignment(
					AssigneeId = usr.Id,
					PermissionSetGroupId = permSetGroupId
				)
			);
		}
		
	}
	
}


if (psa.isEmpty()) {
	return;
}

// actually create permission set group assignments
insert psa;


