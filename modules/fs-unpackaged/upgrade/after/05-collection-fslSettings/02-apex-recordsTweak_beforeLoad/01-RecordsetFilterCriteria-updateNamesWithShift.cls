
// grab records to update
List<RecordsetFilterCriteria> rsfCriteria = [
	SELECT
		Id,
		Name
	FROM
		RecordsetFilterCriteria
	WHERE
		Name IN (
			'Maintenance Designated Time',
			'OpenOrder Designated time',
			'Repair Designated Time',
			'Service Request Designated Time'
		)
		AND
		SourceObject = 'Shift'
		AND
		FilteredObject = 'ServiceAppointment'
];


// early exit - no records to update found
if (rsfCriteria == null || rsfCriteria.isEmpty()) {
	return;
}


for (RecordsetFilterCriteria rsfCriterion : rsfCriteria) {
	
	rsfCriterion.Name += ' for Shift';
	
}


update rsfCriteria;

