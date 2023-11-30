
const fs = require("fs");

const DEFAULT_POLLING_INTERVAL = 30 * 1000; 		// 30 sec
const DEFAULT_POLLING_TIMEOUT = 60 * 60 * 1000; 	// 1 hour

// standard operations
const OPERATION_INSERT = "insert".toLowerCase();
const OPERATION_UPDATE = "update".toLowerCase();
const OPERATION_UPSERT = "upsert".toLowerCase();
const OPERATION_DELETE = "delete".toLowerCase();
const OPERATION_HARDDELETE = "hardDelete".toLowerCase();

// custom operations
const OPERATION_DELETE_BY_QUERY = "deleteByQuery".toLowerCase();

const DEFAULT_OPERATION_TYPE = OPERATION_INSERT;

const DEFAULT_EXTERNAL_ID_FIELD = "Id";


const SUPPORTED_OPERATIONS = new Set(
	[
		
		// standard operations
		OPERATION_INSERT,
		OPERATION_UPDATE,
		OPERATION_UPSERT,
		OPERATION_DELETE,
		OPERATION_HARDDELETE,
		
		// custom operations
		OPERATION_DELETE_BY_QUERY
		
	]
);


// set up params
{
	
	context.pollInterval = context.pollInterval || DEFAULT_POLLING_INTERVAL;
	context.pollTimeout = context.pollTimeout || DEFAULT_POLLING_TIMEOUT;
	
	// parse object type and operation from data file (if not provided explicitly) assuming naming conventions like, OCE__Affilitation__c-insert-testData.csv
	{
		
		// remove path leaving only file name
		let dataFileName = context.dataFile.replace(/^.*[\\\/]/, "");
		
		[ 
			objectTypeFromFile, 
			operationFromFile = DEFAULT_OPERATION_TYPE, 
			externalIdField = DEFAULT_EXTERNAL_ID_FIELD 
		] = dataFileName.replace(/^[^a-z]*([a-z][a-z_0-9]*)(-[a-z]+)?(-[a-z][a-z_0-9]*)?.*$/i, "$1$2$3").split("-");
		
		context.objectType = context.objectType || objectTypeFromFile;
		context.operation = (context.operation || operationFromFile).toLowerCase();
		
		context.operation = SUPPORTED_OPERATIONS.has(context.operation) ? context.operation : DEFAULT_OPERATION_TYPE;
		
		context.externalIdField = context.externalIdField || externalIdField;
		
	}
	
}


main();


async function main() {
	
	try {
		
		connection.bulk.pollInterval = context.pollInterval;
		connection.bulk.pollTimeout = context.pollTimeout;
		
		let dataStream;
		
		
		// query data in advance to delete
		if (context.operation === OPERATION_DELETE_BY_QUERY) {
			
			console.log(`Querying data before delete: ${context.dataFile}, ObjectType: ${context.objectType}, Operation: ${context.operation}`);
			
			context.query = fs.readFileSync(context.dataFile, "utf8");
			console.log(`Query: [ ${context.query} ]`);
			
			dataStream = connection.bulk.query(context.query).stream();
			
			context.operation = OPERATION_DELETE;
			
		} else {
			
			console.log(
				`Loading DataFile: ${context.dataFile}, ObjectType: ${context.objectType}, Operation: ${context.operation}`
				+ 
				(context.operation === OPERATION_UPSERT ? `, ExternalIdField: ${context.externalIdField}` : "")
			);
			
			dataStream = fs.createReadStream(context.dataFile);
			
		}
		
		
		// bulk load options
		let options = {};
		
		// include external id field in case of upsert operation
		if (context.operation === OPERATION_UPSERT) {	
			options.extIdField = context.externalIdField;
		}
		
		
		let results = (
			await 
			connection.bulk.load(
				context.objectType, 
				context.operation, 
				options,
				dataStream
			)
		);
		
		
		// collect stats
		let successCount = 0;
		let errorCount = 0;
		let errors = [];
		
		results.forEach( 
			result => {
				
				if (result.success) {
					
					successCount++;
					
				} else {
					
					errorCount++;
					
					errors.push(
						result.errors.join(', ')
					);
					
				}
				
			}
		);
		
		console.log(
			JSON.stringify(
				results,
				null,
				4
			)
		);
		
		console.log(`SUCCESS: ${successCount}, ERRORS: ${errorCount}`);
		
		if (errors.length) {
			console.log(
				errors.join("\n")
			);
		}
		
	
	} catch (exp) {
		
		console.log("ERROR: Error when loading data: " + JSON.stringify(exp, null, 4));
		
		throw exp;
		
	}
	
}

