
FSL.SettingsAPI.setCustomSettings(
    'AppointmentBookingSettings__c', 
    new Map<String, Object> {
		//'DefaultOperatingHours__c' => [ SELECT Id FROM OperatingHours ORDER BY CreatedDate DESC LIMIT 1 ]?.Id,
		//'Minimum_Grade__c' => 0.0,
		//'Show_Grade_Explanation__c' => true,
		//'LazyLoadBookingInHours__c' => 72.0,
		//'Recommended_Threshold__c' => 70.0,
		//'Ideal_Threshold__c' => 90.0,
		//'ShowMoreOptions__c' => true,
		//'AutoTerritoryPicker__c' => false,
		//'ShowGoldenSlots__c' => false,
		'SchedulingPolicyId__c' => [ SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = 'Customer First' ORDER BY CreatedDate DESC LIMIT 1 ]?.Id
    }
);
