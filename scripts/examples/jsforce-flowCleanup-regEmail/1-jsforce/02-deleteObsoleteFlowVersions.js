
const BATCH_SIZE = 100;


main();


async function main() {
	
	try {
		
		// fetch obsolete flows versions to delete
		let versionsToDelete = (
			await 
			utils.toolingQuery.queryAllRecords(
				`
				SELECT 
					Id, 
					MasterLabel, 
					ProcessType,
					Status,
					IsTemplate, 
					ManageableState, 
					VersionNumber 
				FROM 
					Flow 
				WHERE 
					Status = 'Obsolete'
					AND
					ManageableState != 'released'
				`
			)
		);
		
		
		// early exit - no obsolete flows versions
		if (!versionsToDelete || !versionsToDelete.length) {
			
			console.log(`WARNING: No obsolete flows versions found at all!`);
			
			return;
			
		}
		
		
		console.log(
			`Found ${versionsToDelete.length} flows versions to delete: ` + 
				utils.common.mapToUnique(versionsToDelete, "MasterLabel")
		);
		
		utils.common.logJson(versionsToDelete);
		
		
		await (
			utils.sobject.deleteRecordsTooling(
				"Flow",
				utils.common.mapToUniqueIds(versionsToDelete),
				BATCH_SIZE
			)
		);
		
		
	} catch (exp) {
		
		console.warn(`WARNING: Error when deleting obsolete flows versions:`, exp);
		
	}
	
}


