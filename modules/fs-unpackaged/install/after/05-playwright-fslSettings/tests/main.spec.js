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



test('Generate FSL Permission Sets', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Getting Started");
	
	await switchToSettingsTab(frame, "PERMISSION SETS");
	
	
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



test('Service Appointment Life Cycle -> Creation', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Service Appointment Life Cycle");
	
	await switchToSettingsTab(frame, "CREATION");
	
	await checkBooleanSetting(frame, "Derive the Service Appointment due date from its Work Type");
	await checkBooleanSetting(frame, "Prevent update of pinned, or unmovable, Service Appointments");
	await checkBooleanSetting(frame, "Set your default Service Appointment duration to one hour");
	await checkBooleanSetting(frame, "Use polygons to assign service territories");
	
	await clickSaveSettingButton(frame);
	
	// NOTE: "Territory assignment policy" picklist appears only after setting "Use polygons to assign service territories" checkbox and saving settings
	await selectPicklistSettingByLabel(frame, "Territory assignment policy", "Highest Level");
	
	await clickSaveSettingButton(frame);
	
});



test('Service Appointment Life Cycle -> SA Status', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Service Appointment Life Cycle");
	
	await switchToSettingsTab(frame, "SA STATUS");
	
	
	// iterate over statuses and populate values
	for (let status of SERVICE_APPOINTMENT_STATUSES) {
		await selectPicklistSettingByValue(frame, status.label, status.value);
	}
	
	
	await clickSaveSettingButton(frame);
	
});



test('Configure Global Actions -> Appointment Booking', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Global Actions");
	
	await switchToSettingsTab(frame, "APPOINTMENT BOOKING");
	
	await selectPicklistSettingByLabel(frame, "Default scheduling policy", "Customer First");
	
	// TODO - set operating hours based on localization domain: NAA vs EMEA
	//await selectPicklistSettingByLabel(frame, "Default operating hours", "America/New York");
	//await selectPicklistSettingByLabel(frame, "Default operating hours", "Central European Standard Time");
	
	await fillSetting(frame, "Ideal grading threshold", 90);
	await fillSetting(frame, "Recommended grading threshold", 70);
	await fillSetting(frame, "Minimum Grade", 0);
	await fillSetting(frame, "Number of hours for initial appointment search", 72);
	
	await checkBooleanSetting(frame, "Show grades explanation");
	
	await fillSetting(frame, "Custom CSS (cascading style sheet)", '');
	
	await uncheckBooleanSetting(frame, "Disable service territory picker in appointment booking");
	await uncheckBooleanSetting(frame, "Pin three highest graded time slots to the top");
	await checkBooleanSetting(frame, "Open extended view by default");
	
	
	await clickSaveSettingButton(frame);
	
});



test('Configure Global Actions -> Emergency Wizard', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Global Actions");
	
	await switchToSettingsTab(frame, "EMERGENCY WIZARD");
	
	// TODO - which policy should be selected here, currently it is just empty
	//await selectPicklistSettingByLabel(frame, "Emergency scheduling policy", "Customer First");
	
	await fillSetting(frame, "Last known location validity", 20);
	await fillSetting(frame, "Ideal availability grade", 30);
	await fillSetting(frame, "Good availability grade", 60);
	await fillSetting(frame, "Emergency search timeframe", 360);
	
	await checkBooleanSetting(frame, "Allow Chatter post");
	
	await selectPicklistSettingByLabel(frame, "Emergency Chatter Post Destination", "Parent Record Feed");
	
	await uncheckBooleanSetting(frame, "Pin After Dispatch");
	
	
	await clickSaveSettingButton(frame);
	
});



const openSettings = async (basePage, baseUrl) => {
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
}


const getMainFrame = (basePage) => {
	
	return basePage.frameLocator('iframe[tabindex="0"]');
	
}


const switchToSettingsMenu = async (frame, menuLabel) => {
	
	await frame.locator('#SettingsMenu').getByText(menuLabel).locator('visible=true').click();
	
}


const switchToSettingsTab = async (frame, tabLabel) => {
	
	await frame.getByText(tabLabel).locator('visible=true').click();
	
}


const checkBooleanSetting = async (frame, label) => {
	
	await frame.locator('boolean-setting').filter({ hasText: label }).getByRole('checkbox').check({ force: true });
	
}


const uncheckBooleanSetting = async (frame, label) => {
	
	await frame.locator('boolean-setting').filter({ hasText: label }).getByRole('checkbox').uncheck({ force: true });
	
}


const selectPicklistSettingByLabel = async (frame, label, optionLabel) => {
	
	await frame.getByLabel(label).locator('visible=true').selectOption({ label: optionLabel });
	
}


const selectPicklistSettingByValue = async (frame, label, optionValue) => {
	
	await frame.getByLabel(label).locator('visible=true').selectOption(optionValue);
	
}


const fillSetting = async (frame, label, value) => {
	
	await frame.getByLabel(label).locator('visible=true').fill(value ? String(value) : '');
	
}


const clickSaveSettingButton = async (frame) => {
	
	// click Save button
	await frame.locator('.save-button').locator('visible=true').click();
	
	// wait for success banner to appear
	await frame.locator('.saving-banner.settings-saved').locator('visible=true').waitFor();
	
}


