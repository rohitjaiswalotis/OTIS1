
FSL.SettingsAPI.setCustomSettings(
    'General_Config__c', 
    new Map<String, Object> {
        'Enable Crew Pilot' => false,
        'Max territories to display on UI' => 2000,
        'Enable Scheduling Bundling' => false,
        'Enable Map Routes' => false,
        'Enable Optimization Environment' => false,
        'Use Bundle Apex Mode' => 2,
        'Bundler Falcon Environment' => 1,
        'Bundler Falcon Environment Default' => 0,
        'Capacity Limit Environment' => 8,
        'Capacity Limit Environment Default' => 0,
        'Bundle Live Wait Time' => 600,
        'Enable Live Bundling' => false,
        'Live Bundling Debug' => false
    }
);

