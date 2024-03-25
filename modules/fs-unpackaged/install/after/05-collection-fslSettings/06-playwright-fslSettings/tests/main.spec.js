// @ts-check

const path = require("path");

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


/*
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
	
	await utils.selectPicklistSettingByLabel(frame, "Emergency scheduling policy", "Emergency");
	
	await utils.fillSetting(frame, "Last known location validity", 20);
	await utils.fillSetting(frame, "Ideal availability grade", 30);
	await utils.fillSetting(frame, "Good availability grade", 60);
	await utils.fillSetting(frame, "Emergency search timeframe", 120);
	
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



test('Optimization -> Scheduled Jobs', async ({ basePage, baseUrl }) => {
	
	const TARGET_JOB_NAME = "Optimization";
	const TARGET_AUTOMATOR_TYPE = "Optimization";
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Optimization");
	
	await utils.switchToSettingsTab(frame, "Scheduled Jobs");
	
	
	// define locators
	
	const jobsSectionLocator = frame.locator('optimization-jobs-enhancements');
	const jobsSectionButtonsLocator = jobsSectionLocator.locator('.automatorButton.settingsButton');
	const jobsSectionNewButtonLocator = jobsSectionButtonsLocator.filter({ hasText: "New Job" });
	const jobsSectionEditButtonLocator = jobsSectionButtonsLocator.filter({ hasText: "Edit" });
	
	const jobTimeControl = jobsSectionLocator.locator(".automatorTimeSpan");
	const jobTimeHourControl = jobTimeControl.filter({ hasText: "Hour" }).locator(".timeSpanInput input");
	const jobTimeMinuteControl = jobTimeControl.filter({ hasText: "Minute" }).locator(".timeSpanInput input");
	
	const targetJobTextLocator = frame.getByText(TARGET_JOB_NAME, { exact: true });
	const jobNameCellLocator = frame.locator(".automatorEnhancementsName");
	const targetJobNameCellLocator = jobNameCellLocator.filter({ has: targetJobTextLocator });
	const targetJobRowLocator = frame.locator(".automatorRowEnhancements").filter({ has: targetJobNameCellLocator });
	const targetJobActionsLocator = targetJobRowLocator.locator(".automatorEnhancementsAction");
	const targetJobStatusToggleLocator = targetJobActionsLocator.locator("checkbox");
	const targetJobStatusLocator = targetJobActionsLocator.locator(".automatorEnhancementsActive");
	
	const newJobPopupLocator = frame.locator('.settingsPopup');
	
	
	await jobsSectionNewButtonLocator.waitFor();
	
	let doesScheduledJobExist = false;
	
	// detect by name if target scheduled job exists
	if (await jobsSectionEditButtonLocator.isVisible()) {
		
		console.log("Some scheduled jobs are present already.");
		
		if (await targetJobNameCellLocator.isVisible()) {
			
			console.log(`Scheduled job with name '${TARGET_JOB_NAME}' already exists.`);
			
			doesScheduledJobExist = true;
			
		} else {
			
			console.log(`Scheduled job with name '${TARGET_JOB_NAME}' does NOT exist.`);
			
		}
		
	} else {
		
		console.log("No Scheduled jobs available at all.");
		
	}
	
	
	// create target scheduled job with predefined name (if not exist)
	if (doesScheduledJobExist === false) {
		
		console.log(`Creating scheduled job with name '${TARGET_JOB_NAME}'...`);
		
		await jobsSectionNewButtonLocator.click();
		
		await utils.fillSetting(newJobPopupLocator, 'Name', TARGET_JOB_NAME);
		await utils.selectPicklistSettingByLabel(newJobPopupLocator, 'Automator type', TARGET_AUTOMATOR_TYPE);
		
		await utils.clickByText(newJobPopupLocator, 'Save');
		
		await utils.clickSaveSettingButton(frame);
		
		console.log(`Scheduled job with name '${TARGET_JOB_NAME}' has been created.`);
		
	}
	
	
	// updating parameters of target scheduled job
	{
		
		console.log("Tweaking further scheduled job parameters...");
		
		//await utils.clickByTitle(targetJobNameCellLocator, "Expand job");
		await utils.clickByText(targetJobNameCellLocator, "+");
		
		await utils.setRadio(frame, "Recurring");
		
		await utils.setCheckboxes(frame, [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ]);
		
		await utils.setRadio(frame, "Day of week");
		
		await utils.setCheckboxes(frame, [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ]);
		
		await utils.setRadio(frame, "Specific Hour");
		
		await jobTimeHourControl.fill(String(21));
		await jobTimeMinuteControl.fill(String(0));
		
		await utils.clickByText(frame, "All");
		
		await utils.fillSetting(frame, "Time Horizon in days", 30);
		
		await utils.selectPicklistSettingByLabel(frame, "Filter by criteria", "None");
		await utils.selectPicklistSettingByLabel(frame, "Scheduling Policy", "Customer First");
		
		await utils.fillSetting(frame, "Email recipient user name", '');
		
		await utils.clickSaveSettingButton(frame);
		
		// activate job if not already
		{
			
			let jobCurrentStatus = await targetJobStatusLocator.textContent();
			console.log(`Current status of '${TARGET_JOB_NAME}' job: ${jobCurrentStatus}`);
			
			if (utils.isEquivalent(jobCurrentStatus, 'Inactive')) {
				await targetJobStatusToggleLocator.click({ force: true });
			}
			
			await utils.clickSaveSettingButton(frame);
			
		}
		
	}
	
	
	// re-entering settings page and Scheduled Jobs tab to select All territories again and save (due to some issue or weird behaviour)
	{
		
		await utils.openSettings(basePage, baseUrl);
		
		await utils.switchToSettingsMenu(frame, "Optimization");
		
		await utils.switchToSettingsTab(frame, "Scheduled Jobs");
		
		console.log("Tweaking further scheduled job parameters...");
		
		await utils.clickByText(targetJobNameCellLocator, "+");
		
		await utils.clickByText(frame, "All");
		
		await utils.clickSaveSettingButton(frame);
		
		await utils.clickByText(targetJobActionsLocator, "Run Now");
		
		// try to run job suppressing failure if any (just logging error)
		try {
			
			await targetJobActionsLocator.locator(".automatorRunNowDone").waitFor();
			console.log(`Scheduled job '${TARGET_JOB_NAME}' execution has succeeded.`);
			
		} catch (exp) {
			
			console.log(`WARNING: Scheduled job '${TARGET_JOB_NAME}' execution has failed`);
			console.log(exp);
			
		}
		
	}
	
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



test('Dispatch -> Scheduled Jobs', async ({ basePage, baseUrl }) => {
	
	const TARGET_JOB_NAME = "Auto Dispatch";
	const TARGET_AUTOMATOR_TYPE = "Auto Dispatch";
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Dispatch");
	
	await utils.switchToSettingsTab(frame, "Scheduled Jobs");
	
	await utils.checkBooleanSetting(frame, "Mention assigned user when the Service Appointment is dispatched");
	await utils.selectPicklistSettingByLabel(frame, "Dispatch Chatter Post Destination", "Service Appointment Feed");
	
	
	// define locators
	
	const jobsSectionLocator = frame.locator('dispatch-automation');
	const jobsSectionButtonsLocator = jobsSectionLocator.locator('.automatorButton.settingsButton');
	const jobsSectionNewButtonLocator = jobsSectionButtonsLocator.filter({ hasText: "New Job" });
	const jobsSectionEditButtonLocator = jobsSectionButtonsLocator.filter({ hasText: "Edit" });
	
	const jobTimeControl = jobsSectionLocator.locator(".automatorTimeSpan");
	const jobTimeHourControl = jobTimeControl.filter({ hasText: "Hour" }).locator(".timeSpanInput input");
	const jobTimeMinuteControl = jobTimeControl.filter({ hasText: "Minute" }).locator(".timeSpanInput input");
	
	const targetJobTextLocator = frame.getByText(TARGET_JOB_NAME, { exact: true });
	const jobNameCellLocator = frame.locator(".automatorTextAndCollapse");
	const targetJobNameCellLocator = jobNameCellLocator.filter({ has: targetJobTextLocator });
	const targetJobRowLocator = frame.locator(".automatorRowContainer").filter({ has: targetJobNameCellLocator });
	const targetJobActionsLocator = targetJobRowLocator.locator(".runNowContainer");
	
	const targetJobStatusToggleLocator = frame.locator(".automatorRowAndContent").filter({ has: targetJobRowLocator }).locator(".automatorLeftContent").locator("checkbox").filter({ hasText: "Active" });
	const targetJobStatusActiveLocator = targetJobStatusToggleLocator.locator(".checked").first();
	const targetJobStatusInactiveLocator = targetJobStatusToggleLocator.locator(".unchecked").first();
	
	const newJobPopupLocator = frame.locator('.settingsPopup');
	
	
	await jobsSectionNewButtonLocator.waitFor();
	
	let doesScheduledJobExist = false;
	
	
	// detect by name if target scheduled job exists
	if (await jobsSectionEditButtonLocator.isVisible()) {
		
		console.log("Some scheduled jobs are present already.");
		
		if (await targetJobNameCellLocator.isVisible()) {
			
			console.log(`Scheduled job with name '${TARGET_JOB_NAME}' already exists.`);
			
			doesScheduledJobExist = true;
			
		} else {
			
			console.log(`Scheduled job with name '${TARGET_JOB_NAME}' does NOT exist.`);
			
		}
		
	} else {
		
		console.log("No Scheduled jobs available at all.");
		
	}
	
	
	// create target scheduled job with predefined name (if not exist)
	if (doesScheduledJobExist === false) {
		
		console.log(`Creating scheduled job with name '${TARGET_JOB_NAME}'...`);
		
		await jobsSectionNewButtonLocator.click();
		
		await utils.fillSetting(newJobPopupLocator, 'Name', TARGET_JOB_NAME);
		await utils.selectPicklistSettingByLabel(newJobPopupLocator, 'Automator type', TARGET_AUTOMATOR_TYPE);
		
		await utils.clickByText(newJobPopupLocator, 'Save');
		
		await utils.clickSaveSettingButton(frame);
		
		console.log(`Scheduled job with name '${TARGET_JOB_NAME}' has been created.`);
		
	}
	
	
	// updating parameters of target scheduled job
	{
		
		console.log("Tweaking further scheduled job parameters...");
		
		await utils.clickByText(targetJobNameCellLocator, "+");
		
		await utils.setRadio(frame, "Recurring");
		
		await utils.setCheckboxes(frame, [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ]);
		
		await utils.setRadio(frame, "Day of week");
		
		await utils.setCheckboxes(frame, [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ]);
		
		await utils.setRadio(frame, "Specific Hour");
		
		await jobTimeHourControl.fill(String(23));
		await jobTimeMinuteControl.fill(String(0));
		
		await utils.clickByText(frame, "All");
		
		await utils.fillSetting(frame, "Time Horizon in days", 30);
		
		await utils.selectPicklistSettingByLabel(frame, "Filter by criteria", "None");
		
		await utils.fillSetting(frame, "Email recipient user name", '');
		
		await utils.clickSaveSettingButton(frame);
		
		
		// activate job if not already
		if (await targetJobStatusInactiveLocator.isVisible()) {
			
			await targetJobStatusInactiveLocator.click({ force: true });
			console.log(`Activated '${TARGET_JOB_NAME}' job`); 
			
		} else if (await targetJobStatusActiveLocator.isVisible()) {
			
			console.log(`Job '${TARGET_JOB_NAME}' is already active.`);
			
		}
		
		await utils.clickSaveSettingButton(frame);
		
	}
	
	
	// re-entering settings page and Scheduled Jobs tab to select All territories again and save (due to some issue or weird behaviour)
	{
		
		await utils.openSettings(basePage, baseUrl);
		
		await utils.switchToSettingsMenu(frame, "Dispatch");
		
		await utils.switchToSettingsTab(frame, "Scheduled Jobs");
		
		console.log("Tweaking further scheduled job parameters...");
		
		await utils.clickByText(targetJobNameCellLocator, "+");
		
		await utils.clickByText(frame, "All");
		
		await utils.clickSaveSettingButton(frame);
		
		await utils.clickByText(targetJobActionsLocator, "Run now");
		
		// try to run job suppressing failure if any (just logging error)
		try {
			
			await targetJobActionsLocator.locator(".automatorRunNowDone").waitFor();
			console.log(`Scheduled job '${TARGET_JOB_NAME}' execution has succeeded.`);
			
		} catch (exp) {
			
			console.log(`WARNING: Scheduled job '${TARGET_JOB_NAME}' execution has failed`);
			console.log(exp);
			
		}
		
	}
	
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
			
		await appsTable
			.getByRole("row")
			.last()
			.click({ force: true });
		
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
	console.log(`Contract Line Item Available Fields: ${availableOptions}`);
	
	let selectedOptions = await utils.getPicklistOptions(frame, 'Selected Fields');
	console.log(`Contract Line Item Selected Fields: ${selectedOptions}`);
	
	
	// unselect extra options (commented for now, so just new options would be appended to existent setup)
	// for (const selectedOption of selectedOptions) {
		
		// if (FIELDS_LABELS_TO_SELECT.includes(selectedOption)) {
			// continue;
		// }
		
		// await utils.selectPicklistSettingByLabel(frame, "Selected Fields", selectedOption);
		// await utils.clickLink(frame, "Remove");
		
		// console.log(`Unselected successfully Contract Line Item Field '${selectedOption}'!`);
		
	// }
	
	
	// select all needed options
	for (const fieldLabelToSelect of FIELDS_LABELS_TO_SELECT) {
		
		if (availableOptions.includes(fieldLabelToSelect)) {
			
			console.log(`Contract Line Item Field '${fieldLabelToSelect}' is available to select.`);
			
			await utils.selectPicklistSettingByLabel(frame, "Available Fields", fieldLabelToSelect);
			await utils.clickLink(frame, "Add");
			
			console.log(`Selected successfully Contract Line Item Field '${fieldLabelToSelect}'!`);
			
		} else if (selectedOptions.includes(fieldLabelToSelect)) {
			
			console.log(`Contract Line Item Field '${fieldLabelToSelect}' is already selected!`);
			
		} else {
			
			console.log(`WARNING: No Contract Line Item Field '${fieldLabelToSelect}' available to select!`);
			
		}
		
	}
	
	await utils.clickButton(frame, "Save");
	
	frame = utils.getMainFrameWithTitlePrefix(basePage, "Edit Page Layout");
	await utils.waitForLink(frame, "Edit Multi-Line Layout");
	
});



test('Setup -> Field Service Mobile App Builder -> Create/Edit and Publish', async ({ basePage, baseUrl }) => {
	
	// const
	
	const APP_BUILDER_HOME_URL = "/lightning/setup/FieldServiceAppBuilder/home";
	const TARGET_CONFIG_NAME = "Otis Field Service Mobile";
	const TARGET_APP_PROFILE = "Field Service Mechanic";
	
	
	// functions
	
	const selectPageType = async (root, name) => {
		
		await root.getByLabel("Page Type", { exact: true }).dispatchEvent("click");
		await utils.clickByText(root.getByRole("listbox"), name);
		
	}
	
	const selectObjects = async (root, name) => {
		
		await utils.clickCombobox(root, "Objects");
		await utils.clickByText(root.getByRole("listbox"), name);
		
	}
	
	const selectFilters = async (root, name) => {
		
		await utils.clickCombobox(root, "Filters");
		await utils.clickByText(root.getByRole("listbox"), name);
		
	}
	
	const selectFieldServicePage = async (root, name) => {
		
		await root.getByLabel("Field Service Page", { exact: true }).dispatchEvent("click");
		await utils.clickByText(root.getByRole("listbox"), name);
		
	}
	
	const selectIcon = async (root, name) => {
		
		const fieldLocator = root.locator('mobilebuilder-tab-form mobilebuilder-tab-fields-common');
		const iconPickerModalLocator = root.locator('mobilebuilder-icon-picker-modal');
		
		// remove current/default icon
		await fieldLocator
			.locator('.iconSection')
			.locator('.slds-pill__remove')
			.click();
		
		await utils.clickButton(fieldLocator, "Select Icon...");
		
		await iconPickerModalLocator.getByText(name, { exact: true }).click();
		await iconPickerModalLocator.getByRole("button", { name: "Select", exact: true }).click();
		
	}
	
	const backToTabs = async (root) => {
		
		await root.locator(".back_button").click();
		
	}
	
	
	// locators
	
	const appsConfigsTableLocator = basePage.locator("table").filter({ has: basePage.getByText("App Name") });
	const targetAppConfigRowLocator = appsConfigsTableLocator.locator("tr").filter({ has: basePage.getByText(TARGET_CONFIG_NAME, { exact: true }) });
	
	const targetProfileText = basePage.getByText(TARGET_APP_PROFILE, { exact: true });
	const targetAppConfigWithProfileRowLocator = targetAppConfigRowLocator.filter({ has: targetProfileText });
	
	const navigationTabsList = basePage.locator("mobilebuilder-tabs-list");
	const navigationTabCloseIconLocator = navigationTabsList.locator(".tabs .close_icon").first();
	
	const addNavigationTabButtonLocator = navigationTabsList.getByText("Add Tab");
	
	const publishOptionalPromptModalLocator = basePage.locator("mobilebuilder-save-prompt-modal");
	const publishOptionalPromptCancelButtonLocator = publishOptionalPromptModalLocator.getByRole("button", { name: "Cancel", exact: true });
	
	const profileAssignmentModalLocator = basePage.locator("mobilebuilder-app-profile-assignment");
	const profileAssignmentNextButtonLocator = profileAssignmentModalLocator.getByRole("button", { name: "Next", exact: true });
	const profileAssignmentOverrideButtonLocator = profileAssignmentModalLocator.getByRole("button", { name: "Override & Publish", exact: true });
	const profileAssignmentPublishButtonLocator = profileAssignmentModalLocator.getByRole("button", { name: "Publish", exact: true });
	const profileAssignmentSearchControlLocator = profileAssignmentModalLocator.getByPlaceholder("Search profiles...", { exact: true });
	
	const profileAssignmentTargetProfilesLocator = profileAssignmentModalLocator.locator("tr").filter({ has: targetProfileText }).getByRole("checkbox");
	
	const builderToolbarLocator = basePage.locator("mobilebuilder-toolbar");
	const builderToolbarPublishButtonLocator = builderToolbarLocator.getByRole("button", { name: "Publish", exact: true });
	const builderToolbarSaveButtonLocator = builderToolbarLocator.getByRole("button", { name: "Save", exact: true });
	const builderToolbarSaveInProgressIndicatorLocator = builderToolbarLocator.getByText("Saving", { exact: true });
	
	const backToConfigsLinkLocator = await basePage.locator("mobilebuilder-header").locator(".test-back-url");
	
	
	await basePage.goto(baseUrl + APP_BUILDER_HOME_URL);
	await utils.waitForButton(basePage, "New Configuration");
	
	
	// figure out wether target config exist
	let doesConfigExist = false; {
		
		if (await basePage.getByText("You don't have any configurations").isVisible()) {
			
			console.log(`No apps configs are available at all.`);
			
		} else {
			
			console.log(`Some apps configs are available.`);
			
			doesConfigExist = await targetAppConfigRowLocator.isVisible();
			
			if (doesConfigExist === true) {
				
				console.log(`App config with name '${TARGET_CONFIG_NAME}' already exists.`);
				
			} else {
				
				console.log(`App config with name '${TARGET_CONFIG_NAME}' does NOT exist.`);
				
			}
			
		}
		
	}
	
	
	// create target app config with predefined name (if not exist)
	if (doesConfigExist === false) {
		
		console.log(`Creating app conifg with name '${TARGET_CONFIG_NAME}'...`);
		
		await utils.clickButton(basePage, "New Configuration");
		
		await basePage.getByPlaceholder("Add an app name...").fill("Otis Field Service Mobile");
		await basePage.getByPlaceholder("Add an API name...").fill("Otis_Field_Service_Mobile");
		
		await utils.clickButton(basePage, "Save");
		
		await utils.waitForButton(basePage, "Publish");
		await utils.waitForButton(basePage, "Add Tab");
		
	} else {
		
		await targetAppConfigRowLocator.getByRole('button').click({ force: true });
		
		await utils.clickMenuItem(basePage, "Edit App Configuration");
		
		await utils.waitForButton(basePage, "Publish");
		await utils.waitForButton(basePage, "Add Tab");
		
	}
	
	
	// removing all current tabs - but the last tab cannot be removed, so will remove it after creating first new one
	while (true) {
		
		if (await navigationTabCloseIconLocator.isVisible()) {
			
			await navigationTabCloseIconLocator.click();
			
		} else {
			
			break;
			
		}
		
	}
	
	
	// Home tab
	{
		
		await addNavigationTabButtonLocator.click();
		
		await selectPageType(basePage, "List View");
		await selectObjects(basePage, "Unit");
		await selectFilters(basePage, "Shutdown Units - FSL");
		
		await utils.fillSetting(basePage, "Tab Label", "Home");
		
		await selectIcon(basePage, "home");
		
		await backToTabs(basePage);
		
	}
	
	
	// remove last existent tab menu from previous initial cleanup step
	if (await navigationTabCloseIconLocator.isVisible()) {
		await navigationTabCloseIconLocator.click();
	}
	
	
	// Schedule tab
	{
		
		await addNavigationTabButtonLocator.click();
		
		await selectPageType(basePage, "Salesforce Field Service");
		await selectFieldServicePage(basePage, "Schedule");
		
		await utils.fillSetting(basePage, "Tab Label", "Schedule");
		
		await selectIcon(basePage, "event");
		
		await backToTabs(basePage);
		
	}
	
	
	// Notifications tab
	{
		
		await addNavigationTabButtonLocator.click();
		
		await selectPageType(basePage, "Salesforce Field Service");
		await selectFieldServicePage(basePage, "Notifications");
		
		await utils.fillSetting(basePage, "Tab Label", "Notifications");
		
		await selectIcon(basePage, "notification");
		
		await backToTabs(basePage);
		
	}
	
	
	// Closed WO tab
	{
		
		await addNavigationTabButtonLocator.click();
		
		await selectPageType(basePage, "List View");
		await selectObjects(basePage, "Work Order");
		await selectFilters(basePage, "Closed WO In Last 72 hours");
		
		await utils.fillSetting(basePage, "Tab Label", "Closed WO");
		
		await selectIcon(basePage, "work_order_type");
		
		await backToTabs(basePage);
		
	}
	
	
	await builderToolbarSaveButtonLocator.click();
	await utils.waitToDisappear(builderToolbarSaveInProgressIndicatorLocator);
	
	// handling extra dialog suggesting to publish - just cancel it
	if (publishOptionalPromptModalLocator.isVisible()) {
		await publishOptionalPromptCancelButtonLocator.first().click();
	}
	
	
	// publishing with profiles assignment
	{
		
		await builderToolbarPublishButtonLocator.click();
		
		await profileAssignmentSearchControlLocator.fill(TARGET_APP_PROFILE);
		
		for (const targetProfileLocator of await profileAssignmentTargetProfilesLocator.all()) {
			await targetProfileLocator.check({ force: true });
		}
		
		// if extra Next button is enabled (to confirm override of profies assignment) go through 2-step process: Next, then Override & Publish
		if (
			await profileAssignmentNextButtonLocator.isVisible()
			&&
			await profileAssignmentNextButtonLocator.isDisabled() === false
		) {
			
			await profileAssignmentNextButtonLocator.click();
			
			await profileAssignmentOverrideButtonLocator.click();
			
		// no overrides - just hit Publish
		} else {
			
			await profileAssignmentPublishButtonLocator.click();
			
		}
		
		await utils.waitToDisappear(profileAssignmentModalLocator);
		
	}
		
		
	// get back to mobile app builder page and check if profile has been assigned
	{
		
		await backToConfigsLinkLocator.click();
		
		await utils.waitForButton(basePage, "New Configuration");
		
		let isTargetProfileAssigned = await targetAppConfigWithProfileRowLocator.isVisible();
		
		if (isTargetProfileAssigned === true) {
			console.log(`Target profile '${TARGET_APP_PROFILE}' is assigned.`);
		} else {
			console.log(`WARNING: No target profile '${TARGET_APP_PROFILE}' assigned!`);
		}
		
	}
	
});
*/



