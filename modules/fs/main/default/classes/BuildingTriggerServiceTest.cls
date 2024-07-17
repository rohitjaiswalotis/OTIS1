@IsTest
private class BuildingTriggerServiceTest {
    private static final String TIME_STAMP = String.valueOf(Datetime.now().millisecond());

    private static final String TEST_LOCATION_BUILDING_NUMBER = TIME_STAMP;
    private static final String TEST_LOCATION_NAME = 'Theta Building';
    private static final String TEST_LOCATION_TYPE = 'Residential';
    private static final String TEST_LOCATION_BUILDING_NOTES = 'test building notes';
    private static final String TEST_LOCATION_MECHANIC_NOTES = 'test mechanic notes';
    private static final String TEST_LOCATION_PHONE_NUMBER = '1234567890';
    private static final String TEST_LOCATION_PERMANENT_INSTRUCTIONS = 'test permanent instructions';
    private static final String TEST_LOCATION_BUILDING_ADDRESS = 'test building address';
    private static final String TEST_LOCATION_BUILDING_OPERATIONAL_HOURS = 'test operational hours';
    private static final String TEST_LOCATION_TEMPORARY_INSTRUCTIONS = 'temporary special instructions';
    private static final String TEST_LOCATION_TIMEZONE = 'America/Los_Angeles';

    private static final String TEST_ADDRESS_STREET = '1 Elm Street';
    private static final String TEST_ADDRESS_CITY = 'New York';
    private static final String TEST_ADDRESS_STATE = 'New York';
    private static final String TEST_ADDRESS_POSTAL_CODE = TIME_STAMP;
    private static final String TEST_ADDRESS_COUNTRY = 'New Zealand';

    private static final String TEST_BRANCH_NAME = 'Florida';

    
    @TestSetup
    private static void setup() {
        User otisIntegrationUser = UTIL_TestDataFactory.createUser(
            UTIL_Constants.OTIS_SYSTEM_INTEGRATION_PROFILE,
            UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX
        );
        insert otisIntegrationUser;

        insert UTIL_TestDataFactory.createTriggerSettings(new List<SObjectType>{
            Schema.Address.getSObjectType(),
            Schema.Location.getSObjectType(),
            Branch__c.getSObjectType()
        });
    }


    @IsTest
    private static void shouldUpdateTemporarySpecialInstructions() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
			
