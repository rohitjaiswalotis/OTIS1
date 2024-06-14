
const puppeteer = require("puppeteer");

const fs = require("fs");


// defaults
const DEFAULT_API_VERSION = "61.0";
const DEFAULT_INSTANCE_URL = "https://test.salesforce.com";

// urls
const SETUP_DIGITAL_SIGNATURE_TYPE_FIELD_URL = "/lightning/setup/ObjectManager/DigitalSignature/FieldsAndRelationships/SignatureType/view";

// selectors

const DIGITAL_SIGNATURE_FIELD_DETAILS_FRAME_SELECTOR = "iframe[title^='Digital Signature Field:']";
const ADD_PICKLIST_OPTIONS_FRAME_SELECTOR = "iframe[title^='Add Picklist Values:']";
const SAVE_BUTTON_SELECTOR = "input[type='submit'][name='save']";
const OPTIONS_INPUT_SELECTOR = "textarea[type='text']";

const CUSTOMER_DEACTIVATE_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Deactivate'][title$='Customer']";
const CUSTOMER_ACTIVATE_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Activate'][title$='Customer']";

const MECHANIC_DEACTIVATE_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Deactivate'][title$='Mechanic']";
const MECHANIC_ACTIVATE_PICKLIST_OPTION_SELECTOR = "a.actionLink[title^='Activate'][title$='Mechanic']";

const NEW_PICKLIST_OPTION_BUTTON_SELECTOR = "input[name='new'][title='New Type Picklist Values']";


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


const BasicService = require((opts.workingDir || process.env.BUILD_SOURCESDIRECTORY || "../../../../..") + "/scripts/puppeteer/service/BasicService");
const BasicUtils = require((opts.workingDir || process.env.BUILD_SOURCESDIRECTORY || "../../../../..") + "/scripts/puppeteer/utils/BasicUtils");



