
const puppeteer = require("puppeteer");

const fs = require("fs");


// defaults
const DEFAULT_API_VERSION = "58.0";
const DEFAULT_INSTANCE_URL = "https://test.salesforce.com";

// urls
const SETUP_APEX_TEST_RESULTS_URL = "/lightning/setup/ApexTestQueue/page?address=%2F07M";

// selectors
const APEX_TEST_RESULTS_FRAME_SELECTOR = "iframe[title^='Apex Test Results']";
const CLEAR_BUTTON_SELECTOR = "input[type='button'][name='clear test data']";
const CANCEL_SETTING_BUTTON_SELECTOR = "input#RPPCancelButton";



let opts = require("optimist")
    
	.usage("Log in to SF.\nUsage: node $0 -o orgAlias -d workingDir [-i instanceUrl -u username -p password] or [-i instanceUrl -s sessionId] or [-i instanceUrl -t accessToken]")
	
	// user name
	.string("u")
    .alias("u", "userName")
    .describe("u", "sf user name")
	
	// password
	.string("p")
    .alias("p", "password")
    .describe("p", "sf password")
	
	// session id
	.string("s")
    .alias("s", "sessionId")
    .describe("s", "sessionId")
	
	// access token
	.string("t")
    .alias("t", "accessToken")
    .describe("t", "accessToken")
	
	// instance url
	.string("i")
    .alias("i", "instanceUrl")
    .describe("i", "sf instance url")
	.default("i", DEFAULT_INSTANCE_URL)
	
	// api version
	.string("v")
    .alias("v", "apiVersion")
    .describe("v", "sf api version")
	.default("v", DEFAULT_API_VERSION)
	
	// org alias
	.string("o")
    .alias("o", "orgAlias")
    .describe("o", "orgAlias")
	
	// working directory
	.string("d")
    .alias("d", "workingDir")
    .describe("d", "workingDir")
	
    .argv;


const BasicService = require((opts.workingDir || process.env.BUILD_SOURCESDIRECTORY || "../../../../../..") + "/scripts/puppeteer/service/BasicService");
const BasicUtils = require((opts.workingDir || process.env.BUILD_SOURCESDIRECTORY || "../../../../../..") + "/scripts/puppeteer/utils/BasicUtils");



async function main() {
	
	let basicService = await BasicService.getInstance();
	
	try {
		
		// log in to SF
		await basicService.logIn(opts);
		
		// open Apex Test Results page in Setup area
		await basicService.goToPage(SETUP_APEX_TEST_RESULTS_URL);
		BasicService.logMessage(`Apex Test Results page has appeared: ${basicService.page.url()}`);
		
		// wait for main frame to be loaded
		await basicService.switchToFrame(APEX_TEST_RESULTS_FRAME_SELECTOR);
		BasicService.logMessage("Apex Test Results frame has appeared initially.");
		
		// click cancel button to close potential Settings dialog
		try {
			let cancelButton = await basicService.frame.waitForSelector(CANCEL_SETTING_BUTTON_SELECTOR);
			await cancelButton.click();
			BasicService.logMessage("Clicked Cancel button to close Settings dialog.");
		} catch(error) {
			BasicService.logMessage("No Settings dialog appeared this time.");
		}
		
		// wait for 'Clear Test Data' button to appear and click it
		let clearButton = await basicService.frame.waitForSelector(CLEAR_BUTTON_SELECTOR);
		await clearButton.click();
		BasicService.logMessage("'Clear Test Data' button has been clicked.");
		
		// wait for main frame to disappear
		await basicService.page.waitForSelector(
			APEX_TEST_RESULTS_FRAME_SELECTOR,
			{
				hidden: true,
				timeout: LONG_TIMEOUT
			}
		);
		BasicService.logMessage("Apex Test Results frame has disappeared after hitting 'Clear Test Data' button.");
		
		// wait for main frame to appear back
		await basicService.switchToFrame(APEX_TEST_RESULTS_FRAME_SELECTOR);
		BasicService.logMessage("Apex Test Results frame has appeared back after finishing with clearing of test data.");
		
		// wait for 'Clear Test Data' button to appear as confirmation that cleanup has been finished
		clearButton = await basicService.frame.waitForSelector(CLEAR_BUTTON_SELECTOR);
		
	} catch(exp) {
		
		BasicService.logMessage("Error happens when clearing test data:");
		BasicService.logMessage(exp);
		
		throw exp;
		
	} finally {
		
		if (basicService) {
			await basicService.cleanup();
		}
		
	}
	
};


BasicUtils.callWithRetry(
	main,
	[],
	5,
	60 * 1000
);


