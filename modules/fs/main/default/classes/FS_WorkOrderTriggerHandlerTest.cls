@IsTest
private class FS_WorkOrderTriggerHandlerTest {

    @TestSetup
    static void setupData() {

        insert UTIL_TestDataFactory.createUser(
            UTIL_Constants.OTIS_SYSTEM_INTEGRATION_PROFILE,
            UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX
        );

        List<CS_TriggerSettings__c> csTriggerSettings = UTIL_TestDataFactory.createTriggerSettings(
            new List<String>{'WorkOrder'}
        );
        insert csTriggerSettings;
    }

    @IsTest
    static void shouldWorkOrderBeInsertedSuccessfully() {

        Boolean hasException = false;

        Branch__c branchToInsert = UTIL_TestDataFactory.createBranch(null, null, null);
        branchToInsert.FSLEnabled__c = false;
        insert branchToInsert;

        Asset assetToInsert = UTIL_TestDataFactory.createAsset('Test', null,  branchToInsert.Id);
        insert assetToInsert;

        Case caseToInsert = UTIL_TestDataFactory.createCase(null, null);
        insert caseToInsert;

        WorkOrder workOrderToInsert = UTIL_TestDataFactory.createWorkOrder(null, null, assetToInsert);
        workOrderToInsert.CaseId = caseToInsert.Id;

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
            'Work Order record should be successfully inserted.'
        );
    }
}