test('Setup -> Service Report Templates -> Create/Edit and Activate', async ({ basePage, baseUrl }) => {
	
	// const
	
	const SERVICE_REPORT_TEMPLATES_URL = "/lightning/setup/ServiceReportEditor/home";
	const TARGET_TEMPLATE_NAME = "Summary Report";
	const TARGET_CHILD_LAYOUT_NAME = "Service Appointment for Work Order";
	
	/*
	const MANDATORY_SECTIONS_HEADERS = new utils.CaseInsensitiveSet(
		[ 
			"Service Report", 
			"Appointment Information",
			"Work Details",
			"Customer Signature"
		]
	);
	*/
	
	const MANDATORY_SECTIONS_HEADERS = [ 
		"Service Report", 
		"Appointment Information",
		"Work Details",
		"Customer Signature"
	];
	
	const SPECIAL_SECTIONS_HEADERS = [ 
		"Customer Signature"
	];
	
	
	// functions
	
	const dragAndDrop = async (page, sourceLocator, targetLocator) => {
		
		// this dragging works
		await sourceLocator.hover();
		await page.mouse.down();
		await targetLocator.hover();
		await targetLocator.hover();
		await page.mouse.up();
		
	}
	
	
	await basePage.goto(baseUrl + SERVICE_REPORT_TEMPLATES_URL);
	
	let frame = utils.getMainFrameWithTitlePrefix(basePage, "Service Report Templates");
	
	let newTemplateButton = frame.getByTitle("New Service Report Templates").and(basePage.getByRole("button"));
	await newTemplateButton.waitFor();
	
	let templatesTable = await frame
		.locator("table")
		.filter({ has: frame.getByText("Created By") });
	
	await templatesTable.waitFor();
	
	
	let summaryReportRow = await templatesTable
		.getByRole("row")
		.filter({ has: frame.getByText(TARGET_TEMPLATE_NAME, { exact: true }) });
	
	
	let doesSummaryReportExist = await summaryReportRow.isVisible();
	
	if (doesSummaryReportExist === true) {
		
		console.log(`Target template '${TARGET_TEMPLATE_NAME}' already exists.`);
		
		await utils.clickLink(summaryReportRow, "Edit");
		
		// TODO - consider go right to activation, i.e. jump over editing, if summary report already exist (in order not to override current changes)
		
	} else {
		
		console.log(`Target template '${TARGET_TEMPLATE_NAME}' does NOT exist - creating a new one...`);
		
		await newTemplateButton.click();
		
		frame = utils.getMainFrameWithTitlePrefix(basePage, "Create New Service Report Template");
		
		await utils.selectPicklistSettingByLabel(frame, "Existing Template", "Standard Template");
		await utils.fillSetting(frame, "Template Name", TARGET_TEMPLATE_NAME);
		
		await utils.clickButton(frame, "Save");
		
	}
	
	frame = utils.getMainFrame(basePage);
	
	await frame.locator(".childLayoutPicklist select").selectOption({ label: TARGET_CHILD_LAYOUT_NAME });
	
	
	// remove extra sections
	{
		
		await frame.locator(".canvasBodyPanel").locator(".section .section-header").first().waitFor();
		
		const locatorsForSectionsToRemove = [ ];
		
		for (const sectionHeaderLocator of await frame.locator(".canvasBodyPanel").locator(".section .section-header").all()) {
			
			if (
				MANDATORY_SECTIONS_HEADERS.includes(
					await sectionHeaderLocator.locator(".section-header-text").textContent()
				)
			) {
				continue;
			}
			
			locatorsForSectionsToRemove.push(sectionHeaderLocator);
			
		}
		
		for (const locatorForSectionToRemove of locatorsForSectionsToRemove) {
			await locatorForSectionToRemove
				.locator(".x-tool-remove")
				.dispatchEvent("click");
				//.click({ force: true });
		}
		
	}
	
	
	// remove all fields from all mandatory sections
	for (const mandatorySectionHeader of MANDATORY_SECTIONS_HEADERS) {
		
		// skip special sections
		if (SPECIAL_SECTIONS_HEADERS.includes(mandatorySectionHeader)) {
			continue;
		}
		
		let fieldsOffset = 0;
		
		let mandatorySectionLocator = frame.locator(".canvasBodyPanel").locator(".section").filter({ has: frame.locator(".section-header").getByText(mandatorySectionHeader, { exact: true }) }).locator(".section-body");
		
		while (true) {
			
			let mandatorySectionFirstFieldLocator = mandatorySectionLocator.locator("table tr td").nth(fieldsOffset);
			
			if (await mandatorySectionFirstFieldLocator.isVisible()) {
				await mandatorySectionFirstFieldLocator.hover();
				
				// not every section can be removed, e.g. Service Report, Footer
				if (await mandatorySectionFirstFieldLocator.locator(".widget .remove").isVisible()) {
					await mandatorySectionFirstFieldLocator.locator(".widget .remove").click({ force: true });
					await mandatorySectionLocator.waitFor({ timeout: 100 });
				} else {
					fieldsOffset++;
				}
			} else {
				break;
			}
			
		}
		
	}
	
	
	await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Image");
	
	let serviceReportSectionLocator = frame.locator(".canvasBodyPanel").locator(".section").filter({ has: frame.locator(".section-header").getByText("Service Report", { exact: true }) }).locator(".section-body");
	await serviceReportSectionLocator.locator("table tr").first().locator('td').first().waitFor();
	
	//let qteHeader = frame.locator(".QTEHeader").filter({has: frame.locator(".section-header").filter({has: frame.getByText("Service Report", { exact: true }) }) });
	//await qteHeader.locator(".section-body table tr").first().locator('td').first().waitFor();
	
	let dragTargetLocator = serviceReportSectionLocator.locator("table tr").first().locator('td').first();
	
	if (await dragTargetLocator.filter({ has: frame.locator('img') }).isVisible() === true) {
		
		console.log("Seems like OTIS Logo is already there.");
		// TODO: it can be graggable icon, probably try differentiate by description (populate description on upload and check whether it is matching to alt text)
		
	} else {
		
		console.log("No OTIS Logo available yet - trying to insert one...");
		
		// this dragging works
		let dragSourceLocator = frame.locator(".draggables").getByText("Text/Image Field", { exact: true });
		await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
		
		let richTextEditorFrame = utils.getMainFrameWithTitlePrefix(frame, "Rich Text Editor");
		
		await frame.locator(".propsWindow").getByRole("toolbar").getByRole("button").filter({ hasText: "Image" }).click();
		
		await frame.getByLabel("Select Image").setInputFiles(path.join(__dirname, "OTIS_logo.jpg"));
		//await utils.fillSetting(frame, "Description", "OTIS Logo");
		//await frame.getByLabel("Description").waitFor();
		//await frame.getByLabel("Description").fill("OTIS Logo", { force: true });
		
		await frame.getByTitle("Insert Image").and(frame.getByRole("button")).click();
		await frame.getByTitle("Insert Image").waitFor({ "state" : "hidden" });
		
		await frame.getByRole("button", { name: "OK", exact: true }).dispatchEvent("click");
		await frame.getByRole("button", { name: "OK", exact: true }).waitFor({ "state" : "hidden" });
		
	}
	
	
	// drag fields into Appointment Information section
	{
		
		let appointmentInformaionSectionLocator = frame.locator(".canvasBodyPanel").locator(".section").filter({ has: frame.locator(".section-header").getByText("Appointment Information", { exact: true }) }).locator(".section-body");
		await appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first().waitFor();
		
		
		// "Unit" field (first column)
		{
			
			await frame.getByText("Service Appointment", { exact: true}).and(frame.locator(".selectorItem")).click();
			//await utils.fillSetting(frame, "Quick Find", "Unit");
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Unit");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Unit".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "Address" field (first column)
		{
			
			await frame.getByText("Service Appointment", { exact: true}).and(frame.locator(".selectorItem")).click();
			//await utils.fillSetting(frame, "Quick Find", "Address");
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Address");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Address".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		
		// "Description" field (second column)
		{
			
			await frame.getByText("Service Appointment", { exact: true}).and(frame.locator(".selectorItem")).click();
			//await utils.fillSetting(frame, "Quick Find", "Description");
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Description");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Description".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').nth(1);
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "No Signature Reason" field (second column)
		{
			
			await frame.getByText("Service Appointment", { exact: true}).and(frame.locator(".selectorItem")).click();
			//await utils.fillSetting(frame, "Quick Find", "No Signature Reason");
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("No Signature Reason");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("No Signature Reason".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').nth(1);
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
	}
	
	
	// drag fields into Work Details section
	{
		
		let appointmentInformaionSectionLocator = frame.locator(".canvasBodyPanel").locator(".section").filter({ has: frame.locator(".section-header").getByText("Work Details", { exact: true }) }).locator(".section-body");
		await appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first().waitFor();
		
		// "Description" field (first column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Description");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Description".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "Unit Misused ?" field (first column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Unit Misused ?");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Unit Misused ?".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "Service Request Closeout Notes" field (first column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Service Request Closeout Notes");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Service Request Closeout Notes".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "SM Component Code" field (first column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("SM Component Code");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("SM Component Code".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "Service Request Paged On" field (first column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Service Request Paged On");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Service Request Paged On".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').first();
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		
		// "Building Number" field (second column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Building Number");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Building Number".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').nth(1);
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "Unit Occupied ?" field (second column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Unit Occupied ?");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Unit Occupied ?".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').nth(1);
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "SM Work Performed Code" field (second column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("SM Work Performed Code");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("SM Work Performed Code".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').nth(1);
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
		// "Service Request Actual Ended On" field (second column)
		{
			
			await frame.getByText("Work Order", { exact: true}).and(frame.locator(".selectorItem")).click();
			await frame.getByLabel("Quick Find").locator('visible=true').pressSequentially("Service Request Actual Ended On");
			
			let dragSourceLocator = await frame.locator(".draggables .item:not(.used)").getByText("Service Request Actual Ended On".substring(0, 10)).first();
			let dragTargetLocator = appointmentInformaionSectionLocator.locator("table tr").first().locator('td').nth(1);
			await dragAndDrop(basePage, dragSourceLocator, dragTargetLocator);
			
		}
		
	}
	
	
	// configuring Customer Signature section
	{
		
		const FIELDS_LABELS_TO_SELECT = [ 
			"Signature",
			"Signed By",
			"Type",
			"Date"
		];
		
		let customerSignatureSectionLocator = frame.locator(".canvasBodyPanel").locator(".section").filter({ has: frame.locator(".section-header").getByText("Customer Signature", { exact: true }) });
		let customerSignatureSectionHeaderLocator = customerSignatureSectionLocator.locator(".section-header");
		
		await customerSignatureSectionHeaderLocator.hover();
		await customerSignatureSectionHeaderLocator.locator(".x-tool-gear").click({ force: true });
		
		await frame.locator(".x-form-arrow-trigger").click();
		await frame.getByText("Customer", { exact: true }).and(frame.locator(".x-combo-list-item")).click();
		
		const availableFieldsSection = frame.locator("fieldset").filter({ has: frame.locator("legend").filter({ has: frame.getByText("Available Fields", { exact: true }) }) });
		const availableFieldsList = availableFieldsSection.locator(".x-list-body");
		const availableFieldListItems = availableFieldsList.locator("dl");
		
		let availableOptions = [];
		
		for (const availableOptionLocator of await availableFieldsList.locator('dl').all()) {
			availableOptions.push(
				(await availableOptionLocator.textContent())?.trim()
			);
		}
		
		console.log(`Customer Signature Available Fields: ${availableOptions}`);
		
		
		const selectedFieldsSection = frame.locator("fieldset").filter({ has: frame.locator("legend").filter({ has: frame.getByText("Selected Fields", { exact: true }) }) });
		const selectedFieldsList = selectedFieldsSection.locator(".x-list-body");
		const selectedFieldListItems = selectedFieldsList.locator("dl");
		
		let selectedOptions = [];
		
		//for (const availableOptionLocator of await availableFieldsList.locator('dl dt em').all()) {
		for (const selectedOptionLocator of await selectedFieldListItems.all()) {
			selectedOptions.push(
				(await selectedOptionLocator.textContent())?.trim()
			);
		}
		
		console.log(`Customer Signature Selected Fields: ${selectedOptions}`);
		
		
		const addOptionButtonLocator = frame.locator("img:below(:text('Add'))").and(frame.locator("[id*='iconRight']"))
		const removeOptionButtonLocator = frame.locator("img:above(:text('Remove'))").and(frame.locator("[id*='iconLeft']"));
		const upOptionButtonLocator = frame.locator("img:below(:text('Up'))").and(frame.locator("[id*='iconUp']"))
		const downOptionButtonLocator = frame.locator("img:above(:text('Down'))").and(frame.locator("[id*='iconDown']"));
		
		
		// unselect all extra options first
		for (const selectedOption of selectedOptions) {
			
			if (FIELDS_LABELS_TO_SELECT.includes(selectedOption)) {
				continue;
			}
			
			await utils.clickByText(selectedFieldListItems, selectedOption);
			await removeOptionButtonLocator.click();
			
			console.log(`Unselected successfully Customer Signature Field '${selectedOption}'!`);
			
		}
		
		
		// select all needed options
		for (const fieldLabelToSelect of FIELDS_LABELS_TO_SELECT) {
			
			if (availableOptions.includes(fieldLabelToSelect)) {
				
				console.log(`Customer Signature Field '${fieldLabelToSelect}' is available to select.`);
				
				await utils.clickByText(availableFieldListItems, fieldLabelToSelect);
				await addOptionButtonLocator.click();
				
				console.log(`Selected successfully Customer Signature Field '${fieldLabelToSelect}'!`);
				
			} else if (selectedOptions.includes(fieldLabelToSelect)) {
				
				console.log(`Customer Signature Field '${fieldLabelToSelect}' is already selected!`);
				
			} else {
				
				console.log(`WARNING: No Customer Signature Field '${fieldLabelToSelect}' available to select!`);
				
			}
			
		}
		
		
		// get latest selected options
		selectedOptions = [];
		for (const selectedOptionLocator of await selectedFieldListItems.all()) {
			selectedOptions.push(
				(await selectedOptionLocator.textContent())?.trim()
			);
		}
		
		
		// ordering current options appropriately
		for (let [targetIndex, targetOption] of FIELDS_LABELS_TO_SELECT.entries()) {
			
			const sourceIndex = selectedOptions.indexOf(targetOption);
			
			
			if (sourceIndex === -1) {
				console.log(`WARNING: Customer Signature Field '${targetOption}' is still not selected for some reason!`);
				continue;
			}
			
			if (sourceIndex === targetIndex) {
				continue;
			}
			
			const numberOfSwaps = sourceIndex - targetIndex;
			
			for (let i = 0; i < Math.abs(numberOfSwaps); i++) {
				await utils.clickByText(selectedFieldListItems, targetOption);
				await (numberOfSwaps > 0 ? upOptionButtonLocator : downOptionButtonLocator).click();
			}
			
			selectedOptions[sourceIndex] = selectedOptions[targetIndex];
			selectedOptions[targetIndex] = FIELDS_LABELS_TO_SELECT[targetIndex];
			
		}
		
		//await basePage.pause();
		
		await frame.getByRole("button", { name: "OK", exact: true }).dispatchEvent("click");
		await frame.getByRole("button", { name: "OK", exact: true }).waitFor({ "state" : "hidden" });
		
	}
		
	
	
	await frame.getByRole("button", { name: "Save", exact: true }).click();
	
	await newTemplateButton.waitFor();
	
	
	let activateSummaryReportLink = summaryReportRow.getByRole("link", { name: "Activate", exact: true });
	let deactivateSummaryReportLink = summaryReportRow.getByRole("link", { name: "Deactivate", exact: true });
	
	
	if (await activateSummaryReportLink.isVisible()) {
		
		console.log(`Target template '${TARGET_TEMPLATE_NAME}' is NOT active - activating...`);
		
		await activateSummaryReportLink.click();
		
		await deactivateSummaryReportLink.waitFor();
		
		console.log(`Target template '${TARGET_TEMPLATE_NAME}' has been activated successfully.`);
		
	} else {
		
		console.log(`Target template '${TARGET_TEMPLATE_NAME}' is already active.`);
		
	}
	
});


/*
test(`FSL Optmization User -> Activate Optimization Service`, async ({ basePage, baseUrl }) => {
	
	await basePage.goto(baseUrl + '/lightning/setup/Profiles/home');
	
	let frame = utils.getMainFrameWithTitlePrefix(basePage, "User Profiles");
	
	await frame.getByRole("link", { name: "FSL Optimization", exact: true }).click()
	
	frame = utils.getMainFrameWithTitlePrefix(basePage, "Profile");
	await frame.getByTitle("View Users", { exact: true }).and(frame.getByRole("button", { name: "users" })).first().click();
	//await frame.getByRole("button", "View Users", { exact: true }).click();
	
	frame = utils.getMainFrameWithTitlePrefix(basePage, "FSL Optimization");
	await frame.getByRole("link", { name: /^fsl.00D/i }).click();
	
	frame = utils.getMainFrameWithTitlePrefix(basePage, "User");
	
	await frame.getByTitle("Reset Password").first().waitFor();
	
	if (await frame.getByTitle("Login").and(frame.getByRole("button")).first().isVisible() === false) {
		console.log(`WARNING: Cannot log in as FSL Optimization user - check if enabled in Setup -> Login Access Policies`);
		return;
	}
	
	await frame.getByTitle("Login").and(frame.getByRole("button")).first().click();
	
	await basePage.waitForLoadState('networkidle');
	await basePage.waitForLoadState('domcontentloaded');
	await basePage.waitForLoadState('networkidle');
	
	await utils.openSettings(basePage, baseUrl);
	
	frame = utils.getMainFrame(basePage);
	
	await frame.getByText("Standard Optimization", { exact: true }).waitFor();
	
	if (await frame.getByText("The optimization service is active", { exact: true}).isVisible()) {
		console.log("Optimization service is already active.");
		return;
	}
	
	if (await frame.getByText("Activate Optimization", { exact: true })) {
		console.log("Activating optimization service...");
		await frame.getByText("Activate Optimization", { exact: true }).click();
	}
	
	await utils.clickSaveSettingButton(frame);
	
	
	// Optimization -> Activation
	//Activate Optimization
	//Save
	
	
	await basePage.pause();
	
});
*/


