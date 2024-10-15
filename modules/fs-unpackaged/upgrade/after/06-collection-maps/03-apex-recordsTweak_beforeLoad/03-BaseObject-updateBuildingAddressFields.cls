
// grab base objects to update
List<maps__BaseObject__c> baseObjectsToUpdate = [
	SELECT 
		Id, Name, maps__Name__c, 
		maps__AddressObject__c, maps__City__c, maps__Country__c, maps__Latitude__c, maps__Longitude__c, 
		maps__PostalCode__c, maps__State__c, maps__Street__c, maps__VerifiedLatitude__c, maps__VerifiedLongitude__c
	FROM 
		maps__BaseObject__c 
	WHERE 
		Name = 'Location'
		AND
		maps__Name__c = 'Building'
		AND
		maps__AddressObject__c = 'SAME'
		AND
		maps__VerifiedLatitude__c = ''
		AND
		maps__VerifiedLongitude__c = ''
];


// early exit - no base objects to update found
if (baseObjectsToUpdate == null || baseObjectsToUpdate.isEmpty()) {
	return;
}


for (maps__BaseObject__c baseObjectToUpdate : baseObjectsToUpdate) {
	
	baseObjectToUpdate.maps__AddressObject__c = 'VisitorAddressId';
	baseObjectToUpdate.maps__City__c = 'VisitorAddress.City';
	baseObjectToUpdate.maps__Country__c = 'VisitorAddress.Country';
	baseObjectToUpdate.maps__Latitude__c = 'VisitorAddress.Latitude';
	baseObjectToUpdate.maps__Longitude__c = 'VisitorAddress.Longitude';
	baseObjectToUpdate.maps__PostalCode__c = 'VisitorAddress.PostalCode';
	baseObjectToUpdate.maps__State__c = 'VisitorAddress.State';
	baseObjectToUpdate.maps__Street__c = 'VisitorAddress.Street';
	baseObjectToUpdate.maps__VerifiedLatitude__c = 'VisitorAddress.Latitude';
	baseObjectToUpdate.maps__VerifiedLongitude__c = 'VisitorAddress.Longitude';
	
}


update baseObjectsToUpdate;

