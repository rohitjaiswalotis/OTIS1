
FSL.SettingsAPI.setCustomSettings(
    'OptimizationSettings__c', 
    'RDO Settings',
    new Map<String, Object> {
		'Max_Runtime_Single_Service__c' =>  1.0,
		'Pinned_Statuses__c' => 'Enroute,Onsite,Canceled,Cannot Complete,Completed'
    }
);

FSL.SettingsAPI.setCustomSettings(
    'OptimizationSettings__c', 
    'BGO Settings',
    new Map<String, Object> {
		'Max_Runtime_Single_Service__c' =>  3.0,
		'Pinned_Statuses__c' =>  'Enroute,Onsite,Canceled,Cannot Complete,Completed'
    }
);

FSL.SettingsAPI.setCustomSettings(
    'OptimizationSettings__c', 
    'Reshuffle Settings',
    new Map<String, Object> {
		'Max_Runtime_Single_Service__c' =>  1.0,
		'Pinned_Statuses__c' =>  'Dispatched,In Progress,Completed,Cannot Complete,Canceled'
    }
);

FSL.SettingsAPI.setCustomSettings(
    'OptimizationSettings__c', 
    'In Day Settings',
    new Map<String, Object> {
		'Max_Runtime_Single_Service__c' =>  0.1,
		'Pinned_Statuses__c' =>  'Enroute,Onsite,Canceled,Cannot Complete,Completed'
    }
);

