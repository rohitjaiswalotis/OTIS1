
// grab layers to update
List<maps__MarkerLayer__c> layersToUpdate = [
	SELECT 
		Id, maps__OwnerFilterId__c, maps__Query__c
	FROM 
		maps__MarkerLayer__c 
	WHERE 
		Name IN (
			'S1 Dispatched Service Appointments', 
			'S2 Dispatched Service Appointments', 
			'S3 Dispatched Service Appointments'
		)
		AND 
		maps__BaseObject__r.Name = 'ServiceAppointment'
		AND 
		maps__Folder__r.Name = 'Otis Layers'
		AND 
		maps__OwnerFilterId__c = 'Team'
];


// early exit - no lyaers to update found
if (layersToUpdate == null || layersToUpdate.isEmpty()) {
	return;
}


for (maps__MarkerLayer__c layerToUpdate : layersToUpdate) {
	
	layerToUpdate.maps__OwnerFilterId__c = 'All';
	
	layerToUpdate.maps__Query__c = layerToUpdate.maps__Query__c.removeEndIgnoreCase(' AND OwnerId IN :TeamRoleIds');
	
}


update layersToUpdate;

