
const fs = require("fs");
const os = require("os");


main();


async function main() {
	
	try {
		
		let app = await utils.metadata.getConnectedApp("sf_fieldservice__Salesforce_Field_Service_for_iOS");
		
		console.log("Retrieved app:");
		console.log(
			JSON.stringify(
				app,
				null,
				4
			)
		);
		
	} catch (exp) {
		
		console.log("ERROR: Error when retrieving connected app: " + JSON.stringify(exp, null, 4));
		
		throw exp;
		
	}
	
}

