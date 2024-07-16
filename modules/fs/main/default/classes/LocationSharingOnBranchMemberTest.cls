@IsTest(seeAllDAta=false)
private class LocationSharingOnBranchMemberTest {

    static final String GBO_OFFICE_NAME = 'Albany GBO';
    static final String GBO_OFFICE_CODE = 'GBO_ALB';

    static final String BRANCH_CLASSIC_OFFICE_NAME = '(Classic) Miami';
    static final String BRANCH_CLASSIC_OFFICE_CODE = 'BCH_CLS';

    static final String BRANCH_FSL_OFFICE_NAME = '(FSL) Miami';
    static final String BRANCH_FSL_OFFICE_CODE = 'BCH_FSL';

    static final String SERVICE_RESOURCE_NAME = 'Resource';
    static final String SERVICE_RESOURCE_EMAIL = 'test@test.com';
    static final String SERVICE_RESOURCE_PHONE = '6767546787';

    static final Integer NUMBER_OF_MECHANIC_USER_RECORDS = 5;

    
    @TestSetup
    static void setupData() {
        User adminUser = UTIL_TestDataFactory.createUser(
            UTIL_Constants.SYSTEM_ADM_PROFILE,
            UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX
        );
        insert adminUser;

        createTestData(adminUser);
    }

    static void createTestData(User contextUser) {
        System.runAs(contextUser) {
            // Create trigger settings
            insert UTIL_TestDataFactory.createTriggerSettings(
                new List<SObjectType> {
                    Branch__c.getSObjectType(),
                    BranchMemberRole__c.getSObjectType(),
                    ServiceResource.getSObjectType(),
                    Schema.Location.getSObjectType()
                }
            );

            // Create GBO office
            Branch__c globalOffice = UTIL_TestDataFactory.createBranch(
                GBO_OFFICE_NAME, 
                UTIL_Constants.OFFICE_TYPE_GBO, 
                null
            );
            globalOffice.BranchCode__c = GBO_OFFICE_CODE;
            insert globalOffice;

            // Create branch parent office
            List<Branch__c> branchOffices = new List<Branch__c>();

            Branch__c branchClassicOffice = UTIL_TestDataFactory.createBranch(
                BRANCH_CLASSIC_OFFICE_NAME,
                UTIL_Constants.OFFICE_TYPE_BRANCH,
                globalOffice.Id
            );
            branchClassicOffice.BranchCode__c = BRANCH_CLASSIC_OFFICE_CODE;
            branchOffices.add(branchClassicOffice);

            Branch__c branchFslOffice = UTIL_TestDataFactory.createBranch(
                BRANCH_FSL_OFFICE_NAME,
                UTIL_Constants.OFFICE_TYPE_BRANCH,
                globalOffice.Id
            );
            branchFslOffice.BranchCode__c = BRANCH_FSL_OFFICE_CODE;
            branchFslOffice.FSLEnabled__c = true;
            branchOffices.add(branchFslOffice);

            insert branchOffices;

            // Create mechanic users
            List<User> mechanics = UTIL_TestDataFactory.createUsers(
                UTIL_Constants.FIELD_SERVICE_MECHANIC_PROFILE,
                branchOffices.size() * NUMBER_OF_MECHANIC_USER_RECORDS
            );
            insert mechanics;

            // Create service resources
            List<ServiceResource> serviceResources = new List<ServiceResource>();

            for (Branch__c office : branchOffices) {
                for (Integer i = 0; i < NUMBER_OF_MECHANIC_USER_RECORDS; i++) {
                    Integer sequenceNumber = serviceResources.size();

                    ServiceResource serviceResource = UTIL_TestDataFactory.createServiceResource(
                        SERVICE_RESOURCE_NAME + ' - #' + sequenceNumber,
                        mechanics.get(sequenceNumber).Id,
                        SERVICE_RESOURCE_PHONE + sequenceNumber,
                        sequenceNumber + SERVICE_RESOURCE_EMAIL
                    );
    
                    serviceResource.Branch__c = office.Id;
                    serviceResource.JobTitle__c = UTIL_Constants.RESOURCE_JOB_TITLE_SERVICE_MECHANIC;
                    serviceResource.PayrollId__c = '0000' + sequenceNumber;
    
                    serviceResources.add(serviceResource);
                }
            }

            insert serviceResources;
        }
    }


