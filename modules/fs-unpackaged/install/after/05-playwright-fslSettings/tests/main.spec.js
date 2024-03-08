// @ts-check

const { test, expect } = require((process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../..") + "/scripts/playwright/setup")


const FIELD_SERVICE_SETTINGS_URL = `/lightning/n/FSL__Field_Service_Settings`;

const SERVICE_APPOINTMENT_STATUSES = [
	{	label: "New Service Appointment",						value: "string:None"			},
	{	label: "Service Appointment is tentatively scheduled",	value: "string:Scheduled"		},
	{	label: "Service Appointment is sent to its resource",	value: "string:Dispatched"		},
	{	label: "Service Appointment is in progress",			value: "string:Onsite"			},
	{	label: "Service Appointment is canceled",				value: "string:Canceled"		},
	{	label: "Service Appointment is not completed",			value: "string:Cannot Complete"	},
	{	label: "Service Appointment is completed",				value: "string:Completed"		}
];



/*
test('Generate FSL Permission Sets', async ({ basePage, baseUrl }) => {
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
	// switch to frame
	const frame = basePage.frameLocator('iframe[tabindex="0"]');
	
	// open 'Getting Started' item from config menu
	await frame.getByRole("heading", { name: "Getting Started" }).click();
	
	// switch to 'PERMISSION SETS' tab
	await frame.getByText("PERMISSION SETS").locator('visible=true').click();
	
	// wait for permission sets pannel to appear
	{
		
		const settingButtonLocator = frame.locator('.settingsButton').locator('visible=true');
		const permissionSetOkLocator = frame.locator('.permissionSetOK').locator('visible=true');
		const permissionSetErrorLocator = frame.locator('.permissionSetERROR').locator('visible=true');
		
		await settingButtonLocator.or(permissionSetOkLocator).or(permissionSetErrorLocator).first().waitFor();
		
		console.log(`Permission sets panel has appeared.`);
		
	}
	
	let numberOfPermissionSetsChanged = 0;
	
	// go through permission sets and hit create/update buttons (if any)
	while(true) {
		
		let permissionButtons = await frame.locator('.settingsButton').locator('visible=true').filter({ hasText: /^(Create Permissions)|(Update Permissions)$/i });
		const permissionButtonsCount = await permissionButtons.count();
		
		console.log(`Detected ${permissionButtonsCount} permission buttons to be clicked...`);
		
		if (permissionButtonsCount <= 0) {
			break;
		}
		
		let permissionButton = await permissionButtons.first();
		
		await permissionButton.click();
		
		await frame.locator('.permissionsLoadingContainer').locator('visible=true').first().waitFor({ "state" : "hidden" });
		
		numberOfPermissionSetsChanged++;
		
	}
	
	if (numberOfPermissionSetsChanged > 0) {
		console.log(`${numberOfPermissionSetsChanged} permission sets have been created/updated!`);
	} else {
		console.log(`No permission sets have been created/updated!`);
	}
	
});



test('Configure Service Appointment statuses', async ({ basePage, baseUrl }) => {
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
	// switch to frame
	const frame = basePage.frameLocator('iframe[tabindex="0"]');
	
	// open 'Service Appointment Life Cycle' item from config menu
	await frame.getByText("Service Appointment Life Cycle").locator('visible=true').click();
	
	// switch to 'SA STATUS' tab
	await frame.getByText("SA STATUS").locator('visible=true').click();
	
	
	// iterate over statuses and populate values
	for (let status of SERVICE_APPOINTMENT_STATUSES) {
		await frame.getByLabel(status.label).selectOption(status.value);
	}
	
	
	// click Save button
	await frame.locator('.save-button').locator('visible=true').click();
	
	// wait for success banner to appear
	await frame.locator('.saving-banner.settings-saved').locator('visible=true').waitFor();
	
});
*/


test('Configure Global Actions -> Appointment Booking', async ({ basePage, baseUrl }) => {
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
	// switch to frame
	const frame = basePage.frameLocator('iframe[tabindex="0"]');
	
	// open 'Global Actions' item from config menu
	await frame.getByText("Global Actions").locator('visible=true').click();
	
	// switch to 'APPOINTMENT BOOKING' tab
	await frame.getByText("APPOINTMENT BOOKING").locator('visible=true').click();
	
	await frame.getByLabel("Default scheduling policy").locator('visible=true').selectOption({ label: 'Customer First' });
	
	// TODO - set operating hours based on localization domain: NAA vs EMEA
	//await frame.getByLabel("Default operating hours").selectOption({ label: 'America/New York' });
	//await frame.getByLabel("Default operating hours").selectOption({ label: 'Central European Standard Time' });
	
	await frame.getByLabel("Ideal grading threshold").locator('visible=true').fill('90');
	await frame.getByLabel("Recommended grading threshold ").locator('visible=true').fill('70');
	await frame.getByLabel("Minimum Grade").locator('visible=true').fill('0');
	await frame.getByLabel("Number of hours for initial appointment search").locator('visible=true').fill('72');
	
	await frame.locator('boolean-setting').filter({ hasText: "Show grades explanation" }).getByRole('checkbox').check({ force: true });
	
	await frame.getByLabel("Custom CSS (cascading style sheet)").locator('visible=true').fill('');
	
	await frame.locator('boolean-setting').filter({ hasText: "Disable service territory picker in appointment booking" }).getByRole('checkbox').uncheck({ force: true });
	await frame.locator('boolean-setting').filter({ hasText: "Pin three highest graded time slots to the top" }).getByRole('checkbox').uncheck({ force: true });
	await frame.locator('boolean-setting').filter({ hasText: "Open extended view by default" }).getByRole('checkbox').check({ force: true });
	
	
	// click Save button
	await frame.locator('.save-button').locator('visible=true').click();
	
	// wait for success banner to appear
	await frame.locator('.saving-banner.settings-saved').locator('visible=true').waitFor();
	
});


