
FSL.SettingsAPI.setCustomSettings(
    'General_Config__c', 
    new Map<String, Object> {
        'Map available on gantt' => true,
        'Max horizon for Resource request' => 30,
		'Status Transitions Policy' => true,
        'Gantt Default Policy' => [ SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = 'Customer First' ORDER BY CreatedDate DESC LIMIT 1 ]?.Id,
		'Map available on gantt' => true,
        'Always show local time in tooltip' => false,
        'Show SLR in resource map' => true,
        'Show daily utilization in daily view' => true,
        'Show secondary STMs on gantt' => false,
        'rule validation after delta' => true,
        'rule validation frequency level' => 'Always',
        'Timezone display mode' => 'user',
        'Total allowed seconds of inactivity' => 7200,
        'Delta Will Run Every' => 10
    }
);

