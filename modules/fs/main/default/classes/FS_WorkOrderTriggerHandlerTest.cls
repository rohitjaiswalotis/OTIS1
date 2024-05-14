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

        Map<String, Object> branchFieldsMap = new Map<String, Object> {'FSLEnabled__c' => false};
        Branch__c createdBranch = UTIL_TestDataFactory.createBranch(branchFieldsMap, true);

        Map<String, Object> assetFieldsMap = new Map<String, Object> {
            'Name' => 'Test',
            'Branch__c' => createdBranch.Id
        };
        Asset createdAsset = UTIL_TestDataFactory.createAsset(assetFieldsMap, true);

        Map<String, Object> caseFieldsMap = new Map<String, Object> {};
        Case createdCase = UTIL_TestDataFactory.createCase(caseFieldsMap, true);

        Map<String, Object> workOrderFieldsMap = new Map<String, Object> {
            'CaseId' => createdCase.Id,
            'AssetId' => createdAsset.Id
        };

        System.runAs(
            UTIL_TestDataFactory.getUserByEmailPostfix(UTIL_TestDataFactory.OTIS_INTEGRATION_USER_EMAIL_POSTFIX)
        ) {
            Test.startTest();
                try {
                    UTIL_TestDataFactory.createWorkOrder(workOrderFieldsMap, true);
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