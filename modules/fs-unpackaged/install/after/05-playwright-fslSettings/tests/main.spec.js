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



test('Global Actions -> Appointment Booking', async ({ basePage, baseUrl }) => {
	
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



test('Global Actions -> Emergency Wizard', async ({ basePage, baseUrl }) => {
	
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



test('Scheduling -> General Logic', async ({ basePage, baseUrl }) => {
	
	const GENERAL_LOGIC_PINNED_STATUSES = new CaseInsensitiveSet(
		[ 
			"Cannot Complete", 
			"Completed"
		]
	);
	
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Scheduling");
	
	await switchToSettingsTab(frame, "General Logic");
	
	await selectPicklistSettingByLabel(frame, "Multiday service appointment field", "Is MultiDay");
	await checkBooleanSetting(frame, "Set the hour that starts a new day based on the Availability rule(s)");
	await fillSetting(frame, "Maximum days to get candidates or to book an appointment", 10);
	
	await checkBooleanSetting(frame, "Delay auto-scheduling until appointments are geocoded");
	await checkBooleanSetting(frame, "Activate Approval confirmation on resource absences");
	await uncheckBooleanSetting(frame, "Enable resource crew skill grouping");
	await checkBooleanSetting(frame, "Avoid aerial calculation upon callout DML exception");
	await uncheckBooleanSetting(frame, "Respect secondary STM operating hours");
	
	
	await setCheckboxesInGroup(
		frame,
		frame.locator("scheduling-logic")
			.locator("#pinned-status-container")
		,
		{
			labelsToCheck: GENERAL_LOGIC_PINNED_STATUSES 
		}
	);
	
	
	await selectPicklistSettingByLabel(frame, "Work Order Priority Field", "None");
	await selectPicklistSettingByLabel(frame, "Work Order Line Item Priority Field", "None");
	await selectPicklistSettingByLabel(frame, "Service Appointment Priority Field", "Priority");
	
	await checkBooleanSetting(frame, "Use 1-100 priority scale");
	
	await checkBooleanSetting(frame, "Enable complex work");
	await uncheckBooleanSetting(frame, "Use all-or-none scheduling for related appointments");
	
	await uncheckBooleanSetting(frame, "Set Apex operation timeout limits");
	
	await fillSetting(frame, "Timeout Limit for Get Candidates (Percent) ", 95);
	await fillSetting(frame, "Timeout Limit for Appointment Booking (Percent)", 95);
	await fillSetting(frame, "Timeout Limit for Scheduling (Percent)", 90);
	
	
	await clickSaveSettingButton(frame);
	
});



test('Scheduling -> Dynamic Gantt', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Scheduling");
	
	await switchToSettingsTab(frame, "Dynamic Gantt");
	
	
	await selectPicklistSettingByLabel(frame, "When attempting to fix overlaps", "Schedule to original resource only");
	await selectPicklistSettingByLabel(frame, "After unscheduling services reschedule them by", "Chronological Order");
	await selectPicklistSettingByLabel(frame, "When unable to find a valid schedule for an appointment", "Leave on Gantt and set In-jeopardy");
	
	
	// 'Fill-in Schedule' section
	{
		
		const fillInScheduleSectionLocator = frame.locator(":below(:text('Fill-in Schedule'))").and(frame.locator(":above(:text('Group Nearby Appointments'))"));
		
		await selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Service Appointment candidate Boolean field", "Is Fill In Candidate");
		await selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Work Order candidate Boolean field", "Is Fill In Candidate");
		await selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Work Order Line Item candidate Boolean field", "Is Fill In Candidate");
		await selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Order candidate appointments by", "Priority");
		
		await fillSetting(fillInScheduleSectionLocator, "Max appointments to schedule", 50);
		await fillSetting(fillInScheduleSectionLocator, "Max runtime (seconds)", 20);
		
	}
	
	
	// 'Group Nearby Appointments' section
	{
		
		const groupNearbyAppointmentsSectionLocator = frame.locator(":below(:text('Group Nearby Appointments'))");
		
		await selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "Service Appointment candidate Boolean field", "Is Fill In Candidate");
		await selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "Work Order candidate Boolean field", "Is Fill In Candidate");
		await selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "Work Order Line Item candidate Boolean field", "Is Fill In Candidate");
		
		await fillSetting(groupNearbyAppointmentsSectionLocator, "Max appointments to schedule", 50);
		await fillSetting(groupNearbyAppointmentsSectionLocator, "Max runtime (seconds)", 20);
		
		await selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "When attempting to schedule the unscheduled service after the nearby services", "Schedule to original resource only");
		await selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "When unable to arrange schedule", "Leave on Gantt and set In-jeopardy");
		
		await fillSetting(groupNearbyAppointmentsSectionLocator, "Radius for nearby appointments", 1);
		
	}
	
	
	await fillSetting(frame, "Max time horizon (days) in which the appointment can be scheduled", 7);
	
	
	await clickSaveSettingButton(frame);
	
});



