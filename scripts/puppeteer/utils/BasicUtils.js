
"use strict";


class BasicUtils {
	
	// generate UTC timestamp as string, e.g. '2018-11-19 23:01:01'
	static getUtcTimestamp() {
		
		let dateDelim = "-";
		let timeDelim = ":";
		let useTZ = false;
		
		let now = new Date();
		
		
		return (
			now.getUTCFullYear()
			+
			dateDelim
			+
			this.toTwoDigits(
				now.getUTCMonth() + 1
			)
			+
			dateDelim
			+
			this.toTwoDigits(
				now.getUTCDate()
			)
			+
			(useTZ ? "T" : " ")
			+
			this.toTwoDigits(
				now.getUTCHours()
			)
			+
			timeDelim
			+
			this.toTwoDigits(
				now.getUTCMinutes()
			)
			+
			timeDelim
			+
			this.toTwoDigits(
				now.getUTCSeconds()
			)
			+
			(useTZ ? "Z" : "")
		);
		
	}
	
	
	// prepend extra zero if provided value has only one digit, i.e. '1' -> '01'
	static toTwoDigits(source) {
		
		return ('0' + source).slice(-2);
		
	}
	
	
	static sleep(milliseconds) {
		
		return (
			new Promise(
				resolve => setTimeout(resolve, milliseconds)
			)
		);
		
	}
	
	
	static async callWithRetry(functionToCall, params = [], retryTimes = 3, retryPauseInMilisec = 5*1000) {
		
		let numberOfFailures = 0;
		
		
		while (true) {
			
			try {
				
				return await functionToCall(...params);
				
			} catch (error) {
				
				numberOfFailures++;
				
				console.log(`ERROR: ${error}`);
				
				
				// retry attempts limit has been reached
				if (numberOfFailures >= retryTimes) {
					
					console.log(`Run out of retry attempts (${numberOfFailures}/${retryTimes}).`);
					
					throw error;
					
				}
				
				
				// continue retrying after pause
				console.log(`Retrying due to error after ${retryPauseInMilisec} miliseconds (${numberOfFailures}/${retryTimes})...`);
				
				await this.sleep(retryPauseInMilisec);
				
			}
			
		}
		
	}
	
	
}
	

module.exports = BasicUtils;
