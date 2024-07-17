public with sharing class BuildingTriggerService {
    private static final Set<String> LOCATION_FIELDS_TO_CHECK = new Set<String>();
    private static final Set<String> LOCATION_FIELDS_TO_UPDATE = new Set<String>();

    static {
        String forCheck = 'check';
        String forUpdate = 'update';
        Map<SObjectField, String> locationFieldsToActionMap = new Map<SObjectField, String> {
            Schema.Location.Name => forCheck ,
            Schema.Location.BuildingAddress__c => forCheck ,
            Schema.Location.BuildingOperationalHours__c => forUpdate,
            Schema.Location.BuildingNotes__c => forCheck + forUpdate ,
            Schema.Location.MechanicNotes__c => forCheck + forUpdate ,
            Schema.Location.BuildingDayPhoneNumber__c => forCheck + forUpdate ,
            Schema.Location.Building247PhoneNumber__c => forCheck + forUpdate ,
            Schema.Location.AlternatePhoneNumber1__c => forCheck + forUpdate ,
            Schema.Location.AlternatePhoneNumber2__c => forCheck + forUpdate ,
            Schema.Location.AlternatePhoneNumber3__c => forCheck + forUpdate ,
            Schema.Location.AlternatePhoneNumber4__c => forCheck + forUpdate ,
            Schema.Location.PermanentSpecialInstructions__c => forCheck + forUpdate ,
            Schema.Location.TemporarySpecialInstructions__c => forCheck + forUpdate ,
            Schema.Location.SpecialInstructionsExpiration__c => forCheck + forUpdate ,
            Schema.Location.TimeZone => forCheck + forUpdate
        };

        for(SObjectField field : locationFieldsToActionMap.keySet()) {
            String fieldApiName = field.getDescribe().getName();
            if (locationFieldsToActionMap.get(field).contains(forCheck)) {
                LOCATION_FIELDS_TO_CHECK.add(fieldApiName);
            }
            if (locationFieldsToActionMap.get(field).contains(forUpdate)) {
                LOCATION_FIELDS_TO_UPDATE.add(fieldApiName);
            }

        }
    }

    public static void setBuildingAddressField(List<Schema.Location> locationList) {
        Set<Id> addressIds = createAddressIdsSet(locationList);
        Map<Id, Schema.Address> addressToIdMap = selectRelatedAddress(addressIds);

        for (Schema.Location locationRecord  : locationList) {
            if (locationRecord.VisitorAddressId == null) {
                locationRecord.BuildingAddress__c = '';
            } else {
                locationRecord.BuildingAddress__c = createCompoundAddress(addressToIdMap.get(locationRecord.VisitorAddressId));
            }
        }
    }

    public static void setDateLastUpdatedField(List<Schema.Location> locationList, Map<Id, Schema.Location> locationToIdMap) {
        for (Schema.Location locationRecord : locationList) {
            if (locationRecord.TemporarySpecialInstructions__c != locationToIdMap.get(locationRecord.Id).TemporarySpecialInstructions__c) {
                locationRecord.DateTimeLastUpdated__c = Datetime.now();
            }
        }
    }

    public static void setGBONameField(List<Schema.Location> locationList, Map<Id, Schema.Location> locationToIdMap) {
        List<Schema.Location> updatedLocations = new List<Schema.Location>();

        for (Schema.Location locationRecord : locationList) {
            if (locationRecord.BranchName__c != locationToIdMap.get(locationRecord.Id).BranchName__c) {
                updatedLocations.add(locationRecord);
            }
        }

        setGBONameField(updatedLocations);
    }

    public static void setGBONameField(List<Schema.Location> locationList) {
        Set<Id> relatedBranchIds = createBranchIdsSet(locationList);
        Map<Id, Branch__c> branchesToIds = selectRelatedBranches(relatedBranchIds);

        for (Schema.Location locationRecord : locationList) {
            String assignedBranchGBOName = branchesToIds.get(locationRecord.BranchName__c)?.GBO__r.Name;

            if ((Trigger.isInsert && !String.isBlank(assignedBranchGBOName)) || Trigger.isUpdate) {
                locationRecord.GBO_Name__c = assignedBranchGBOName;
            }
        }
    }

    public static void syncBuildingsWithSameBuildingNumber(List<Schema.Location> locationList, Map<Id, Schema.Location> locationToIdMap) {
        Map<String, Schema.Location> locationToBuildingNumberMap = new Map<String, Schema.Location>();

        for (Schema.Location locationRecord : locationList) {
            if (areLocationFieldsChanged(locationRecord, locationToIdMap.get(locationRecord.Id))) {
                locationToBuildingNumberMap.put(locationRecord.BuildingNumber__c, locationRecord);
            }
        }

        List<Schema.Location> relatedLocations = selectRelatedLocations(locationToBuildingNumberMap.keySet(), locationToIdMap.keySet());

        for (Schema.Location locationRecord : relatedLocations) {
            updateRelatedLocationsFields(locationRecord, locationToBuildingNumberMap.get(locationRecord.BuildingNumber__c));
        }

        update relatedLocations;
    }

    public static void setTimeZoneField(List<Schema.Location> locationList, Map<Id, Schema.Location> locationToIdMap) {
        for (Schema.Location locationRecord : locationList) {
            if (locationToIdMap == null || locationRecord.TimeZone != locationToIdMap.get(locationRecord.Id).TimeZone) {
                locationRecord.TimeZone__c = locationRecord.TimeZone;
            }
        }
    }

    private static Set<Id> createAddressIdsSet(List<Schema.Location> locationList) {
        Set<Id> addressIds = new Set<Id>();

        for (Schema.Location locationRecord  : locationList) {
            if (locationRecord.VisitorAddressId != null) {
                addressIds.add(locationRecord.VisitorAddressId);
            }
        }

        return addressIds;
    }

    private static Set<Id> createBranchIdsSet(List<Schema.Location> locationList) {
        Set<Id> relatedBranchIds = new Set<Id>();

        for (Schema.Location locationRecord : locationList) {
            relatedBranchIds.add(locationRecord.BranchName__c);
        }

        relatedBranchIds.remove(null);

        return relatedBranchIds;
    }

    private static void updateRelatedLocationsFields(Schema.Location relatedLocation, Schema.Location initialLocation) {
        for (String fieldToUpdate : LOCATION_FIELDS_TO_UPDATE) {
            relatedLocation.put(fieldToUpdate, initialLocation.get(fieldToUpdate));
        }
    }

    private static Map<Id, Schema.Address> selectRelatedAddress(Set<Id> addressIds) {
        if (addressIds.isEmpty()) {
            return new Map<Id, Schema.Address>();
        }

        return new Map<Id, Schema.Address>([
            SELECT
                Street,
                City,
                State,
                PostalCode
            FROM Address
            WHERE Id IN :addressIds
        ]);
    }

    private static Map<Id, Branch__c> selectRelatedBranches(Set<Id> relatedBranchIds) {
        if (relatedBranchIds.isEmpty()) {
            return new Map<Id, Branch__c>();
        }

        return new Map<Id, Branch__c>([
            SELECT
                Name,
                GBO__r.Name
            FROM Branch__c
            WHERE Id IN :relatedBranchIds
        ]);
    }

    private static List<Schema.Location> selectRelatedLocations(Set<String> buildingNumbers, Set<Id> initialLocationIds) {
        if (buildingNumbers.isEmpty()) {
            return new List<Schema.Location>();
        }

        return [
            SELECT
                AlternatePhoneNumber1__c,
                AlternatePhoneNumber2__c,
                AlternatePhoneNumber3__c,
                AlternatePhoneNumber4__c,
                Building247PhoneNumber__c,
                BuildingDayPhoneNumber__c,
                BuildingNotes__c,
                BuildingOperationalHours__c,
                MechanicNotes__c,
                PermanentSpecialInstructions__c,
                SpecialInstructionsExpiration__c,
                TemporarySpecialInstructions__c,
                TimeZone,
                BuildingNumber__c
            FROM Location
            WHERE BuildingNumber__c IN :buildingNumbers 
            AND Id NOT IN :initialLocationIds
        ];
    }

    private static String createCompoundAddress(Schema.Address addressRecord) {
        return String.format(
            '{0},{1},{2},{3}',
            new List<String> {
                addressRecord?.Street != null ? addressRecord.Street : '',
                addressRecord?.City != null ? addressRecord.City : '',
                addressRecord?.State != null ? addressRecord.State : '',
                addressRecord?.PostalCode != null ? addressRecord.PostalCode : ''
            }
        );
    }

    private static Boolean areLocationFieldsChanged(Schema.Location locationRecord, Schema.Location oldLocation) {
        for (String fieldToCheck : LOCATION_FIELDS_TO_CHECK) {
            if (locationRecord.get(fieldToCheck) != oldLocation.get(fieldToCheck)) {
                return true;
            }
        }

        return false;
    }
}