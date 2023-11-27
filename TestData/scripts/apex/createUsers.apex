Id mechanicProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service Mechanic' LIMIT 1].Id;
Id supervisorProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service Supervisor' LIMIT 1].Id;
Id mechanicRoleId = [SELECT Id FROM UserRole WHERE Name = 'Mechanic' LIMIT 1].Id;
Id supervisorRole = [SELECT Id FROM UserRole WHERE Name = 'Route Supervisor' LIMIT 1].Id;
String mechanic1Name = 'Mechanic Otis';
String mechanic2Name = 'Mechanic2 OTIS';
String mechanic3Name = 'Mechanic3 OTIS';
String supervisorName = 'Supervisor Otis';
List<String> userNames = new List<String>{
    mechanic1Name, mechanic2Name, mechanic3Name, supervisorName
};

List<User> existingUsers = [SELECT Id, Name FROM User WHERE Name IN :userNames];

List<User> usersToCreate = new List<User>();
List<String> existingUserNames = getExistingUserNames(existingUsers);
for (String userName : userNames) {
    if (existingUserNames.contains(userName)) {
        continue;
    }
    if (userName.startsWith('Mechanic')) {
        usersToCreate.add(createUser(userName, mechanicProfileId, mechanicRoleId));
    } else {
        usersToCreate.add(createUser(userName, supervisorProfileId, supervisorRole));

    }
}
insert usersToCreate;

usersToCreate.addAll(existingUsers);
List<Group> publicGroups = [SELECT Id from Group WHERE DeveloperName = 'Salesforce_GBO' LIMIT 1];
Group gboGroup;
if (!publicGroups.isEmpty()) {
    gboGroup = publicGroups[0];
}else{
    gboGroup= new Group(Name = 'Salesforce GBO', DeveloperName = 'Salesforce_GBO');
    insert gboGroup;
}

List<GroupMember> groupMembers = new List<GroupMember>();
for (User user : usersToCreate) {
    groupMembers.add(new GroupMember(GroupId = gboGroup.Id, UserOrGroupId = user.Id));
}
insert groupMembers;

public static User createUser(String name, Id profileId, Id roleId) {
    Integer randomNumber = Integer.valueOf((Math.random() * 100));
    return new User(Username =createUserName(randomNumber),
        ProfileId = profileId,
        UserRoleId = roleId,
        FirstName = name.split(' ')[0],
        LastName = name.split(' ')[1],
        IsActive = true,
        Alias = 'ALIA' + randomNumber,
        Email = 'testUser' + randomNumber + '@otis.com.void',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'ISO-8859-1',
        LanguageLocaleKey = 'en_US'
    );
}

public static String createUserName(Integer i) {
    String orgId = UserInfo.getOrganizationId();
    Integer randomInt = Integer.valueOf(Math.random() * 100);
    String randomSecs = System.now().format('ssSSS');
    return orgId + randomSecs + randomInt + i + '@otis.com.test';
}

public List<String> getExistingUserNames(List<User> users) {
    List<String> userNames = new List<String>();
    for (User user : users) {
        userNames.add(user.Name);
    }

    return userNames;
}