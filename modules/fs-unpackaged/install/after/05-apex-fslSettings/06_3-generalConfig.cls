
FSL.SettingsAPI.setCustomSettings(
    'General_Config__c', 
    new Map<String, Object> {
        'Bundle Live Debug Logs' => false,
        'Fsl Cache' => true,
        'Fsl Cache partition name' => 'FSLPartition',
        'FSL Overlap Detection Number Of Days' => 7,
        'FSL Overlap Detection Batch Size' => 10,
        'Bundle Client Debug' => false,
        'Disable Contractor Trigger Calculation' => false,
        'Use Sliding With Dynamic Skills' => false,
        'Max Number Of Skills With Sliding' => false,
        'Max Number Of Extended With Sliding' => false,
        'Capacity Limit Allow Relaxation List' => 'No relaxation'
    }
);

