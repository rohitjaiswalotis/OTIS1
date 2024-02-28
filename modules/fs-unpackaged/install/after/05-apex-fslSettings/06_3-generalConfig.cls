
FSL.SettingsAPI.setCustomSettings(
    'General_Config__c', 
    new Map<String, Object> {
        'Bundle Live Debug Logs' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => false
        },
        'Fsl Cache' => new Map<String, Object> {
            'Value__c' => 1,
            'Run__c' => true
        },
        'Fsl Cache partition name' => new Map<String, Object> {
            'Value__c' => 'FSLPartition',
            'Run__c' => true
        },
        'FSL Overlap Detection Number Of Days' => new Map<String, Object> {
            'Value__c' => 7,
            'Run__c' => true
        },
        'FSL Overlap Detection Batch Size' => new Map<String, Object> {
            'Value__c' => 10,
            'Run__c' => true
        },
        'Bundle Client Debug' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => false
        },
        'Disable Contractor Trigger Calculation' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => false
        },
        'Use Sliding With Dynamic Skills' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Max Number Of Skills With Sliding' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Max Number Of Extended With Sliding' => new Map<String, Object> {
            'Value__c' => 0,
            'Run__c' => true
        },
        'Capacity Limit Allow Relaxation List' => new Map<String, Object> {
            'Value__c' => 'No relaxation',
            'Run__c' => true
        }
    }
);

