LocalizationSettings__c settings = LocalizationSettings__c.getOrgDefaults();

settings.Domain__c = '${SF_SR_VAR_GLOBAL_LOCALIZATION_DOMAIN}';

upsert settings;
