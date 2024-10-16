
const fieldNamesToActivateHistory = {
	
	"ServiceAppointment.FSL__Auto_Schedule__c" : "true",
	"ServiceAppointment.FSL__InJeopardy__c" : "true",
	"ServiceAppointment.FSL__InJeopardyReason__c" : "true",
	"ServiceAppointment.FSL__Pinned__c" : "true",
	"ServiceAppointment.FSL__Schedule_over_lower_priority_appointment__c" : "true",
	"ServiceAppointment.FSL__Scheduling_Policy_Used__c" : "true"

};


main();


async function main() {
	
	// upsert options
	for (const [fieldName, needsHistoryTracking] of Object.entries(fieldNamesToActivateHistory)) {
		(
			await updateFieldHistoryTracking(
				fieldName,
				needsHistoryTracking
			)
		);
	}
}

/**
 * Enable/Disable History Tracking for the field
 */
async function updateFieldHistoryTracking(fieldName, needsHistoryTracking) {

	try {
		return (
			await utils.metadata.updateMetadataArtifacts(
				fieldName,
				"CustomField",
				field => _updateFieldHistoryAttribute(field, needsHistoryTracking)
			)
		);
	} catch (exp) {
		console.log(
			`ERROR: Error when updating history tracking for '${fieldName}': ` +
			JSON.stringify(exp, null, 4)
		);
	}
}

// private: change field history attribute
function _updateFieldHistoryAttribute(field, needsHistoryTracking) {

	field[0].trackHistory = needsHistoryTracking;

	return field;
}
