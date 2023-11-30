
const BATCH_SIZE = 100;


main();


async function main() {
	
	// delete ApexCodeCoverageAggregate records
	try {
		
		await (
			utils.sobject.deleteRecordsTooling(
				"SELECT Id FROM ApexCodeCoverageAggregate",
				BATCH_SIZE
			)
		);
		
	} catch (exp) {
		
		console.warn(`WARNING: Error when deleting ApexCodeCoverageAggregate records:`, exp);
		
	}
	
	
	// delete ApexOrgWideCoverage records
	try {
		
		await (
			utils.sobject.deleteRecordsTooling(
				"SELECT Id FROM ApexOrgWideCoverage",
				BATCH_SIZE
			)
		);
		
	} catch (exp) {
		
		console.warn(`WARNING: Error when deleting ApexOrgWideCoverage records:`, exp);
		
	}
	
	
	// delete ApexTestResult records
	try {
		
		await (
			utils.sobject.deleteRecordsTooling(
				"SELECT Id FROM ApexTestResult",
				BATCH_SIZE
			)
		);
		
	} catch (exp) {
		
		console.warn(`WARNING: Error when deleting ApexTestResult records:`, exp);
		
	}
	
}


