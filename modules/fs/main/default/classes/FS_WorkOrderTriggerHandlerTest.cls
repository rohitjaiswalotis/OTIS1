@IsTest
private class FS_WorkOrderTriggerHandlerTest {

    @TestSetup
    static void setupData() {
		
		// create integration user
        User integrationUser = UTIL_TestDataFactory.createUser(
            UTIL_Constants.OTIS_SYSTEM_INTEGRATION_PROFILE,
            UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX
        );
		
		insert integrationUser;
		
		
		// assign required permission set groups (using runAs for current user to avoid mixed dml error)
		System.runAs(new User(Id = UserInfo.getUserId())) {
			
			UTIL_TestDataFactory.assignPermissionSetGroups(
				integrationUser.Id,
				new Set<String> {
					'OtisSystemIntegration_Persona',
					'FS_OtisSystemIntegration_Persona'
				}
			);
			
		}


        insert UTIL_TestDataFactory.createTriggerSettings(
            new List<String>{'WorkOrder'}
        );

        insert new Otis_Settings__c(Schedule_Job_User__c = UserInfo.getUserId());

        Branch__c branchToInsert = UTIL_TestDataFactory.createBranch(null, null, null);
        branchToInsert.FSLEnabled__c = false;
        insert branchToInsert;

        Asset assetToInsert = UTIL_TestDataFactory.createAsset('Test', null,  branchToInsert.Id);
        insert assetToInsert;

        Case caseToInsert = UTIL_TestDataFactory.createCase(null, null);
        insert caseToInsert;
    }


    @IsTest
    static void shouldWorkOrderBeInsertedSuccessfully() {

        Boolean hasException = false;

        Asset testAsset = [SELECT LocationId FROM Asset];
        Case testCase = [SELECT Id FROM Case];

        Id recordTypeId = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE
        ).getRecordTypeId();

        WorkOrder workOrderToInsert = UTIL_TestDataFactory.createWorkOrder(
            null, null, null, testAsset.Id, null, null, null, recordTypeId
        );
        workOrderToInsert.LocationId = testAsset.LocationId;
        workOrderToInsert.CaseId = testCase.Id;

        System.runAs(
            UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX)
        ) {
			
            Test.startTest();
				
                try {
                    insert workOrderToInsert;
                } catch (Exception e) {
                    hasException = true;
                }
				
            Test.stopTest();
			
        }
		
		
        Assert.areEqual(
            false,
            hasException,
            'Work Order record should be successfully inserted. Trigger should not process "Classic_CC" work orders.'
        );
		
		
    }


    @IsTest
    static void shouldWorkOrderBeUpdatedSuccessfully() {

        Boolean hasException = false;

        Asset testAsset = [SELECT LocationId FROM Asset];
        Case testCase = [SELECT Id FROM Case];

        Id recordTypeId = RecordTypeUtilities.getRecordTypeInfo(
            WorkOrder.SObjectType,
            UTIL_Constants.WORK_ORDER_CLASSIC_RECORD_TYPE
        ).getRecordTypeId();

        WorkOrder workOrderToInsert = UTIL_TestDataFactory.createWorkOrder(
            null, null, null, testAsset.Id, null, null, null, recordTypeId
        );
        workOrderToInsert.LocationId = testAsset.LocationId;
        workOrderToInsert.CaseId = testCase.Id;

        insert workOrderToInsert;

        System.runAs(
            UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX)
        ) {
			
            Test.startTest();
				
                try {
                    update workOrderToInsert;
                } catch (Exception e) {
                    hasException = true;
                }
				
            Test.stopTest();
			
        }
		
		
        Assert.areEqual(
            false,
            hasException,
            'Work Order record should be successfully updated. Trigger should not process "Classic_CC" work orders.'
        );
		
    }
	
}