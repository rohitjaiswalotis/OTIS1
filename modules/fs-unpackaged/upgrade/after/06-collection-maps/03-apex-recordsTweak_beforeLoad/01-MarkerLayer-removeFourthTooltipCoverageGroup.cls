
// grab layers to update
List<maps__MarkerLayer__c> layersToUpdate = [
	SELECT 
		Id, maps__Tooltip1__c, maps__Tooltip2__c, maps__Tooltip3__c, maps__Tooltip4__c, maps__Tooltip5__c, maps__Tooltip6__c 
	FROM 
		maps__MarkerLayer__c 
	WHERE 
		Name = 'Mechanic Location' 
		AND 
		maps__BaseObject__r.Name = 'ServiceResource' 
		AND 
		maps__Folder__r.Name = 'Otis Layers' 
		AND 
		maps__Tooltip4__c = 'ServiceCrewId'
];


// early exit - no layers to update found
if (layersToUpdate == null || layersToUpdate.isEmpty()) {
	return;
}


for (maps__MarkerLayer__c layerToUpdate : layersToUpdate) {
	
	if (String.isBlank(layerToUpdate.maps__Tooltip5__c)) {
		
		layerToUpdate.maps__Tooltip4__c = '';
		
	} else {
		
		layerToUpdate.maps__Tooltip4__c = layerToUpdate.maps__Tooltip5__c;
		layerToUpdate.maps__Tooltip5__c = '';
		
	}
	
}


update layersToUpdate;

