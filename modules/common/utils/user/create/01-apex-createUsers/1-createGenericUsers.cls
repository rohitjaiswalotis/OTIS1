
final String DEFAULT_PASSWORD = 'someDefaultPasswordHere_withDigits_from1_to9';


String currentUserName = UserInfo.getUserName();
String AT_HOST_NAME_SUFFIX = currentUserName.replaceFirst('[^@]+(@.*)', '$1');

// special handling of scratch org username format
if (currentUserName.endsWithIgnoreCase('@example.com')) {
	AT_HOST_NAME_SUFFIX = '-' + (currentUserName.contains('-') ? currentUserName.substringAfter('-') : currentUserName);
}


// get groups
Id sfGBOGroupId = getGroupId('Salesforce_GBO');


// create admin user
{
	
	User u = generateTemplateUser(getProfileId('System Administrator'));
	
	u.UserName = 'otisadmin' + AT_HOST_NAME_SUFFIX;
	u.Email = 'otisadmin@dreamcompany.com';
	u.FirstName = 'Admin';
	u.LastName = 'OTIS';
	u.Alias = 'otisadm';
	u.CommunityNickname = 'otisadm';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
	}
	
}


// create csr expert
{
	
	User u = generateTemplateUser(getProfileId('CSR Expert'), getRoleId('CSRExpert'));
	
	u.UserName = 'csrexpert' + AT_HOST_NAME_SUFFIX;
	u.Email = 'csrexpert@dreamcompany.com';
	u.FirstName = 'Expert';
	u.LastName = 'CSR';
	u.Alias = 'csrexp';
	u.CommunityNickname = 'csrexp';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
		
		Database.insert(
			new List<GroupMember> {
				new GroupMember(GroupId = sfGBOGroupId, UserOrGroupId = u.Id),
				new GroupMember(GroupId = getGroupId('CSRCoreGroup'), UserOrGroupId = u.Id),
				new GroupMember(GroupId = getGroupId('CSRNonBeginners'), UserOrGroupId = u.Id)
			},
			false
		);
		
	}
	
}


// create otis integration
{
	
	User u = generateTemplateUser(getProfileId('Otis System Integration'), getRoleId('MigrationIntegration'));
	
	u.UserName = 'otisint' + AT_HOST_NAME_SUFFIX;
	u.Email = 'otisint@dreamcompany.com';
	u.FirstName = 'Integration';
	u.LastName = 'OTIS';
	u.Alias = 'otisint';
	u.CommunityNickname = 'otisint';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		try {
			
			System.setPassword(
				u.Id,
				DEFAULT_PASSWORD
			);
			
		} catch (Exception exp) {
			
		}
		
	}
	
}


// create csr supervisor
{
	
	User u = generateTemplateUser(getProfileId('CSR Supervisor'), getRoleId('CSRSupervisor'));
	
	u.UserName = 'csrsupervisor' + AT_HOST_NAME_SUFFIX;
	u.Email = 'csrsupervisor@dreamcompany.com';
	u.FirstName = 'Supervisor';
	u.LastName = 'CSR';
	u.Alias = 'csrsv';
	u.CommunityNickname = 'csrsv';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
		
		Database.insert(
			new List<GroupMember> {
				new GroupMember(GroupId = sfGBOGroupId, UserOrGroupId = u.Id),
				new GroupMember(GroupId = getGroupId('CSRCoreGroup'), UserOrGroupId = u.Id),
				new GroupMember(GroupId = getGroupId('CSRNonBeginners'), UserOrGroupId = u.Id)
			},
			false
		);
		
	}
	
}


// create csr beginner
{
	
	User u = generateTemplateUser(getProfileId('CSR Beginner'), getRoleId('CSRBeginner'));
	
	u.UserName = 'csrbeginner' + AT_HOST_NAME_SUFFIX;
	u.Email = 'csrbeginner@dreamcompany.com';
	u.FirstName = 'Beginner';
	u.LastName = 'CSR';
	u.Alias = 'csrbeg';
	u.CommunityNickname = 'csrbeg';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
		
		Database.insert(
			new List<GroupMember> {
				new GroupMember(GroupId = sfGBOGroupId, UserOrGroupId = u.Id),
				new GroupMember(GroupId = getGroupId('CSRCoreGroup'), UserOrGroupId = u.Id)
			},
			false
		);
		
	}
	
}