async function main() {
	
	let basicService = await BasicService.getInstance();
	
	try {
		
		// log in to SF
		await basicService.logIn(opts);
		
		// open DigitalSignature.SignatureType field details in Setup area
		await basicService.goToPage(SETUP_DIGITAL_SIGNATURE_TYPE_FIELD_URL);
		BasicService.logMessage(`Digital Signature Type Picklist Field Details page has appeared: ${basicService.page.url()}`);
		
		await basicService.switchToFrame(DIGITAL_SIGNATURE_FIELD_DETAILS_FRAME_SELECTOR);
		BasicService.logMessage("Digital Signature Type Picklist Field Details frame has appeared.");
		
		
		// Create 'Customer' option
		{
			
			let customerDeactivateOption = await basicService.frame.$(CUSTOMER_DEACTIVATE_PICKLIST_OPTION_SELECTOR);
			let customerActivateOption = await basicService.frame.$(CUSTOMER_ACTIVATE_PICKLIST_OPTION_SELECTOR);
			
			// active Customer option exist -> done here
			if (customerDeactivateOption) {
				
				BasicService.logMessage("Detected existent active 'Customer' option - nothing to do here!");
				
			// inactive Customer option exist -> activate
			} else if (customerActivateOption) {
				
				BasicService.logMessage("Detected existent inactive 'Customer' option - trying to activate it...");
				
				await customerActivateOption.click();
				
				BasicService.logMessage("AFTER CLICKING ACTIVATE ON INACTIVE EXISTENT OPTION");
				
				await basicService.page.waitForNavigation({ waitUntil: "networkidle0" });
				
				await basicService.switchToFrame(DIGITAL_SIGNATURE_FIELD_DETAILS_FRAME_SELECTOR);
				customerDeactivateOption = await basicService.frame.$(CUSTOMER_DEACTIVATE_PICKLIST_OPTION_SELECTOR);
				
				if (customerDeactivateOption) {
					BasicService.logMessage("Deactivate link has appeared as prove of successful activation!");
				} else {
					BasicService.logMessage("WARNING: No Deactivate button detected after clicking Activate on existing inactive Customer option!");
				}
				
			// no Customer option exist -> create new one as active
			} else {
				
				BasicService.logMessage("No Customer picklist option exist - trying to create a new one as active...");
				
				let newPicklistOptionButton = await basicService.frame.$(NEW_PICKLIST_OPTION_BUTTON_SELECTOR);
				BasicService.logMessage("AFTER GETTING NEW PICKLIST OPTION BUTTON");
				await newPicklistOptionButton.click();
				BasicService.logMessage("AFTER CLICKING IN NEW PICKLIST OPTION BUTTON");
				
				await basicService.switchToFrame(ADD_PICKLIST_OPTIONS_FRAME_SELECTOR);
				BasicService.logMessage("AFTER SWITCHING TO FRAME");
				
				await basicService.frame.$$eval(
					OPTIONS_INPUT_SELECTOR, 
					inputs => inputs.forEach(el => el.value = "Customer")
				);
				BasicService.logMessage("AFTER POPULATING ALL INPUT FIELDS");
				
				let saveButton = await basicService.frame.$(SAVE_BUTTON_SELECTOR);
				BasicService.logMessage("AFTER GETTING SAVE BUTTON");
				await saveButton.click();
				BasicService.logMessage("AFTER CLICKING SAVE BUTTON");
				
				await basicService.switchToFrame(DIGITAL_SIGNATURE_FIELD_DETAILS_FRAME_SELECTOR);
				
				BasicService.logMessage("AFTER SWITCHING BACK TO FRAME");
				
			}
			
		}
		
		
		// Create 'Mechanic' option
		{
			
			let mechanicDeactivateOption = await basicService.frame.$(MECHANIC_DEACTIVATE_PICKLIST_OPTION_SELECTOR);
			let mechanicActivateOption = await basicService.frame.$(MECHANIC_ACTIVATE_PICKLIST_OPTION_SELECTOR);
			
			// active Mechanic option exist -> done here
			if (mechanicDeactivateOption) {
				
				BasicService.logMessage("Detected existent active 'Mechanic' option - nothing to do here!");
				
			// inactive Mechanic option exist -> activate
			} else if (mechanicActivateOption) {
				
				BasicService.logMessage("Detected existent inactive 'Mechanic' option - trying to activate it...");
				
				await mechanicActivateOption.click();
				
				BasicService.logMessage("AFTER CLICKING ACTIVATE ON INACTIVE EXISTENT OPTION");
				
				await basicService.page.waitForNavigation({ waitUntil: "networkidle0" });
				
				await basicService.switchToFrame(DIGITAL_SIGNATURE_FIELD_DETAILS_FRAME_SELECTOR);
				mechanicDeactivateOption = await basicService.frame.$(MECHANIC_DEACTIVATE_PICKLIST_OPTION_SELECTOR);
				
				if (mechanicDeactivateOption) {
					BasicService.logMessage("Deactivate link has appeared as prove of successful activation!");
				} else {
					BasicService.logMessage("WARNING: No Deactivate button detected after clicking Activate on existing inactive Mechanic option!");
				}
				
			// no Mechanic option exist -> create new one as active
			} else {
				
				BasicService.logMessage("No Mechanic picklist option exist - trying to create a new one as active...");
				
				let newPicklistOptionButton = await basicService.frame.$(NEW_PICKLIST_OPTION_BUTTON_SELECTOR);
				BasicService.logMessage("AFTER GETTING NEW PICKLIST OPTION BUTTON");
				await newPicklistOptionButton.click();
				BasicService.logMessage("AFTER CLICKING IN NEW PICKLIST OPTION BUTTON");
				
				await basicService.switchToFrame(ADD_PICKLIST_OPTIONS_FRAME_SELECTOR);
				BasicService.logMessage("AFTER SWITCHING TO FRAME");
				
				await basicService.frame.$$eval(
					OPTIONS_INPUT_SELECTOR, 
					inputs => inputs.forEach(el => el.value = "Mechanic")
				);
				BasicService.logMessage("AFTER POPULATING ALL INPUT FIELDS");
				
				let saveButton = await basicService.frame.$(SAVE_BUTTON_SELECTOR);
				BasicService.logMessage("AFTER GETTING SAVE BUTTON");
				await saveButton.click();
				BasicService.logMessage("AFTER CLICKING SAVE BUTTON");
				
				await basicService.switchToFrame(DIGITAL_SIGNATURE_FIELD_DETAILS_FRAME_SELECTOR);
				
				BasicService.logMessage("AFTER SWITCHING BACK TO FRAME");
				
			}
			
		}
		
	} catch(exp) {
		
		BasicService.logMessage("Error happens when creating picklist options:");
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