            setupData.selectLocations();
            for (Schema.Location locationRecord : setupData.TestLocations) {
				Assert.isNull(
					locationRecord.DateTimeLastUpdated__c,
					'Field should be empty after entity creation.'
				);
            }

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.TemporarySpecialInstructions__c,
                    TEST_LOCATION_TEMPORARY_INSTRUCTIONS + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            for (Schema.Location locationRecord : setupData.TestLocations) {
				Assert.isNotNull(
					locationRecord.DateTimeLastUpdated__c,
					'Field should be populated with current timestamp as result of temporary special instructions update.'
				);
            }
        }
    }

    @IsTest
    private static void shouldSetGBOOnInsert() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createParentTestBranches();
            setupData.createChildTestBranches();

            Test.startTest();
            {
                setupData.createTestLocationsWithBranch();
            }
            Test.stopTest();

            setupData.selectLocations();

            for (Schema.Location locationRecord : setupData.TestLocations) {
                Assert.areEqual(locationRecord.BranchName__r.GBO__r.Name, locationRecord.GBO_Name__c);
            }
        }
    }

    @IsTest
    private static void shouldSetGBOOnUpdate() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createParentTestBranches();
            setupData.createChildTestBranches();
            setupData.createTestLocations();

            Test.startTest();
            {
                setupData.updateLocationsField(Schema.Location.BranchName__c, setupData.TestChildBranches[0].Id);
            }
            Test.stopTest();

            setupData.selectLocations();

            for (Schema.Location locationRecord : setupData.TestLocations) {
                Assert.areEqual(locationRecord.BranchName__r.GBO__r.Name, locationRecord.GBO_Name__c);
            }
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnTimeZoneChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(Schema.Location.TimeZone, TEST_LOCATION_TIMEZONE);
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].TimeZone,
                setupData.TestLocationsDifferentBuildingNumber[0].TimeZone
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnNameChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(Schema.Location.Name, TEST_LOCATION_NAME + TIME_STAMP);
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].BuildingNotes__c,
                setupData.TestLocationsDifferentBuildingNumber[0].BuildingNotes__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnBuildingNotesChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.BuildingNotes__c,
                    TEST_LOCATION_BUILDING_NOTES + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].BuildingNotes__c,
                setupData.TestLocationsDifferentBuildingNumber[0].BuildingNotes__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnMechanicNotesChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.MechanicNotes__c,
                    TEST_LOCATION_MECHANIC_NOTES + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].MechanicNotes__c,
                setupData.TestLocationsDifferentBuildingNumber[0].MechanicNotes__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnBuildingDayPhoneNumberChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.BuildingDayPhoneNumber__c,
                    TEST_LOCATION_PHONE_NUMBER + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].BuildingDayPhoneNumber__c,
                setupData.TestLocationsDifferentBuildingNumber[0].BuildingDayPhoneNumber__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnBuilding247PhoneNumberChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.Building247PhoneNumber__c,
                    TEST_LOCATION_PHONE_NUMBER + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].Building247PhoneNumber__c,
                setupData.TestLocationsDifferentBuildingNumber[0].Building247PhoneNumber__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnAlternatePhoneNumber1Change() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.AlternatePhoneNumber1__c,
                    TEST_LOCATION_PHONE_NUMBER + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].AlternatePhoneNumber1__c,
                setupData.TestLocationsDifferentBuildingNumber[0].AlternatePhoneNumber1__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnAlternatePhoneNumber2Change() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.AlternatePhoneNumber2__c,
                    TEST_LOCATION_PHONE_NUMBER + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].AlternatePhoneNumber2__c,
                setupData.TestLocationsDifferentBuildingNumber[0].AlternatePhoneNumber2__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnAlternatePhoneNumber3Change() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.AlternatePhoneNumber3__c,
                    TEST_LOCATION_PHONE_NUMBER + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].AlternatePhoneNumber3__c,
                setupData.TestLocationsDifferentBuildingNumber[0].AlternatePhoneNumber3__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnAlternatePhoneNumber4Change() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.AlternatePhoneNumber4__c,
                    TEST_LOCATION_PHONE_NUMBER + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].AlternatePhoneNumber4__c,
                setupData.TestLocationsDifferentBuildingNumber[0].AlternatePhoneNumber4__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnPermanentSpecialInstructionsChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.PermanentSpecialInstructions__c,
                    TEST_LOCATION_PERMANENT_INSTRUCTIONS + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].PermanentSpecialInstructions__c,
                setupData.TestLocationsDifferentBuildingNumber[0].PermanentSpecialInstructions__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnTemporarySpecialInstructionsChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.TemporarySpecialInstructions__c,
                    TEST_LOCATION_TEMPORARY_INSTRUCTIONS + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].TemporarySpecialInstructions__c,
                setupData.TestLocationsDifferentBuildingNumber[0].TemporarySpecialInstructions__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnSpecialInstructionsExpirationChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.SpecialInstructionsExpiration__c,
                    Date.today().addDays(1)
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].SpecialInstructionsExpiration__c,
                setupData.TestLocationsDifferentBuildingNumber[0].SpecialInstructionsExpiration__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsOnBuildingAddressChange() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.skipLocationTrigger();
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();
            setupData.activateLocationTrigger();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.BuildingAddress__c,
                    TEST_LOCATION_BUILDING_ADDRESS + TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            setupData.fieldSyncAssertion();
            Assert.areNotEqual(
                setupData.TestLocations[0].BuildingOperationalHours__c,
                setupData.TestLocationsDifferentBuildingNumber[0].BuildingOperationalHours__c
            );
        }
    }

    @IsTest
    private static void shouldSyncFieldsWithTwoLocationsUpdated() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations(1);
            setupData.createTestLocationsSameBuildingNumberDiffField();
            setupData.createTestLocationsSameBuildingNumber(1);
            setupData.createTestLocationsDifferentBuildingNumber(1);

            Test.startTest();
            {
                setupData.TestLocationSameBuildingNumberDiffField.BuildingNotes__c = null;
                setupData.TestLocations[0].BuildingNotes__c = TEST_LOCATION_BUILDING_NOTES + TIME_STAMP;
                update new List<Schema.Location>{setupData.TestLocationSameBuildingNumberDiffField, setupData.TestLocations[0]};

            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsSameBuildingNumberDiffField();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            Assert.isTrue(setupData.TestLocationsSameBuildingNumber[0].BuildingNotes__c != null);
            Assert.isTrue(setupData.TestLocationsSameBuildingNumber[0].MechanicNotes__c != null);
            Assert.areEqual(setupData.TestLocations[0].BuildingNotes__c, setupData.TestLocationsSameBuildingNumber[0].BuildingNotes__c);
            Assert.areEqual(setupData.TestLocations[0].MechanicNotes__c, setupData.TestLocationsSameBuildingNumber[0].MechanicNotes__c);
            Assert.areNotEqual(
                setupData.TestLocations[0].BuildingOperationalHours__c,
                setupData.TestLocationsDifferentBuildingNumber[0].BuildingOperationalHours__c
            );
        }
    }

    @IsTest
    private static void shouldUpdateVisitorAddressId() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestAddresses();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.VisitorAddressId,
                    setupData.TestAddresses
                );
            }
            Test.stopTest();

            setupData.selectLocations();

            Assert.areEqual(setupData.getExpectedBuildingAddressValue(), setupData.TestLocations[0].BuildingAddress__c);
        }
    }

    @IsTest
    private static void shouldUpdateVisitorAddressIdToNull() {

        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.skipLocationTrigger();
            setupData.createTestLocations();
            setupData.createTestAddresses();
            setupData.updateLocationsField(
                Schema.Location.VisitorAddressId,
                setupData.TestAddresses
            );
            setupData.activateLocationTrigger();

            Test.startTest();
            {
                setupData.updateLocationsField(Schema.Location.VisitorAddressId, (String) null);
            }
            Test.stopTest();

            setupData.selectLocations();

            Assert.isTrue(String.isEmpty(setupData.TestLocations[0].VisitorAddressId));
            Assert.isTrue(String.isBlank(setupData.TestLocations[0].BuildingAddress__c));
        }
    }

    @IsTest
    private static void shouldNotSyncFields() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();
            setupData.createTestLocationsSameBuildingNumber();
            setupData.createTestLocationsDifferentBuildingNumber();

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.Description,
                    TIME_STAMP
                );
            }
            Test.stopTest();

            setupData.selectLocations();
            setupData.selectAdditionalLocationsSameBuildingNumber();
            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            Assert.areNotEqual(
                setupData.TestLocations[0].SpecialInstructionsExpiration__c,
                setupData.TestLocationsSameBuildingNumber[0].SpecialInstructionsExpiration__c,
                'Should not match, because there is no logic for description field check'
            );
            Assert.areNotEqual(
                setupData.TestLocations[0].SpecialInstructionsExpiration__c,
                setupData.TestLocationsDifferentBuildingNumber[0].SpecialInstructionsExpiration__c,
                'Should not match, because there is no logic for description field check'
            );
        }
    }

    @IsTest
    private static void shouldUpdateTemporarySpecialInstructionsWithNull() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {
            setupData.createTestLocations();

            setupData.selectLocations();
			Assert.isNull(
				setupData.TestLocations[0].DateTimeLastUpdated__c,
				'Field should be empty after entity creation.'
			);

            Test.startTest();
            {
                setupData.updateLocationsField(
                    Schema.Location.TemporarySpecialInstructions__c,
                    (String) null
                );
            }
            Test.stopTest();

            setupData.selectLocations();
			Assert.isNotNull(
				setupData.TestLocations[0].DateTimeLastUpdated__c,
				'Field should be populated with current timestamp as result of temporary special instructions update.'
			);

        }
    }

    @IsTest
    private static void shouldSetGBOOnUpdateWithNull() {
        SetupDataClass setupData = new SetupDataClass();
        setupData.createParentTestBranches();
        setupData.createChildTestBranches();
        setupData.createTestLocations();

        System.runAs(setupData.TestUser) {

            Test.startTest();
            {
                setupData.updateLocationsField(Schema.Location.BranchName__c, (String) null);
            }
            Test.stopTest();

            setupData.selectLocations();

            Assert.areEqual(
                null,
                setupData.TestLocations[0].GBO_Name__c,
                'Location did not have branch id, so GBO_Name__c should be null'
            );
        }
    }

    @IsTest
    private static void shouldSetTimeZoneOnInsert() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {

            Test.startTest();
            {
                setupData.createTestLocationsDifferentBuildingNumber();
            }
            Test.stopTest();

            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            for (Schema.Location locationRecord : setupData.TestLocationsDifferentBuildingNumber) {
                Assert.areEqual(locationRecord.TimeZone__c, 'America/New_York');
            }
        }
    }

    @IsTest
    private static void shouldSetTimeZoneOnUpdate() {
        SetupDataClass setupData = new SetupDataClass();

        System.runAs(setupData.TestUser) {

            Test.startTest();
            {
                setupData.createTestLocationsDifferentBuildingNumber();
                for (Schema.Location location : setupData.TestLocationsDifferentBuildingNumber) {
                    location.TimeZone = 'America/Montreal';
                }
                update setupData.TestLocationsDifferentBuildingNumber;
            }
            Test.stopTest();

            setupData.selectAdditionalLocationsDifferentBuildingNumber();

            for (Schema.Location locationRecord : setupData.TestLocationsDifferentBuildingNumber) {
                Assert.areEqual(locationRecord.TimeZone__c, 'America/Montreal');
            }
        }
    }


    private class SetupDataClass {
        public User TestUser;
        public List<Schema.Address> TestAddresses;
        public List<Schema.Location> TestLocations;
        public List<Schema.Location> TestLocationsSameBuildingNumber;
        public List<Schema.Location> TestLocationsDifferentBuildingNumber;
        public Schema.Location TestLocationSameBuildingNumberDiffField;
        public List<Branch__c> TestParentBranches;
        public List<Branch__c> TestChildBranches;

        public SetupDataClass() {
            TestAddresses = new List<Schema.Address>();
            TestLocations = new List<Schema.Location>();
            TestLocationsSameBuildingNumber = new List<Schema.Location>();
            TestLocationsDifferentBuildingNumber = new List<Schema.Location>();
            TestParentBranches = new List<Branch__c>();
            TestChildBranches = new List<Branch__c>();
            TestUser = UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX);
        }

        public void createTestLocations() {
            createTestLocations(200);
        }
        public void createTestLocations(Integer locationAmount) {
            for (Integer i = 0; i < locationAmount; i++) {
                Schema.Location locationRecord = UTIL_TestDataFactory.createLocation(TEST_LOCATION_NAME + i, TEST_LOCATION_TYPE);
                locationRecord.BuildingNotes__c = TEST_LOCATION_BUILDING_NOTES;
                locationRecord.MechanicNotes__c = TEST_LOCATION_MECHANIC_NOTES;
                locationRecord.BuildingDayPhoneNumber__c = TEST_LOCATION_PHONE_NUMBER;
                locationRecord.Building247PhoneNumber__c = TEST_LOCATION_PHONE_NUMBER;
                locationRecord.AlternatePhoneNumber1__c = TEST_LOCATION_PHONE_NUMBER;
                locationRecord.AlternatePhoneNumber2__c = TEST_LOCATION_PHONE_NUMBER;
                locationRecord.AlternatePhoneNumber3__c = TEST_LOCATION_PHONE_NUMBER;
                locationRecord.AlternatePhoneNumber4__c = TEST_LOCATION_PHONE_NUMBER;
                locationRecord.PermanentSpecialInstructions__c = TEST_LOCATION_PERMANENT_INSTRUCTIONS;
                locationRecord.TemporarySpecialInstructions__c = TEST_LOCATION_TEMPORARY_INSTRUCTIONS;
                locationRecord.SpecialInstructionsExpiration__c = Date.today();
                locationRecord.BuildingAddress__c = TEST_LOCATION_BUILDING_ADDRESS;
                locationRecord.BuildingOperationalHours__c = TEST_LOCATION_BUILDING_OPERATIONAL_HOURS;
                locationRecord.BuildingNumber__c = TEST_LOCATION_BUILDING_NUMBER;

                TestLocations.add(locationRecord);
            }

            insert TestLocations;
        }

        public void createTestLocationsSameBuildingNumber() {
            createTestLocationsSameBuildingNumber(200);
        }

        public void createTestLocationsSameBuildingNumber(Integer locationAmount) {
            for (Integer i = 0; i < locationAmount; i++) {
                Schema.Location locationRecord = UTIL_TestDataFactory.createLocation(TEST_LOCATION_NAME + i, TEST_LOCATION_TYPE);
                locationRecord.BuildingNumber__c = TEST_LOCATION_BUILDING_NUMBER;

                TestLocationsSameBuildingNumber.add(locationRecord);
            }

            insert TestLocationsSameBuildingNumber;
        }

        public void createTestLocationsDifferentBuildingNumber() {
            createTestLocationsDifferentBuildingNumber(200);
        }

        public void createTestLocationsDifferentBuildingNumber(Integer locationAmount) {
            for (Integer i = 0; i < locationAmount; i++) {
                Schema.Location locationRecord = UTIL_TestDataFactory.createLocation(TEST_LOCATION_NAME + i, TEST_LOCATION_TYPE);
                locationRecord.BuildingNumber__c = TEST_LOCATION_BUILDING_NUMBER + TIME_STAMP;

                TestLocationsDifferentBuildingNumber.add(locationRecord);
            }

            insert TestLocationsDifferentBuildingNumber;
        }

        public void createTestLocationsSameBuildingNumberDiffField() {
            TestLocationSameBuildingNumberDiffField = UTIL_TestDataFactory.createLocation(TEST_LOCATION_NAME, TEST_LOCATION_TYPE);
            TestLocationSameBuildingNumberDiffField.BuildingNumber__c = TIME_STAMP;
            TestLocationSameBuildingNumberDiffField.MechanicNotes__c = null;

            insert TestLocationSameBuildingNumberDiffField;
        }

        public void createTestLocationsWithBranch() {
            for (Integer i = 0; i < 200; i++) {
                Schema.Location locationRecord = UTIL_TestDataFactory.createLocation(TEST_LOCATION_NAME + i, TEST_LOCATION_TYPE);
                locationRecord.BranchName__c = TestChildBranches[i].Id;

                TestLocations.add(locationRecord);
            }

            insert TestLocations;
        }

        public void createTestAddresses() {
            for (Integer i = 0; i < 200; i++) {
                Schema.Address addressRecord = new Schema.Address(
                    Street = TEST_ADDRESS_STREET,
                    City = TEST_ADDRESS_CITY,
                    State = TEST_ADDRESS_STATE,
                    PostalCode = TEST_ADDRESS_POSTAL_CODE,
                    Country = TEST_ADDRESS_COUNTRY,
                    ParentId = TestLocations[i].Id
                );

                TestAddresses.add(addressRecord);
            }

            insert TestAddresses;
        }

        public void createParentTestBranches() {
            for (Integer i = 0; i < 200; i++) {
                Branch__c branch = UTIL_TestDataFactory.createBranch(
                    TEST_BRANCH_NAME + TIME_STAMP,
                    UTIL_Constants.OFFICE_TYPE_GBO,
                    null
                );

                TestParentBranches.add(branch);
            }

            insert TestParentBranches;
        }

        public void createChildTestBranches() {
            for (Integer i = 0; i < 200; i++) {
                Branch__c branch = UTIL_TestDataFactory.createBranch(
                    TEST_BRANCH_NAME,
                    UTIL_Constants.OFFICE_TYPE_GBO,
                    TestParentBranches[i].Id
                );

                TestChildBranches.add(branch);
            }

            insert TestChildBranches;
        }

        public void updateLocationsField(SObjectField field, String value) {
            for(Schema.Location locationRecord : TestLocations) {
                locationRecord.put(field, value);
            }

            update TestLocations;
        }

        public void updateLocationsField(SObjectField field, List<Schema.Address> testAddresses) {
            for(Schema.Location locationRecord : TestLocations) {
                locationRecord.put(field, testAddresses[TestLocations.indexOf(locationRecord)].Id);
            }

            update TestLocations;
        }

        public void updateLocationsField(SObjectField field, Date value) {
            for(Schema.Location locationRecord : TestLocations) {
                locationRecord.put(field, value);
            }

            update TestLocations;
        }

        public void selectLocations() {
            TestLocations = queryLocation(TestLocations);
        }

        public void selectAdditionalLocationsSameBuildingNumber() {
            TestLocationsSameBuildingNumber = queryLocation(TestLocationsSameBuildingNumber);
        }

        public void selectAdditionalLocationsDifferentBuildingNumber() {
            TestLocationsDifferentBuildingNumber = queryLocation(TestLocationsDifferentBuildingNumber);
        }

        public void selectAdditionalLocationsSameBuildingNumberDiffField() {
            TestLocationSameBuildingNumberDiffField = queryLocation(new List<Schema.Location>{TestLocationSameBuildingNumberDiffField})[0];
        }

        public void fieldSyncAssertion() {
            Schema.Location locationRecord = TestLocations[0];
            Schema.Location locationSameBuildingNumber = TestLocationsSameBuildingNumber[0];
            Assert.areEqual(locationRecord.TimeZone, locationSameBuildingNumber.TimeZone);
            Assert.areEqual(locationRecord.TemporarySpecialInstructions__c, locationSameBuildingNumber.TemporarySpecialInstructions__c);
            Assert.areEqual(locationRecord.SpecialInstructionsExpiration__c, locationSameBuildingNumber.SpecialInstructionsExpiration__c);
            Assert.areEqual(locationRecord.PermanentSpecialInstructions__c, locationSameBuildingNumber.PermanentSpecialInstructions__c);
            Assert.areEqual(locationRecord.MechanicNotes__c, locationSameBuildingNumber.MechanicNotes__c);
            Assert.areEqual(locationRecord.BuildingOperationalHours__c, locationSameBuildingNumber.BuildingOperationalHours__c);
            Assert.areEqual(locationRecord.BuildingNotes__c, locationSameBuildingNumber.BuildingNotes__c);
            Assert.areEqual(locationRecord.BuildingDayPhoneNumber__c, locationSameBuildingNumber.BuildingDayPhoneNumber__c);
            Assert.areEqual(locationRecord.Building247PhoneNumber__c, locationSameBuildingNumber.Building247PhoneNumber__c);
            Assert.areEqual(locationRecord.AlternatePhoneNumber1__c, locationSameBuildingNumber.AlternatePhoneNumber1__c);
            Assert.areEqual(locationRecord.AlternatePhoneNumber2__c, locationSameBuildingNumber.AlternatePhoneNumber2__c);
            Assert.areEqual(locationRecord.AlternatePhoneNumber3__c, locationSameBuildingNumber.AlternatePhoneNumber3__c);
            Assert.areEqual(locationRecord.AlternatePhoneNumber4__c, locationSameBuildingNumber.AlternatePhoneNumber4__c);
        }

        private List<Schema.Location> queryLocation(List<Schema.Location> locations) {
            Set<Id> locationIds = new Map<Id, SObject>(locations).keySet();
            return [
                SELECT
                    Name,
                    TimeZone,
                    TimeZone__c,
                    BuildingNotes__c,
                    MechanicNotes__c,
                    BuildingDayPhoneNumber__c,
                    Building247PhoneNumber__c,
                    AlternatePhoneNumber1__c,
                    AlternatePhoneNumber2__c,
                    AlternatePhoneNumber3__c,
                    AlternatePhoneNumber4__c,
                    PermanentSpecialInstructions__c,
                    TemporarySpecialInstructions__c,
                    SpecialInstructionsExpiration__c,
                    BuildingAddress__c,
                    BuildingNumber__c,
                    BranchName__r.GBO__r.Name,
                    GBO_Name__c,
                    DateTimeLastUpdated__c,
                    BuildingOperationalHours__c,
                    VisitorAddressId
                FROM Location
                WHERE Id IN :locationIds
            ];
        }

        public String getExpectedBuildingAddressValue() {
            Schema.Address addressRecord = TestAddresses[0];

            return String.format(
                '{0},{1},{2},{3}',
                new List<String> {
                    addressRecord.Street != null ? addressRecord.Street : '',
                    addressRecord.City != null ? addressRecord.City : '',
                    addressRecord.State != null ? addressRecord.State : '',
                    addressRecord.PostalCode != null ? addressRecord.PostalCode : ''
                }
            );
        }

        public void skipLocationTrigger() {
            CS_TriggerSettings__c triggerSettings = CS_TriggerSettings__c.getValues('Location');
            triggerSettings.IsActive__c = false;
            update triggerSettings;
        }

        public void activateLocationTrigger() {
            CS_TriggerSettings__c triggerSettings = CS_TriggerSettings__c.getValues('Location');
            triggerSettings.IsActive__c = true;
            update triggerSettings;
        }
    }
}