test('Scheduling -> Routing', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Scheduling");
	
	await switchToSettingsTab(frame, "Routing");
	
	// checkboxes should be set in this precised order due - they are dependendant
	await uncheckBooleanSetting(frame, "Enable Point-to-Point Predictive Routing");
	await checkBooleanSetting(frame, "Enable Street Level Routing");
	await uncheckOptinalBooleanSetting(frame, "Enable Predictive Travel for optimization services");
	
	await checkBooleanSetting(frame, "Calculate travel and breaks");
	
	await selectPicklistSettingByLabel(frame, "Travel speed unit", "KM/h");
	
	await fillSetting(frame, "Default travel speed", 35);
	
	await checkBooleanSetting(frame, "Show map");
	await checkBooleanSetting(frame, "Show street level routing in the Service Resource map tab");
	
	
	await clickSaveSettingButton(frame);
	
});



test('Optimization -> Logic', async ({ basePage, baseUrl }) => {
	
	const GLOBAL_OPTIMIZATION_PINNED_STATUSES = new CaseInsensitiveSet(
		[ 
			"Enroute", 
			"Onsite",
			"Canceled",
			"Cannot Complete",
			"Completed"
		]
	);
	
	const RESOURCE_OPTIMIZATION_PINNED_STATUSES = new CaseInsensitiveSet(
		[ 
			"Enroute", 
			"Onsite",
			"Canceled",
			"Cannot Complete",
			"Completed"
		]
	);
	
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Optimization");
	
	await switchToSettingsTab(frame, "Logic");
	
	await checkBooleanSetting(frame, "Enable optimization overlaps prevention");
	await checkBooleanSetting(frame, "Mark optimization requests failed when failing due to org customizations");
	await uncheckBooleanSetting(frame, "Enable sharing for Optimization request");
	
	await selectPicklistSettingByLabel(frame, "Optimization run time per service appointment", "High");
	
	
	// 'Global Optimization' section
	{
		
		await setCheckboxesInGroup(
			frame,
			frame.locator("optimization-logic")
				.locator("#pinned-status-container")
				.and(
					frame.locator(":below(:text('Global Optimization'))")
				)
				.and(
					frame.locator(":above(:text('In-Day and Resource Schedule Optimization'))")
				)
			,
			{
				labelsToCheck: GLOBAL_OPTIMIZATION_PINNED_STATUSES 
			}
		);
		
	}
	
	
	// 'In-Day and Resource Schedule Optimization' section
	{
		
		await setCheckboxesInGroup(
			frame,
			frame.locator("optimization-logic")
				.locator("#pinned-status-container")
				.and(
					frame.locator(":below(:text('In-Day and Resource Schedule Optimization'))")
				)
			,
			{
				labelsToCheck: RESOURCE_OPTIMIZATION_PINNED_STATUSES 
			}
		);
		
	}
	
	
	await clickSaveSettingButton(frame);
	
});



test('Dispatch -> Drip Feed', async ({ basePage, baseUrl }) => {
	
	await openSettings(basePage, baseUrl);
	
	const frame = getMainFrame(basePage);
	
	await switchToSettingsMenu(frame, "Dispatch");
	
	await switchToSettingsTab(frame, "Drip Feed");
	
	await uncheckBooleanSetting(frame, "Enable drip feed dispatching");
	
	await fillSetting(frame, "Service Appointments to Dispatch", 2);
	
	
	await clickSaveSettingButton(frame);
	
});



