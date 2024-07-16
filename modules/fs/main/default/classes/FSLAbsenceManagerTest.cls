@IsTest
public class FSLAbsenceManagerTest {
 
    @TestSetup
    static void setupTestData() {
        // Create test data for supervisor and service resource
        User supervisor = UTIL_TestDataFactory.createUser('Field Service Supervisor');
        User serviceResourceUser = UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert new List<User>{supervisor, serviceResourceUser};
        serviceResourceUser.ManagerId = supervisor.Id;
        update serviceResourceUser;
 
        ServiceResource resource = UTIL_TestDataFactory.createServiceResource('SR Resource', serviceResourceUser.Id, '908239421', 'mechanic@test.com');
        insert resource;
    }
 
    @IsTest
    static void testDailyAbsenceCreation() {
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceResource resource = serviceResources[0];
 
        List<FSLAbsenceManager.ResourceabsenceWrapper> absencesToCreate = new List<FSLAbsenceManager.ResourceabsenceWrapper>();
        FSLAbsenceManager.ResourceabsenceWrapper absence = new FSLAbsenceManager.ResourceabsenceWrapper();
        absence.absenceType = 'Vacation';
        absence.startTime = system.now().addHours(1);
        absence.endTime = absence.startTime.addHours(2);
        absence.street = '123 Main St';
absence.city = 'San Francisco';
absence.country = 'USA';
        absence.postalCode = '94105';
        absence.state = 'CA';
        absence.description = 'Test absence';
        absence.internalId = '12313';
        absence.isApproved = true;
        absence.reccurenceType = 'Daily';
        absence.endDate = system.now().addDays(2);
        absence.loggedInSupervisorId = UserInfo.getUserId();
        absence.ids = new List<String>{resource.Id};
        absencesToCreate.add(absence);
 
        Test.startTest();
        FSLAbsenceManager.resourceAbsenceFromFlow(absencesToCreate);
        Test.stopTest();
 
        List<ResourceAbsence> absences = [SELECT Id, Type, Start, End, Description FROM ResourceAbsence];
        Assert.areEqual(2, absences.size());
        Assert.areEqual('Vacation', absences[0].Type);
        Assert.areEqual('Test absence', absences[0].Description);
    }
 
    @IsTest
    static void testMonthlyAbsenceCreation() {
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceResource resource = serviceResources[0];
 
        List<FSLAbsenceManager.ResourceabsenceWrapper> absencesToCreate = new List<FSLAbsenceManager.ResourceabsenceWrapper>();
        FSLAbsenceManager.ResourceabsenceWrapper absence = new FSLAbsenceManager.ResourceabsenceWrapper();
        absence.absenceType = 'Vacation';
        absence.startTime = system.now().addHours(2);
        absence.endTime = absence.startTime.addDays(1);
        absence.street = '123 Main St';
absence.city = 'San Francisco';
absence.country = 'USA';
        absence.postalCode = '94105';
        absence.state = 'CA';
        absence.description = 'Test absence';
        absence.internalId = '12313';
        absence.isApproved = true;
        absence.reccurenceType = 'Monthly';
        absence.endDate = system.now().addMonths(2);
        absence.loggedInSupervisorId = UserInfo.getUserId();
        absence.ids = new List<String>{resource.Id};
        absencesToCreate.add(absence);
 
        Test.startTest();
        FSLAbsenceManager.resourceAbsenceFromFlow(absencesToCreate);
        Test.stopTest();
 
        List<ResourceAbsence> absences = [SELECT Id, Type, Start, End, Description FROM ResourceAbsence];
        Assert.areEqual(3, absences.size());
        Assert.areEqual('Vacation', absences[0].Type);
        Assert.areEqual('Test absence', absences[0].Description);
    }
 
    @IsTest
    static void testWeeklyAbsenceCreation() {
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceResource resource = serviceResources[0];
 
        List<FSLAbsenceManager.ResourceabsenceWrapper> absencesToCreate = new List<FSLAbsenceManager.ResourceabsenceWrapper>();
        FSLAbsenceManager.ResourceabsenceWrapper absence = new FSLAbsenceManager.ResourceabsenceWrapper();
        absence.absenceType = 'Vacation';
        absence.startTime = system.now().addHours(2);
        absence.endTime = absence.startTime.addDays(1);
        absence.street = '123 Main St';
        absence.city = 'San Francisco';
        absence.country = 'USA';
        absence.postalCode = '94105';
        absence.state = 'CA';
        absence.description = 'Test absence';
        absence.internalId = '12313';
        absence.isApproved = true;
        absence.reccurenceType = 'Weekly';
        absence.endDate = system.now().addDays(14);
        absence.loggedInSupervisorId = UserInfo.getUserId();
        absence.ids = new List<String>{resource.Id};
        absencesToCreate.add(absence);
 
        Test.startTest();
        FSLAbsenceManager.resourceAbsenceFromFlow(absencesToCreate);
        Test.stopTest();
 
        List<ResourceAbsence> absences = [SELECT Id, Type, Start, End, Description FROM ResourceAbsence];
        Assert.areEqual(2, absences.size());
        
    }
 
   
}