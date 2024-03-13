// @ts-check

const basePath = (process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../../..");

const { test, expect } = require(basePath + "/scripts/playwright/setup");
const utils = require(basePath + "/scripts/playwright/utils");


const SERVICE_APPOINTMENT_STATUSES = [
	{	label: "New Service Appointment",						value: "string:None"			},
	{	label: "Service Appointment is tentatively scheduled",	value: "string:Scheduled"		},
	{	label: "Service Appointment is sent to its resource",	value: "string:Dispatched"		},
	{	label: "Service Appointment is in progress",			value: "string:Onsite"			},
	{	label: "Service Appointment is canceled",				value: "string:Canceled"		},
	{	label: "Service Appointment is not completed",			value: "string:Cannot Complete"	},
	{	label: "Service Appointment is completed",				value: "string:Completed"		}
];



test('Service Appointment Life Cycle -> Creation', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Service Appointment Life Cycle");
	
	await utils.switchToSettingsTab(frame, "CREATION");
	
	await utils.checkBooleanSetting(frame, "Derive the Service Appointment due date from its Work Type");
	await utils.checkBooleanSetting(frame, "Prevent update of pinned, or unmovable, Service Appointments");
	await utils.checkBooleanSetting(frame, "Set your default Service Appointment duration to one hour");
	await utils.checkBooleanSetting(frame, "Use polygons to assign service territories");
	
	await utils.clickSaveSettingButton(frame);
	
	// NOTE: "Territory assignment policy" picklist appears only after setting "Use polygons to assign service territories" checkbox and saving settings
	await utils.selectPicklistSettingByLabel(frame, "Territory assignment policy", "Highest Level");
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Service Appointment Life Cycle -> SA Status', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Service Appointment Life Cycle");
	
	await utils.switchToSettingsTab(frame, "SA STATUS");
	
	
	// iterate over statuses and populate values
	for (let status of SERVICE_APPOINTMENT_STATUSES) {
		await utils.selectPicklistSettingByValue(frame, status.label, status.value);
	}
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Global Actions -> Appointment Booking', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Global Actions");
	
	await utils.switchToSettingsTab(frame, "APPOINTMENT BOOKING");
	
	await utils.selectPicklistSettingByLabel(frame, "Default scheduling policy", "Customer First");
	
	// TODO - set operating hours based on localization domain: NAA vs EMEA
	//await utils.selectPicklistSettingByLabel(frame, "Default operating hours", "America/New York");
	//await utils.selectPicklistSettingByLabel(frame, "Default operating hours", "Central European Standard Time");
	
	await utils.fillSetting(frame, "Ideal grading threshold", 90);
	await utils.fillSetting(frame, "Recommended grading threshold", 70);
	await utils.fillSetting(frame, "Minimum Grade", 0);
	await utils.fillSetting(frame, "Number of hours for initial appointment search", 72);
	
	await utils.checkBooleanSetting(frame, "Show grades explanation");
	
	await utils.fillSetting(frame, "Custom CSS (cascading style sheet)", '');
	
	await utils.uncheckBooleanSetting(frame, "Disable service territory picker in appointment booking");
	await utils.uncheckBooleanSetting(frame, "Pin three highest graded time slots to the top");
	await utils.checkBooleanSetting(frame, "Open extended view by default");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Global Actions -> Emergency Wizard', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Global Actions");
	
	await utils.switchToSettingsTab(frame, "EMERGENCY WIZARD");
	
	// TODO - which policy should be selected here, currently it is just empty
	//await utils.selectPicklistSettingByLabel(frame, "Emergency scheduling policy", "Customer First");
	
	await utils.fillSetting(frame, "Last known location validity", 20);
	await utils.fillSetting(frame, "Ideal availability grade", 30);
	await utils.fillSetting(frame, "Good availability grade", 60);
	await utils.fillSetting(frame, "Emergency search timeframe", 360);
	
	await utils.checkBooleanSetting(frame, "Allow Chatter post");
	
	await utils.selectPicklistSettingByLabel(frame, "Emergency Chatter Post Destination", "Parent Record Feed");
	
	await utils.uncheckBooleanSetting(frame, "Pin After Dispatch");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Scheduling -> General Logic', async ({ basePage, baseUrl }) => {
	
	const GENERAL_LOGIC_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Cannot Complete", 
			"Completed"
		]
	);
	
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Scheduling");
	
	await utils.switchToSettingsTab(frame, "General Logic");
	
	await utils.selectPicklistSettingByLabel(frame, "Multiday service appointment field", "Is MultiDay");
	await utils.uncheckBooleanSetting(frame, "Set the hour that starts a new day based on the Availability rule(s)");
	await utils.fillSetting(frame, "Maximum days to get candidates or to book an appointment", 10);
	
	await utils.checkBooleanSetting(frame, "Delay auto-scheduling until appointments are geocoded");
	await utils.checkBooleanSetting(frame, "Activate Approval confirmation on resource absences");
	await utils.uncheckBooleanSetting(frame, "Enable resource crew skill grouping");
	await utils.checkBooleanSetting(frame, "Avoid aerial calculation upon callout DML exception");
	await utils.uncheckBooleanSetting(frame, "Respect secondary STM operating hours");
	
	
	await utils.setCheckboxesInGroup(
		frame,
		frame.locator("scheduling-logic")
			.locator("#pinned-status-container")
		,
		{
			labelsToCheck: GENERAL_LOGIC_PINNED_STATUSES 
		}
	);
	
	
	await utils.selectPicklistSettingByLabel(frame, "Work Order Priority Field", "None");
	await utils.selectPicklistSettingByLabel(frame, "Work Order Line Item Priority Field", "None");
	await utils.selectPicklistSettingByLabel(frame, "Service Appointment Priority Field", "Priority");
	
	await utils.checkBooleanSetting(frame, "Use 1-100 priority scale");
	
	await utils.checkBooleanSetting(frame, "Enable complex work");
	await utils.uncheckBooleanSetting(frame, "Use all-or-none scheduling for related appointments");
	
	await utils.uncheckBooleanSetting(frame, "Set Apex operation timeout limits");
	
	await utils.fillSetting(frame, "Timeout Limit for Get Candidates (Percent) ", 95);
	await utils.fillSetting(frame, "Timeout Limit for Appointment Booking (Percent)", 95);
	await utils.fillSetting(frame, "Timeout Limit for Scheduling (Percent)", 90);
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Scheduling -> Dynamic Gantt', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Scheduling");
	
	await utils.switchToSettingsTab(frame, "Dynamic Gantt");
	
	
	await utils.selectPicklistSettingByLabel(frame, "When attempting to fix overlaps", "Schedule to original resource only");
	await utils.selectPicklistSettingByLabel(frame, "After unscheduling services reschedule them by", "Chronological Order");
	await utils.selectPicklistSettingByLabel(frame, "When unable to find a valid schedule for an appointment", "Leave on Gantt and set In-jeopardy");
	
	
	// 'Fill-in Schedule' section
	{
		
		const fillInScheduleSectionLocator = frame.locator(":below(:text('Fill-in Schedule'))").and(frame.locator(":above(:text('Group Nearby Appointments'))"));
		
		await utils.selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Service Appointment candidate Boolean field", "Is Fill In Candidate");
		await utils.selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Work Order candidate Boolean field", "Is Fill In Candidate");
		await utils.selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Work Order Line Item candidate Boolean field", "Is Fill In Candidate");
		await utils.selectPicklistSettingByLabel(fillInScheduleSectionLocator, "Order candidate appointments by", "Priority");
		
		await utils.fillSetting(fillInScheduleSectionLocator, "Max appointments to schedule", 50);
		await utils.fillSetting(fillInScheduleSectionLocator, "Max runtime (seconds)", 20);
		
	}
	
	
	// 'Group Nearby Appointments' section
	{
		
		const groupNearbyAppointmentsSectionLocator = frame.locator(":below(:text('Group Nearby Appointments'))");
		
		await utils.selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "Service Appointment candidate Boolean field", "Is Fill In Candidate");
		await utils.selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "Work Order candidate Boolean field", "Is Fill In Candidate");
		await utils.selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "Work Order Line Item candidate Boolean field", "Is Fill In Candidate");
		
		await utils.fillSetting(groupNearbyAppointmentsSectionLocator, "Max appointments to schedule", 50);
		await utils.fillSetting(groupNearbyAppointmentsSectionLocator, "Max runtime (seconds)", 20);
		
		await utils.selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "When attempting to schedule the unscheduled service after the nearby services", "Schedule to original resource only");
		await utils.selectPicklistSettingByLabel(groupNearbyAppointmentsSectionLocator, "When unable to arrange schedule", "Leave on Gantt and set In-jeopardy");
		
		await utils.fillSetting(groupNearbyAppointmentsSectionLocator, "Radius for nearby appointments", 1);
		
	}
	
	
	await utils.fillSetting(frame, "Max time horizon (days) in which the appointment can be scheduled", 7);
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Scheduling -> Routing', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Scheduling");
	
	await utils.switchToSettingsTab(frame, "Routing");
	
	// checkboxes should be set in this precised order due - they are dependendant
	await utils.uncheckBooleanSetting(frame, "Enable Point-to-Point Predictive Routing");
	await utils.checkBooleanSetting(frame, "Enable Street Level Routing");
	await utils.uncheckOptinalBooleanSetting(frame, "Enable Predictive Travel for optimization services");
	
	await utils.checkBooleanSetting(frame, "Calculate travel and breaks");
	
	await utils.selectPicklistSettingByLabel(frame, "Travel speed unit", "KM/h");
	
	await utils.fillSetting(frame, "Default travel speed", 50);
	
	await utils.checkBooleanSetting(frame, "Show map");
	await utils.checkBooleanSetting(frame, "Show street level routing in the Service Resource map tab");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Optimization -> Logic', async ({ basePage, baseUrl }) => {
	
	const GLOBAL_OPTIMIZATION_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Enroute", 
			"Onsite",
			"Canceled",
			"Cannot Complete",
			"Completed"
		]
	);
	
	const RESOURCE_OPTIMIZATION_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Enroute", 
			"Onsite",
			"Canceled",
			"Cannot Complete",
			"Completed"
		]
	);
	
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Optimization");
	
	await utils.switchToSettingsTab(frame, "Logic");
	
	await utils.checkBooleanSetting(frame, "Enable optimization overlaps prevention");
	await utils.checkBooleanSetting(frame, "Mark optimization requests failed when failing due to org customizations");
	await utils.uncheckBooleanSetting(frame, "Enable sharing for Optimization request");
	
	await utils.selectPicklistSettingByLabel(frame, "Optimization run time per service appointment", "High");
	
	
	// 'Global Optimization' section
	{
		
		await utils.setCheckboxesInGroup(
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
		
		await utils.setCheckboxesInGroup(
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
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Dispatch -> Drip Feed', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Dispatch");
	
	await utils.switchToSettingsTab(frame, "Drip Feed");
	
	await utils.uncheckBooleanSetting(frame, "Enable drip feed dispatching");
	
	await utils.fillSetting(frame, "Service Appointments to Dispatch", 2);
	
	
	await utils.clickSaveSettingButton(frame);
	
});



const APPS_TO_RELAX_IP = [ 
	"Salesforce Field Service for Android", 
	"Salesforce Field Service for iOS" 
];

for (
	const appToRelaxIp 
	of 
	APPS_TO_RELAX_IP
) {
	
	test(`Setup -> App Manager ->  -> IP Relaxation for ${appToRelaxIp} apps`, async ({ basePage, baseUrl }) => {
		
		await basePage.goto(baseUrl + '/lightning/setup/NavigationMenus/home');
		
		const appsTable = basePage
			.locator("table")
			.filter({ has: basePage.getByText("Developer Name") });
			
		const appsTableSecondRow = appsTable.locator('tr').nth(2);
		
		await appsTableSecondRow.hover();
		
		await basePage.mouse.wheel(0, +20);
		
		await appsTable
			.getByRole("row")
			.filter({ hasText: appToRelaxIp })
			.getByRole('button')
			.click({ force: true });
		
		await utils.clickMenuItem(basePage, "Manage");
		
		const frame = basePage.frameLocator("iframe[tabindex='0'][title^='Connected App']");
		
		await utils.clickButton(frame, "Edit Policies");
		console.log("Opened Edit Policies");
		
		await utils.selectPicklistSettingByLabel(frame, "IP Relaxation", "Relax IP restrictions");
		
		await utils.clickButton(frame, "Save");
		
		await utils.waitForButton(frame, "Edit Policies");
		
	});
	
}



test(`Contract Line Item -> Edit Multi-Line Layout`, async ({ basePage, baseUrl }) => {
	
	const FIELDS_LABELS_TO_SELECT = [ 
		"Sales Contract Line Item",
		"Type"
	];
	
	
	await basePage.goto(baseUrl + '/lightning/setup/ObjectManager/ContractLineItem/PageLayouts/view');
	
	await basePage
		.locator("table")
		.filter({ has: basePage.getByText("Page Layout Name") })
		.getByText("Contract Line Item Layout")
		.click();
	
	let frame = utils.getMainFrameWithTitlePrefix(basePage, "Edit Page Layout");
	
	await utils.clickLink(frame, "Edit Multi-Line Layout");
	
	frame = utils.getMainFrameWithTitleContains(basePage, "Contract Line Item Multi-Line Layout");
	
	
	let availableOptions = await utils.getPicklistOptions(frame, 'Available Fields');
	console.log(`Available Fields: ${availableOptions}`);
	
	let selectedOptions = await utils.getPicklistOptions(frame, 'Selected Fields');
	console.log(`Selected Fields: ${selectedOptions}`);
	
	
	for (const fieldLabelToSelect of FIELDS_LABELS_TO_SELECT) {
		
		if (availableOptions.includes(fieldLabelToSelect)) {
			
			console.log(`Field '${fieldLabelToSelect}' is available to select.`);
			
			await utils.selectPicklistSettingByLabel(frame, "Available Fields", fieldLabelToSelect);
			await utils.clickLink(frame, "Add");
			
			console.log(`Selected successfully field '${fieldLabelToSelect}'!`);
			
		} else if (selectedOptions.includes(fieldLabelToSelect)) {
			
			console.log(`Field '${fieldLabelToSelect}' is already selected!`);
			
		} else {
			
			console.log(`WARNING: No field '${fieldLabelToSelect}' available to select!`);
			
		}
		
	}
	
	await utils.clickButton(frame, "Save");
	
	frame = utils.getMainFrameWithTitlePrefix(basePage, "Edit Page Layout");
	await utils.waitForLink(frame, "Edit Multi-Line Layout");
	
});


