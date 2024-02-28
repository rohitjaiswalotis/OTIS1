
FSL.SettingsAPI.setCustomSettings(
    'General_Config__c', 
    new Map<String, Object> {
        'Enable Crew Pilot' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Max territories to display on UI' => new Map<String, Object> {
            'Value__c' => 2000,
            'Run__c' => true
        },
        'Enable Scheduling Bundling' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => false
        },
        'Enable Map Routes' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Enable Optimization Environment' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Use Bundle Apex Mode' => new Map<String, Object> {
            'Value__c' => 2,
            'Run__c' => false
        },
        'Bundler Falcon Environment' => new Map<String, Object> {
            'Value__c' => 1,
            'Run__c' => false
        },
        'Bundler Falcon Environment Default' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => false
        },
        'Capacity Limit Environment' => new Map<String, Object> {
            'Value__c' => 8,
            'Run__c' => true
        },
        'Capacity Limit Environment Default' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Bundle Live Wait Time' => new Map<String, Object> {
            'Value__c' => 600,
            'Run__c' => false
        },
        'Enable Live Bundling' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Live Bundling Debug' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        }
    }
);

