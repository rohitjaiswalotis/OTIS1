@IsTest
public class FSLAbsenceManagerTest {
    
    
    
    
    @IsTest
    static void testDailyAbsenceCreation() {
        User supervisor = UTIL_TestDataFactory.createUser('Field Service Supervisor');
        User serviceResourceUser =  UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert new List<User>{supervisor, serviceResourceUser};
        serviceResourceUser.ManagerId = supervisor.Id;
        update serviceResourceUser;
        ServiceResource resource = UTIL_TestDataFactory.createServiceResource('SR Resource', serviceResourceUser.Id, '908239421', 'mechanic@test.com');
        insert resource;
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
        absence.loggedInSupervisorId = supervisor.Id;
        absencesToCreate.add(absence);
        Test.startTest();
        FSLAbsenceManager.resourceAbsenceFromFlow(absencesToCreate);
        Test.stopTest();
        List<ResourceAbsence> absences = [SELECT Id, Type, Start, End, Description FROM ResourceAbsence];
        
        System.assertEquals(3, absences.size(), 'There should be 3 ResourceAbsences created for Daily recurrence');
    }
    @IsTest
    static void testMonthlyAbsenceCreation() {
        User supervisor = UTIL_TestDataFactory.createUser('Field Service Supervisor');
        User serviceResourceUser =  UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert new List<User>{supervisor, serviceResourceUser};
        serviceResourceUser.ManagerId = supervisor.Id;
        update serviceResourceUser;
        ServiceResource resource = UTIL_TestDataFactory.createServiceResource('SR Resource', serviceResourceUser.Id, '908239421', 'mechanic@test.com');
        insert resource;
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
        absence.endDate = absence.startTime.addMonths(2);
        absence.loggedInSupervisorId = supervisor.Id;
        absencesToCreate.add(absence);
        Test.startTest();
        FSLAbsenceManager.resourceAbsenceFromFlow(absencesToCreate);
        Test.stopTest();
        List<ResourceAbsence> absences = [SELECT Id, Type, Start, End, Description FROM ResourceAbsence ];
    
        System.assertEquals(3, absences.size(), 'There should be 3 ResourceAbsences created for Monthly recurrence');
    }
    @IsTest
    static void testYearlyAbsenceCreation() {
        // Create test data
        User supervisor = UTIL_TestDataFactory.createUser('Field Service Supervisor');
        User serviceResourceUser =  UTIL_TestDataFactory.createUser('Field Service Mechanic');
        insert new List<User>{supervisor, serviceResourceUser};
        serviceResourceUser.ManagerId = supervisor.Id;
        update serviceResourceUser;
        ServiceResource resource = UTIL_TestDataFactory.createServiceResource('SR Resource', serviceResourceUser.Id, '908239421', 'mechanic@test.com');
        insert resource;
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
        absence.reccurenceType = 'Yearly';
        absence.endDate = absence.startTime.addYears(2);
        absence.loggedInSupervisorId = supervisor.Id;
        absencesToCreate.add(absence);
        Test.startTest();
        FSLAbsenceManager.resourceAbsenceFromFlow(absencesToCreate);
        Test.stopTest();
        List<ResourceAbsence> absences = [SELECT Id, Type, Start, End, Description FROM ResourceAbsence];
        
        System.assertEquals(3, absences.size(), 'There should be 3 ResourceAbsences created for Yearly recurrence');
    }
}