// create field service admin
{
	
	User u = generateTemplateUser(getProfileId('Field Service Admin'), getRoleId('FieldServiceAdmin'));
	
	u.UserName = 'fsadmin' + AT_HOST_NAME_SUFFIX;
	u.Email = 'fsadmin@dreamcompany.com';
	u.FirstName = 'Admin';
	u.LastName = 'FieldService';
	u.Alias = 'fsadmin';
	u.CommunityNickname = 'fsadmin';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
		
		Database.insert(
			new List<GroupMember> {
				new GroupMember(GroupId = sfGBOGroupId, UserOrGroupId = u.Id),
				new GroupMember(GroupId = getGroupId('Field_Service_Admin_group'), UserOrGroupId = u.Id)
			},
			false
		);
		
	}
	
}


// create field service supervisor
{
	
	User u = generateTemplateUser(getProfileId('Field Service Supervisor'), getRoleId('RouteSupervisor'));
	
	u.UserName = 'fssupervisor' + AT_HOST_NAME_SUFFIX;
	u.Email = 'fssupervisor@dreamcompany.com';
	u.FirstName = 'Supervisor';
	u.LastName = 'FieldService';
	u.Alias = 'fssuper';
	u.CommunityNickname = 'fssuper';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
		
		Database.insert(
			new List<GroupMember> {
				new GroupMember(GroupId = sfGBOGroupId, UserOrGroupId = u.Id)
			},
			false
		);
		
	}
	
}


// create mechanic
{
	
	User u = generateTemplateUser(getProfileId('Field Service Mechanic'/*'Mechanic User'*/), getRoleId('Mechanic'));
	
	u.UserName = 'ordinarymechanic' + AT_HOST_NAME_SUFFIX;
	u.Email = 'ordinarymechanic@dreamcompany.com';
	u.FirstName = 'Mechanic';
	u.LastName = 'Ordinary';
	u.Alias = 'omechan';
	u.CommunityNickname = 'omechan';
	
	Database.SaveResult r = Database.insert(u, false);
	
	if (r.isSuccess()) {
		
		System.setPassword(
			u.Id,
			DEFAULT_PASSWORD
		);
		
		Database.insert(
			new List<GroupMember> {
				new GroupMember(GroupId = sfGBOGroupId, UserOrGroupId = u.Id)
			},
			false
		);
		
	}
	
}


private static User generateTemplateUser(Id profileId) {
	return generateTemplateUser(profileId, null);
}


private static User generateTemplateUser(Id profileId, Id roleId) {
	
	return 
		new User(
			ProfileId 			= 		profileId,
			UserRoleId 			= 		roleId,
			IsActive			= 		true,
            CompanyName			=		'AutoGenerated',
			Title 				=		'Mr',
			Street 				=		'Backer Street',
			Phone 				= 		'000000',
			MobilePhone 		= 		'000001',
			TimeZoneSidKey 		= 		'America/Los_Angeles',
			EmailEncodingKey 	= 		'UTF-8',
			LanguageLocaleKey	=		'en_US',
			LocaleSidKey 		= 		'en_US'
		)
		
	;

}


private static String normalize(String source) {
	
	return 
		source?.trim().toLowerCase()
	;
	
}


private static Id getProfileId(String name) {
	return [ SELECT Id, Name FROM Profile WHERE Name = :name ]?.Id;
}


private static Id getGroupId(String developerName) {
	return [ SELECT Id FROM Group WHERE DeveloperName = :developerName ]?.Id;
}


private static Id getRoleId(String developerName) {
	return [ SELECT Id FROM UserRole WHERE DeveloperName = :developerName ]?.Id;
}


