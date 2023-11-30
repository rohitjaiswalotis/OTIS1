
const puppeteer = require("puppeteer");

const fs = require("fs");


// defaults
const DEFAULT_API_VERSION = "58.0";
const DEFAULT_INSTANCE_URL = "https://test.salesforce.com";

// urls
const SETUP_CONTRACT_STATUS_FIELD_URL = "/lightning/setup/ObjectManager/Contract/FieldsAndRelationships/Status/view";

// selectors

const CONTRACT_FIELD_DETAILS_FRAME_SELECTOR = "iframe[title^='Contract Field:']";
const CONTRACT_FIELD_EDIT_FRAME_SELECTOR = "iframe[title^='Picklist Edit:']";
const SAVE_BUTTON_SELECTOR = "input[type='submit'][name='save']";
const TEXT_INPUT_SELECTOR = "input[type='text']";

const IN_APPROVAL_EDIT_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Edit'][title$='In Approval Process']";
const ACTIVATED_EDIT_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Edit'][title$='Activated']";
const DRAFT_EDIT_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Edit'][title$='Draft']";


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


const BasicService = require((opts.workingDir || process.env.BUILD_SOURCESDIRECTORY || "../../../..") + "/scripts/puppeteer/service/BasicService");
const BasicUtils = require((opts.workingDir || process.env.BUILD_SOURCESDIRECTORY || "../../../..") + "/scripts/puppeteer/utils/BasicUtils");



async function main() {
	
	let basicService = await BasicService.getInstance();
	
	try {
		
		// log in to SF
		await basicService.logIn(opts);
		
		// open Contract.Status field details in Setup area
		await basicService.goToPage(SETUP_CONTRACT_STATUS_FIELD_URL);
		BasicService.logMessage(`Contract Status Picklist Field Details page has appeared: ${basicService.page.url()}`);
		
		await basicService.switchToFrame(CONTRACT_FIELD_DETAILS_FRAME_SELECTOR);
		BasicService.logMessage("Contract Status Picklist Field Details frame has appeared.");
		
		
		// In Approval Process -> Pending
		{
			
			const inApprovalProcessOption = await basicService.frame.$(IN_APPROVAL_EDIT_PICKLIST_OPTION_SELECTOR);
			
			if (inApprovalProcessOption) {
				
				BasicService.logMessage("Detected 'In Approval Process' option, going to change to 'Pending'");
				
				await inApprovalProcessOption.click();
				BasicService.logMessage("AFTER CLICKING IN APPROVAL PROCESS OPTION");
				
				await basicService.switchToFrame(CONTRACT_FIELD_EDIT_FRAME_SELECTOR);
				BasicService.logMessage("AFTER SWITCHING TO FRAME");
				
				await basicService.frame.$$eval(
					TEXT_INPUT_SELECTOR, 
					inputs => inputs.forEach(el => el.value = "Pending")
				);
				BasicService.logMessage("AFTER POPULATING ALL INPUT FIELDS");
				
				let saveButton = await basicService.frame.$(SAVE_BUTTON_SELECTOR);
				BasicService.logMessage("AFTER GETTING SAVE BUTTON");
				await saveButton.click();
				BasicService.logMessage("AFTER CLICKING SAVE BUTTON");
				
				await basicService.switchToFrame(CONTRACT_FIELD_DETAILS_FRAME_SELECTOR);
				
				BasicService.logMessage("AFTER SWITCHING BACK TO FRAME");
				
			} else {
				
				BasicService.logMessage("No 'In Approval Process' option detected!");
				
			}
			
		}
		
		
		// Activated -> Active
		{
			
			const activatedOption = await basicService.frame.$(ACTIVATED_EDIT_PICKLIST_OPTION_SELECTOR);
			
			if (activatedOption) {
				
				BasicService.logMessage("Detected 'Activated' option, going to change to 'Active'");
				
				await activatedOption.click();
				
				await basicService.switchToFrame(CONTRACT_FIELD_EDIT_FRAME_SELECTOR);
				
				await basicService.frame.$$eval(
					TEXT_INPUT_SELECTOR, 
					inputs => inputs.forEach(el => el.value = "Active")
				);
				
				let saveButton = await basicService.frame.$(SAVE_BUTTON_SELECTOR);
				await saveButton.click();
				
				await basicService.switchToFrame(CONTRACT_FIELD_DETAILS_FRAME_SELECTOR);
				
			} else {
				
				BasicService.logMessage("No 'Activated' option detected!");
				
			}
			
		}
		
		
		// Draft -> Inactive
		{
			
			const draftOption = await basicService.frame.$(DRAFT_EDIT_PICKLIST_OPTION_SELECTOR);
			
			if (draftOption) {
				
				BasicService.logMessage("Detected 'Draft' option, going to change to 'Inactive'");
				
				await draftOption.click();
				
				await basicService.switchToFrame(CONTRACT_FIELD_EDIT_FRAME_SELECTOR);
				
				await basicService.frame.$$eval(
					TEXT_INPUT_SELECTOR, 
					inputs => inputs.forEach(el => el.value = "Inactive")
				);
				
				let saveButton = await basicService.frame.$(SAVE_BUTTON_SELECTOR);
				await saveButton.click();
				
				await basicService.switchToFrame(CONTRACT_FIELD_DETAILS_FRAME_SELECTOR);
				
			} else {
				
				BasicService.logMessage("No 'Draft' option detected!");
				
			}
			
		}
		
	} catch(exp) {
		
		BasicService.logMessage("Error happens when renaming picklist options:");
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



