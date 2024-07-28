
FSL.SettingsAPI.setCustomSettings(
	'Trigger_Configurations__c', 
	new Map<String, Object> {
		//'Service Type Derive Due Date' => true,
		//'Status Actions' => false,
		//'Change Status To Scheduled' => true,
		//'User Locations' => true,
		'Travel Time' => true,
		'Location Based Sharing' => true,
		//'Cancelled Service Not Scheduled' => true,
		//'Pinned Service Not Changed' => true,
		//'Service Duration Longer Than Minute' => true,
		//'Service Derive Label From Account' => true,
		//'Mention user on service dispatch' => true,
		//'Wait for clean state' => true,
		'Enable workorder parent sharing' => true,
		'Enable account parent sharing' => false,
		'Enable opportunity parent sharing' => false,
		'Enable asset parent sharing' => false,
		'Enable Dynamic Gantt Fix Overlaps' => false,
		//'Enable Service Auto Classification' => true,
		//'Enable Territory Name Duplicates' => false,
		'Allow follow' => false,
		//'Work Capacity Triggers' => false,
		//'Edit Sharing For Crew Members' => false,
		//'Update AR when service is reassigned' => true,
		//'Update AR when service is dispatched' => true,
		//'Enable req overlaps prevention' => true,
		//'Enable sharing for Optimization' => false,
		'Enable optimization failure' => true
	}
);

