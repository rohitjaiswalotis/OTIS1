
const path = require("path");
const fs = require("fs");

const sfbulk = require("node-sf-bulk2");
const axios = require("axios");


// time related
const JOB_STATUS_PULLING_INTERVAL = 30 * 1000;


// standard operations
const OPERATION_INSERT = "insert".toLowerCase();
const OPERATION_UPDATE = "update".toLowerCase();
const OPERATION_UPSERT = "upsert".toLowerCase();
const OPERATION_DELETE = "delete".toLowerCase();
const OPERATION_HARDDELETE = "hardDelete".toLowerCase();

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
		
	]
);


// job statuses
const JOB_STATUS_READY = "UploadComplete";
const JOB_STATUS_IN_PROGRESS = "InProgress";
const JOB_STATUS_ABORTED = "Aborted";
const JOB_STATUS_COMPLETED = "JobComplete";
const JOB_STATUS_FAILED = "Failed";


const JOB_STATUSES_FINISHED = (
	new Set(
		[
			JOB_STATUS_ABORTED,
			JOB_STATUS_COMPLETED,
			JOB_STATUS_FAILED
		].map( 
			el => el.toLowerCase()
		)
	)
);


// result types
const RESULT_TYPE_SUCCESS = "successfulResults";
const RESULT_TYPE_FAILED = "failedResults";
const RESULT_TYPE_UNPROCESSED = "unprocessedrecords";


// restrictions
const RESULT_RECORDS_LIMIT_TO_PRINT = 10;



// set up params
{
	
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
		
		console.log(
			`Loading DataFile: ${context.dataFile}, ObjectType: ${context.objectType}, Operation: ${context.operation}`
			+ 
			(context.operation === OPERATION_UPSERT ? `, ExternalIdField: ${context.externalIdField}` : "")
		);
		
		let dataStream = fs.createReadStream(context.dataFile);
		
		
		// create bulk connection
		const bulkConnection = new sfbulk.BulkAPI2(connection);
		
		// create job
		let { id: jobId, status: jobStatus, contentUrl: jobContentUrl } = (
			await createJob(
				bulkConnection, 
				context.objectType, 
				context.operation, 
				context.externalIdField
			)
		);
		
		// upload data
		await uploadData(bulkConnection, jobId, jobContentUrl, dataStream);
		
		// wait for job to complete
		await waitForJobToComplete(bulkConnection, jobId);
		
		
		// get job results
		{
			
			let outputFile = context.dataFile;
			
			// success records
			await getJobSuccessResults(
				bulkConnection, 
				jobId, 
				utils.file.appendToFileName(outputFile, ".result_success")
			);
			
			// failed records
			await getJobFailedResults(
				bulkConnection, 
				jobId, 
				utils.file.appendToFileName(outputFile, ".result_error")
			);
			
			// unprocessed records
			await getJobUnprocessedResults(
				bulkConnection, 
				jobId, 
				utils.file.appendToFileName(outputFile, ".result_unprocessed")
			);
			
		}
		
		
		// delete job
		await deleteJob(bulkConnection, jobId);
		
		
	} catch (exp) {
		
		console.log("ERROR: Error when loading data: " + JSON.stringify(exp, null, 4));
		
		throw exp;
		
	}
	
}



async function createJob(bulkConnection, object, operation, externalIdFieldName = null, contentType = "CSV", lineEnding = "LF") {
	
	let jobOptions = {
		"object" : object,
		"contentType" : contentType,
		"operation" : operation,
		"lineEnding": lineEnding
	};
	
	if (externalIdFieldName) {
		jobOptions["externalIdFieldName"] = externalIdFieldName;
	}
	
	
	let responseBody = (
		await utils.common.callWithRetry(
			() => {
				return (
					bulkConnection.createDataUploadJob(
						jobOptions
					)
				);
			},
			[]
		)
	);
	
	
	console.log(responseBody);
	
	if (responseBody.id) {
		
		console.log(`Job created: id = ${responseBody.id}, status = ${responseBody.state}, contentUrl = ${responseBody.contentUrl}`);
		
		return {
			id: responseBody.id,
			status: responseBody.state,
			contentUrl: responseBody.contentUrl
		};
		
	}
	
	throw "Error when creating job";
	
}


async function uploadData(bulkConnection, jobId, contentUrl, data) {
	
	let statusCode = (
		await utils.common.callWithRetry(
			() => {
				return (
					bulkConnection.uploadJobData(
						contentUrl,
						data
					)
				);
			},
			[]
		)
	);
	
	
	if (statusCode !== 201) {
		throw "Error when uploading data";
	}
	
	console.log("Job data has been uploaded.");
	
	await markJobAsReady(bulkConnection, jobId);
	
}