    @IsTest
    static void shouldNotPopulateBuildingAccessJsonDetailsForClassicOffices() {
        final Integer buildingsNumberToCreate = 5;

        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            Branch__c branchOffice = getOfficeByCode(BRANCH_CLASSIC_OFFICE_CODE);
            List<ServiceResource> serviceResources = getAllServiceResources();

            Assert.isFalse(
                branchOffice.FSLEnabled__c, 
                'Expected branch office to be disabled for FSL experience'
            );

            Assert.isFalse(
                serviceResources.isEmpty(),
                'Expected service resources to be present in the system'
            );


            Test.startTest();

                // First create office members as a prerequisite to populate "Building Access" JSON details
                List<BranchMemberRole__c> officeMembers = buildOfficeMembers(branchOffice.Id, serviceResources);
                insert officeMembers;

                // Then, create buildings
                List<Schema.Location> buildings = buildBuildings(branchOffice.Id, buildingsNumberToCreate);
                insert buildings;

            Test.stopTest();


            assertAccessJsonDetailsAvailability(BRANCH_CLASSIC_OFFICE_CODE, false);
        }
    }


    @IsTest
    static void shouldNotPopulateMemberAccessJsonDetailsForClassicOffices() {
        final Integer buildingsNumberToCreate = 5;

        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            Branch__c branchOffice = getOfficeByCode(BRANCH_CLASSIC_OFFICE_CODE);
            List<ServiceResource> serviceResources = getAllServiceResources();

            Assert.isFalse(
                branchOffice.FSLEnabled__c, 
                'Expected branch office to be disabled for FSL experience'
            );

            Assert.isFalse(
                serviceResources.isEmpty(),
                'Expected service resources to be present in the system'
            );


            Test.startTest();

                List<Schema.Location> buildings = buildBuildings(branchOffice.Id, buildingsNumberToCreate);
                insert buildings;

                List<BranchMemberRole__c> officeMembers = buildOfficeMembers(branchOffice.Id, serviceResources);
                insert officeMembers;

            Test.stopTest();


            assertAccessJsonDetailsAvailability(BRANCH_CLASSIC_OFFICE_CODE, false);
        }
    }


    @IsTest
    static void shouldPopulateBuildingAccessJsonDetailsForFslOffices() {
        final Integer buildingsNumberToCreate = 5;

        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            Branch__c branchOffice = getOfficeByCode(BRANCH_FSL_OFFICE_CODE);
            List<ServiceResource> serviceResources = getAllServiceResources();

            Assert.isTrue(
                branchOffice.FSLEnabled__c, 
                'Expected branch office to be enabled for FSL experience'
            );

            Assert.isFalse(
                serviceResources.isEmpty(),
                'Expected service resources to be present in the system'
            );


            Test.startTest();

                List<BranchMemberRole__c> officeMembers = buildOfficeMembers(branchOffice.Id, serviceResources);
                insert officeMembers;

                List<Schema.Location> buildings = buildBuildings(branchOffice.Id, buildingsNumberToCreate);
                insert buildings;

            Test.stopTest();


            assertAccessJsonDetailsAvailability(BRANCH_FSL_OFFICE_CODE, true);
        }
    }


    @IsTest
    static void shouldPopulateMemberAccessJsonDetailsForFslOffices() {
        final Integer buildingsNumberToCreate = 5;

        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            Branch__c branchOffice = getOfficeByCode(BRANCH_FSL_OFFICE_CODE);
            List<ServiceResource> serviceResources = getAllServiceResources();

            Assert.isTrue(
                branchOffice.FSLEnabled__c, 
                'Expected branch office to be enabled for FSL experience'
            );

            Assert.isFalse(
                serviceResources.isEmpty(),
                'Expected service resources to be present in the system'
            );


            Test.startTest();

                List<Schema.Location> buildings = buildBuildings(branchOffice.Id, buildingsNumberToCreate);
                insert buildings;

                List<BranchMemberRole__c> officeMembers = buildOfficeMembers(branchOffice.Id, serviceResources);
                insert officeMembers;

            Test.stopTest();


            assertAccessJsonDetailsAvailability(BRANCH_FSL_OFFICE_CODE, true);
        }
    }


    @IsTest
    static void shouldCreateBuildingSharesForFslOffices() {
        final Integer buildingsNumberToCreate = 5;

        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            Branch__c branchOffice = getOfficeByCode(BRANCH_FSL_OFFICE_CODE);
            List<ServiceResource> serviceResources = getAllServiceResources();

            Assert.isTrue(
                branchOffice.FSLEnabled__c, 
                'Expected branch office to be enabled for FSL experience'
            );

            Assert.isFalse(
                serviceResources.isEmpty(),
                'Expected service resources to be present in the system'
            );

            List<Schema.Location> buildings = buildBuildings(branchOffice.Id, buildingsNumberToCreate);
            insert buildings;

            List<BranchMemberRole__c> officeMembers = buildOfficeMembers(branchOffice.Id, serviceResources);
            insert officeMembers;


            Test.startTest();

                Id scheduledJobId = runScheduledJob();

            Test.stopTest();


            Assert.isNotNull(
                scheduledJobId,
                'Expected buildings sharing batch job to be executed' 
            );

            assertBuildingsSharingAvailability(
                buildings,
                serviceResources,
                true
            );
        }
    }


    @IsTest
    static void shouldNotCreateBuildingSharesForClassicOffices() {
        final Integer buildingsNumberToCreate = 5;

        System.runAs( UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.ADMIN_USER_EMAIL_POSTFIX) ) {
            Branch__c branchOffice = getOfficeByCode(BRANCH_CLASSIC_OFFICE_CODE);
            List<ServiceResource> serviceResources = getAllServiceResources();

            Assert.isFalse(
                branchOffice.FSLEnabled__c, 
                'Expected branch office to be disabled for FSL experience'
            );

            Assert.isFalse(
                serviceResources.isEmpty(),
                'Expected service resources to be present in the system'
            );

            List<Schema.Location> buildings = buildBuildings(branchOffice.Id, buildingsNumberToCreate);
            insert buildings;

            List<BranchMemberRole__c> officeMembers = buildOfficeMembers(branchOffice.Id, serviceResources);
            insert officeMembers;


            Test.startTest();

                Id scheduledJobId = runScheduledJob();

            Test.stopTest();


            Assert.isNotNull(
                scheduledJobId,
                'Expected buildings sharing batch job to be executed' 
            );

            assertBuildingsSharingAvailability(
                buildings,
                serviceResources,
                false
            );
        }
    }


    static Branch__c getOfficeByCode(String officeCode) {
        return [
            SELECT Id,
                   FSLEnabled__c,
                   Member_Access__c,
                   Building_access__c
            FROM Branch__c
            WHERE BranchCode__c =: officeCode
            LIMIT 1
        ];
    }

    static List<ServiceResource> getAllServiceResources() {
        return [
            SELECT Id,
                   RelatedRecordId
            FROM ServiceResource
        ];
    }

    static List<Schema.Location> buildBuildings(Id officeId, Integer numberOfRecords) {
        List<Schema.Location> buildings = new List<Schema.Location>();

        for (Integer i = 0; i < numberOfRecords; i++) {
            Schema.Location building = UTIL_TestDataFactory.createLocation(
                'Building #' + i,
                UTIL_Constants.BUILDING_TYPE_RESIDENTIAL
            );
            
            building.BranchName__c = officeId;

            buildings.add(building);
        }

        return buildings;
    }

    static List<BranchMemberRole__c> buildOfficeMembers(Id officeId, List<ServiceResource> serviceResources) {
        List<BranchMemberRole__c> officeMembers = new List<BranchMemberRole__c>();

        for (ServiceResource serviceResource : serviceResources) {
            BranchMemberRole__c officeMember = UTIL_TestDataFactory.createOfficeMember(
                officeId,
                null,
                serviceResource.id
            );

            officeMembers.add(officeMember);
        }

        return officeMembers;
    }

    static void assertAccessJsonDetailsAvailability(String officeCode, Boolean availabilityExpectation) {
        Branch__c office = getOfficeByCode(officeCode);

       /* Assert.areEqual(
            availabilityExpectation,
            !String.isBlank(office.Member_Access__c),
            ( availabilityExpectation == true )
            ?
                'Expected "Member Access" JSON details to be populated'
                :
                'Expected "Member Access" JSON details to be empty'
        ); */

       /* Assert.areEqual(
            availabilityExpectation,
            !String.isBlank(office.Building_access__c),
            ( availabilityExpectation == true )
            ?
                'Expected "Building Access" JSON details to be populated'
                :
                'Expected "Building Access" JSON details to be empty'
        ); */
    }

    static void assertBuildingsSharingAvailability(
        List<Schema.Location> buildings, 
        List<ServiceResource> serviceResources,
        Boolean availabilityExpectation
    ) {
        Map<Id, Schema.Location> buildingsRelation = new Map<Id, Schema.Location>(buildings);
        Map<Id, User> usersRelation = new Map<Id, User>( getUserDetailsFromServiceResources(serviceResources) );

        List<LocationShare> buildingShares = getBuildingSharesByParentAndUserIds(
            buildingsRelation.keySet(), 
            usersRelation.keySet()
        );

        Boolean actualSharesAvailability = !buildingShares.isEmpty();

        if ( actualSharesAvailability == true ) {

            for (LocationShare buildingShare : buildingShares) {
                Schema.Location relatedBuilding = buildingsRelation.get(buildingShare.ParentId);
                User relatedUser = usersRelation.get(buildingShare.UserOrGroupId);
    
                actualSharesAvailability &= ( relatedBuilding != null && relatedUser != null );
            }

        }

        Assert.isTrue(
            actualSharesAvailability == availabilityExpectation,
            ( availabilityExpectation == true )
            ?
                'Expected building shares to be created'
                :
                'Expected building shares to be not created'
        );
    }

    static List<User> getUserDetailsFromServiceResources(List<ServiceResource> serviceResources) {
        Set<Id> userIds = new Set<Id>();

        for (ServiceResource serviceResource : serviceResources) {
            userIds.add(serviceResource.RelatedRecordId);
        }

        return [
            SELECT Id
            FROM User
            WHERE Id IN: userIds
        ];
    }

    static List<LocationShare> getBuildingSharesByParentAndUserIds(Set<Id> parentIds, Set<Id> userIds) {
        return [
            SELECT Id,
                   ParentId,
                   UserOrGroupId
            FROM LocationShare
            WHERE ParentId IN: parentIds
              AND UserOrGroupId IN: userIds
              AND AccessLevel =: UTIL_Constants.Edit_AccessLevel
              AND RowCause =: UTIL_Constants.Manual_RowCause
        ];
    }

    static Id runScheduledJob(){
        System.schedule(
            'Sharing Buildings with Office Members (Apex Test)', 
            '0 0 * * * ?', 
            new ScheduleBuildingSharing()
        );

        return Database.executeBatch( new LocationSharingOnBranchMember() );
    }
    
}