const openSettings = async (basePage, baseUrl) => {
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
}


const getMainFrame = (basePage) => {
	
	return basePage.frameLocator('iframe[tabindex="0"]');
	
}


const switchToSettingsMenu = async (root, menuLabel) => {
	
	await root.locator('#SettingsMenu').getByText(menuLabel, { exact: true }).locator('visible=true').click();
	
}


const switchToSettingsTab = async (root, tabLabel) => {
	
	await root.getByText(tabLabel).locator('visible=true').click();
	
}


const getBooleanSettingLocator = (root, label) => {
	
	const booleanSettingLocator = root.locator('boolean-setting');
	const booleanTextSettingLocator = root.locator('boolean-text-setting');
	
	return booleanSettingLocator.or(booleanTextSettingLocator).filter({ hasText: label });
	
}


const checkBooleanSetting = async (root, label) => {
	
	await getBooleanSettingLocator(root, label).getByRole('checkbox').check({ force: true });
	
}


const checkOptinalBooleanSetting = async (root, label) => {
	
	if (await getBooleanSettingLocator(root, label).isVisible()) {
		
		await checkBooleanSetting(root, label);
		
	} else {
		
		console.log(`WARNING: Optional boolean settings '${label}' not available!`);
		
	}
	
}


const uncheckBooleanSetting = async (root, label) => {
	
	await getBooleanSettingLocator(root, label).getByRole('checkbox').uncheck({ force: true });
	
}


const uncheckOptinalBooleanSetting = async (root, label) => {
	
	if (await getBooleanSettingLocator(root, label).isVisible()) {
		
		await uncheckBooleanSetting(root, label);
		
	} else {
		
		console.log(`WARNING: Optional boolean settings '${label}' not available!`);
		
	}
	
}


const selectPicklistSettingByLabel = async (root, label, optionLabel) => {
	
	await root.getByLabel(label).locator('visible=true').selectOption({ label: optionLabel });
	
}


const selectPicklistSettingByValue = async (root, label, optionValue) => {
	
	await root.getByLabel(label).locator('visible=true').selectOption(optionValue);
	
}


const fillSetting = async (root, label, value) => {
	
	await root.getByLabel(label).locator('visible=true').fill(value ? String(value) : '');
	
}


const setCheckboxesInGroup = async (root, container, { resetAll = true, labelsToCheck = new Set(), labelsToUncheck = new Set() } = { resetAll: true }) => {
	
	let checkboxesLocator = container.locator('label');
	await checkboxesLocator.first().waitFor();
	
	checkboxesLocator = await checkboxesLocator.filter({ has: root.getByRole('checkbox').locator('visible=true') });
	console.log(`Found ${await checkboxesLocator.count()} checkboxes in group`);
	
	for (const checkboxLocator of await checkboxesLocator.all()) {
		
		const checkboxLabel = (await checkboxLocator.textContent()).trim();
		console.log(`Checking checkbox ${checkboxLabel}`);
		
		if (labelsToCheck.has(checkboxLabel)) {
			
			await checkboxLocator.getByRole('checkbox').check({ force: true });
			
		} else if (labelsToUncheck.has(checkboxLabel)) {
			
			await checkboxLocator.getByRole('checkbox').uncheck({ force: true });
			
		} else if (resetAll === true) {
			
			await checkboxLocator.getByRole('checkbox').uncheck({ force: true });
		}
		
	}
	
}


const clickSaveSettingButton = async (root) => {
	
	// click Save button
	await root.locator('.save-button').locator('visible=true').click();
	
	// wait for success banner to appear
	await root.locator('.saving-banner.settings-saved').locator('visible=true').waitFor();
	
}


class CaseInsensitiveSet extends Set {
	
	constructor(values) {
		super(
			Array.from(
				values, it => String(it).trim().toLowerCase()
			)
		);
	}
	
	add(value) {
		return super.add(String(value).trim().toLowerCase());
	}
	
	has(value) {
		return super.has(String(value).trim().toLowerCase());
	}
	
	delete(value) {
		return super.delete(String(value).trim().toLowerCase());
	}
	
}