async function markJobAsReady(bulkConnection, jobId) {
	
	let responseBody = (
		await utils.common.callWithRetry(
			() => {
				return (
					bulkConnection.closeOrAbortJob(
						jobId,
						JOB_STATUS_READY
					)
				);
			},
			[]
		)
	);
	
	console.log(responseBody);
	let jobStatus = responseBody.state;
	
	if (!isJobReady(jobStatus)) {
		throw "Error when updating job status";
	}
	
	console.log("Job has been marked as ready.");
	
}


async function waitForJobToComplete(bulkConnection, jobId) {
	
	while (true) {
		
		// get job status
		let responseBody = (
			await utils.common.callWithRetry(
				() => {
					return (
						bulkConnection.getIngestJobInfo(jobId)
					);
				},
				[]
			)
		);
		
		
		console.log(responseBody);
		
		let jobStatus = responseBody.state;
		
		if (!jobStatus) {
			throw "Error when getting job status";
		}
		
		
		console.log(`Job Status = ${jobStatus}`);
		
		
		if (isJobCompleted(responseBody.state)) {
			break;
		} else if (isJobAborted(responseBody.state)) {
			throw "Job has been aborted!";
		} else if (isJobFailed(responseBody.state)) {
			throw "Job has failed!";
		}
		
		
		await utils.common.sleep(JOB_STATUS_PULLING_INTERVAL);
		
	}
	
}


async function getJobSuccessResults(bulkConnection, jobId, outputFile) {
	
	await getJobResults(bulkConnection, jobId, RESULT_TYPE_SUCCESS, outputFile);
	
}


async function getJobFailedResults(bulkConnection, jobId, outputFile) {
	
	await getJobResults(bulkConnection, jobId, RESULT_TYPE_FAILED, outputFile);
	
}


async function getJobUnprocessedResults(bulkConnection, jobId, outputFile) {
	
	await getJobResults(bulkConnection, jobId, RESULT_TYPE_UNPROCESSED, outputFile);
	
}


async function getJobResults(bulkConnection, jobId, resultType, outputFile) {
	
	let data = (
		await utils.common.callWithRetry(
			() => {
				return (
					bulkConnection.getResults(
						jobId,
						resultType
					)
				);
			},
			[],
			10,		// retry attempts
			30*1000 // delay in milisec between retries
		)
	).trim();
	
	
	// dump results to output file (if any)
	if (outputFile) {
		
		await utils.file.write(
			outputFile,
			data
		);
		
	}
	
	
	// print results
	{
		
		let lines = data.trim().split("\n");
		let recordsCount = lines.length - 1; // minus first line with header	
		
		
		// print stats
		console.log(`Job Result for '${resultType}': ${recordsCount} records`);
		
		// print first N lines of results (if any)
		if (recordsCount) {
			console.log(
				lines.slice(
					0, 
					RESULT_RECORDS_LIMIT_TO_PRINT + 1
				).join(
					"\n"
				)
				+
				( recordsCount >  RESULT_RECORDS_LIMIT_TO_PRINT ? "\n...OUTPUT TRUNCATED...\n" : "\n")
			);
		}
		
	}
	
}


async function deleteJob(bulkConnection, jobId) {
	
	let endpoint = `${connection.instanceUrl}/services/data/v${connection.version}/jobs/ingest/${jobId}`;
	
	
	const headers = {
		'Content-Type': 'application/json',
		'Authorization': 'Bearer ' + connection.accessToken
	};
	
	let response = (
		await utils.common.callWithRetry(
			() => {
				return (
					axios.delete(endpoint, { headers })
				);
			},
			[]
		)
	);
	
	if (response.status != 204) {
		throw "Error when deleting job";
	}
	
	console.log(`Job ${jobId} has been successfully deleted`);
	
}



function isJobReady(status) {
	return utils.common.isEquivalent(status, JOB_STATUS_READY);
}


function isJobCompleted(status) {
	return utils.common.isEquivalent(status, JOB_STATUS_COMPLETED);
}

function isJobAborted(status) {
	return utils.common.isEquivalent(status, JOB_STATUS_ABORTED);
}

function isJobFailed(status) {
	return utils.common.isEquivalent(status, JOB_STATUS_FAILED);
}

function isJobDone(status) {
	return JOB_STATUSES_FINISHED.has(status.toLowerCase());
}


