
FSL.SettingsAPI.setCustomSettings(
    'General_Config__c', 
    new Map<String, Object> {
        'Map available on gantt' => new Map<String, Object> {
        	'Value__c' => 1,
            'Run__c' => true
        },
        'Max horizon for Resource request' => new Map<String, Object> {
        	'Value__c' => 30,
            'Run__c' => true
        },
		'Status Transitions Policy' => new Map<String, Object> {
            'Run__c' => true
        },
        'Gantt Default Policy' => new Map<String, Object> {
        	'Value__c' => [ SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = 'Customer First' ORDER BY CreatedDate DESC LIMIT 1 ]?.Id,
            'Run__c' => true
        },
		'Map available on gantt' => new Map<String, Object> {
            'Value__c' => 1,
            'Run__c' => true
        },
        'Always show local time in tooltip' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Show SLR in resource map' => new Map<String, Object> {
            'Value__c' => 1,
            'Run__c' => true
        },
        'Show daily utilization in daily view' => new Map<String, Object> {
            'Value__c' => 1,
            'Run__c' => true
        },
        'Show secondary STMs on gantt' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'rule validation after delta' => new Map<String, Object> {
            'Value__c' => 1,
            'Run__c' => true
        },
        'rule validation frequency level' => new Map<String, Object> {
            'Value__c' => 'Always',
            'Run__c' => true
        },
        'Timezone display mode' => new Map<String, Object> {
            'Value__c' => 'user',
            'Run__c' => true
        },
        'Total allowed seconds of inactivity' => new Map<String, Object> {
            'Value__c' => 7200,
            'Run__c' => true
        },
        'Delta Will Run Every' => new Map<String, Object> {
            'Value__c' => 10,
            'Run__c' => true
        }
    }
);

