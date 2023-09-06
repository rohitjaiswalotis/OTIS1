
const fs = require("fs");
const os = require("os");


context.emailToRegister = "boom@abc.com";


main();


async function main() {
	
	try {
		
		// main org
		{
			
			let result = await connection.query(
				"SELECT " + 
					"Id, " + 
					"UserId, " + 
					"User.Name, " + 
					"User.Email, " + 
					"Email, " + 
					"LastModifiedDate, " + 
					"LastModifiedBy.Id, " + 
					"LastModifiedBy.Name " + 
				"FROM " + 
					"ApexEmailNotification " + 
				"WHERE " + 
					"Email = '" + context.emailToRegister + "'" +
					" OR " + 
					"User.Email = '" + context.emailToRegister + "'"
			);
			
			
			if (result.records.length) {
				
				console.log("Already registered in main org:");
				
				console.log(
					JSON.stringify(
						result.records[0],
						null,
						4
					)
				);
				
				result = result.records[0];
				
			} else {
				
				console.log("Not registered yet in main org.");
				
				console.log("Registration in-progress in main org...");
				
				
				// build notification record
				let notificationToCreate = {}; {
					
					notificationToCreate.Email = context.emailToRegister;
					
				}
				
				
				// actually create notification
				result = await connection.tooling.sobject("ApexEmailNotification").create(
					notificationToCreate
				);
				
				console.log("Done with registration in main org:");
				
				console.log(
					JSON.stringify(
						result,
						null,
						4
					)
				);
				
			}
			
		}
		
		
		// secondary org
		if (connection2) {
			
			let result = await connection2.query(
				"SELECT " + 
					"Id, " + 
					"UserId, " + 
					"User.Name, " + 
					"User.Email, " + 
					"Email, " + 
					"LastModifiedDate, " + 
					"LastModifiedBy.Id, " + 
					"LastModifiedBy.Name " + 
				"FROM " + 
					"ApexEmailNotification " + 
				"WHERE " + 
					"Email = '" + context.emailToRegister + "'" +
					" OR " + 
					"User.Email = '" + context.emailToRegister + "'"
			);
			
			
			if (result.records.length) {
				
				console.log("Already registered in secondary org:");
				
				console.log(
					JSON.stringify(
						result.records[0],
						null,
						4
					)
				);
				
				result = result.records[0];
				
			} else {
				
				console.log("Not registered yet in secondary org.");
				
				console.log("Registration in-progress in secondary org...");
				
				
				// build notification record
				let notificationToCreate = {}; {
					
					notificationToCreate.Email = context.emailToRegister;
					
				}
				
				
				// actually create notification
				result = await connection2.tooling.sobject("ApexEmailNotification").create(
					notificationToCreate
				);
				
				console.log("Done with registration in secondary org:");
				
				console.log(
					JSON.stringify(
						result,
						null,
						4
					)
				);
				
			}
			
		}
		
	
	} catch (exp) {
		
		console.log("ERROR: Error when registering apex exception email: " + JSON.stringify(exp, null, 4));
		
		throw exp;
		
	}
	
}

