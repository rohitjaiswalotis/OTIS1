/**=========================================================================================
Developed by - Aditya Kannaujia
Created date - 02/08/2024
Description - Test class for FSL_AssetService class.
=========================================================================================*/
@isTest
public class FSL_AssetServiceTest {
    @isTest
    static void testUpdateServiceAppointmentsWithAssetLocation() {
        // Create test data using TestDataFactory
        Schema.Location testLocation = FSL_TestDataFactory.createLocation('Test Location');
        insert testLocation;
        
        Schema.Address testAddress = FSL_TestDataFactory.createAddress(new Map<String, Object>{
            'Street' => '123 Test St',
                'City' => 'Test City',
                'State' => 'TS',
                'PostalCode' => '12345',
                'Country' => 'Test Country',
                'Latitude' => 37.7749,
                'Longitude' => -122.4194,
                'ParentId' => testLocation.Id
                });
        
        insert testAddress;
        
        Schema.Address testAddressTwo = FSL_TestDataFactory.createAddress(new Map<String, Object>{
            'Street' => '123 Test St',
                'City' => 'Test City',
                'State' => 'TS',
                'PostalCode' => '12345',
                'Country' => 'Test Country',
                'Latitude' => 39.767,
                'Longitude' => -128.4194,
                'ParentId' => testLocation.Id
                });
        
        insert testAddressTwo;
        
        Asset oldAsset = FSL_TestDataFactory.createAsset('Test Asset', testLocation.Id,testAddress.Latitude,testAddress.Longitude);
        insert oldAsset;
        
        oldAsset.Latitude = testAddressTwo.Latitude;
        oldAsset.Longitude = testAddressTwo.Longitude;
        update oldAsset;
        
        // Prepare maps for the service method
        Map<Id, Asset> newAssetMap = new Map<Id, Asset>([SELECT Id, LocationId FROM Asset WHERE Id = :oldAsset.Id]);
        Map<Id, Asset> oldAssetMap = new Map<Id, Asset>([SELECT Id, LocationId FROM Asset WHERE Id = :oldAsset.Id]);
        
        Test.startTest();
        // Call the method to update ServiceAppointments
        FSL_AssetService.updateSArecordsFromUnit(newAssetMap, oldAssetMap);
        Test.stopTest();
         
        System.assertEquals(39.767,oldAsset.Latitude , 'Updated Lat');
        System.assertEquals(-128.4194,oldAsset.Longitude , 'Updated Long');
    }
}