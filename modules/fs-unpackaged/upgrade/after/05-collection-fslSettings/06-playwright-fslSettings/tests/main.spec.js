// @ts-check

const basePath = (process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../../..");

const { test, expect } = require(basePath + "/scripts/playwright/setup");
const utils = require(basePath + "/scripts/playwright/utils");



test('Global Actions -> Appointment Booking', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Global Actions");
	
	await utils.switchToSettingsTab(frame, "APPOINTMENT BOOKING");
	
	
	await utils.selectPicklistSettingByLabel(frame, "Default scheduling policy", "Otis Default Scheduling Policy");
	
	// FSL Winter 25 specific setting
	await utils.checkOptionalBooleanSetting(frame, "Automatically search for scheduling options");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Global Actions -> Emergency Wizard', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Global Actions");
	
	await utils.switchToSettingsTab(frame, "EMERGENCY WIZARD");
	
	
	await utils.selectPicklistSettingByLabel(frame, "Emergency scheduling policy", "Otis Emergency Scheduling Policy");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Scheduling -> General Logic', async ({ basePage, baseUrl }) => {
	
	const GENERAL_LOGIC_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Enroute",
			"Onsite",
			"Cannot Complete", 
			"Completed"
		]
	);
	
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Scheduling");
	
	await utils.switchToSettingsTab(frame, "General Logic");
	
	await utils.uncheckBooleanSetting(frame, "Activate Approval confirmation on resource absences");
	
	await utils.setRadio(frame, "Sliding and reshuffling", false);
	
	
	// 'Scheduling Logic' section
	{
		
		const globalOptimizationSection = (
			frame
			.locator("scheduling-logic")
			.locator(".guarded-optimization-container")
		);
		
		await globalOptimizationSection.waitFor();
		
		
		const multiselectComponentContainer = globalOptimizationSection.locator(".multiselect-component-container");
		
		// clear all selected options first
		await multiselectComponentContainer.waitFor();
		const selectedOptionsLocator = multiselectComponentContainer.locator(".multiselect-pillars-container .multiselect-pillar");
		
		for (const selectedOptionLocator of await selectedOptionsLocator.all()) {
			if (await selectedOptionLocator.isVisible()) {
				await selectedOptionLocator.click();
			}
		}
		
		// open drop down to select statuses
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
		// select statuses
		for (const statusToPin of GENERAL_LOGIC_PINNED_STATUSES) {
			await multiselectComponentContainer.locator("ul li").filter({ hasText: statusToPin }).dispatchEvent("click");
		}
		
		// close drop down to select statuses
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
	}
	
	
	await utils.uncheckBooleanSetting(frame, "Use the Visiting Hours object’s time zone when an appointment has visiting hours");
	await utils.uncheckBooleanSetting(frame, "Generate activity reports and retrieve optimization request files");
	
	await utils.uncheckBooleanSetting(frame, "Use 1-100 priority scale");
	
	
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
	await utils.uncheckOptionalBooleanSetting(frame, "Enable Predictive Travel for optimization services");
	
	await utils.selectPicklistSettingByLabel(frame, "Travel speed unit", "MPH");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Dispatcher Console UI -> Gantt Configurations', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Dispatcher Console UI");
	
	await utils.switchToSettingsTab(frame, "Gantt Configurations");
	
	await utils.selectPicklistSettingByLabel(frame, "Default scheduling policy", "Otis Default Scheduling Policy");
	
	await utils.checkBooleanSetting(frame, "Show secondary Service Territory Members on Gantt chart");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Optimization -> Logic', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Optimization");
	
	await utils.switchToSettingsTab(frame, "Logic");
	
	
	await utils.uncheckBooleanSetting(frame, "Enable sharing for Optimization request");
	
	await utils.selectPicklistSettingByLabel(frame, "Global optimization run time per service appointment", "Medium");
	
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Sharing -> Scheduled Jobs', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Sharing");
	
	await utils.switchToSettingsTab(frame, "Scheduled Jobs");
	
	
	await utils.checkBooleanSetting(frame, "Share parent Work Order when Service Appointment is shared");
	await utils.checkBooleanSetting(frame, "Share parent Account when Service Appointment is shared");
	
	await utils.uncheckBooleanSetting(frame, "Share parent Opportunity when Service Appointment is shared");
	
	await utils.checkBooleanSetting(frame, "Share parent Asset when Service Appointment is shared");
	await utils.checkBooleanSetting(frame, "Enable User Territories sharing");
	await utils.checkBooleanSetting(frame, "Automatically populate user groups based on User Territory");
	
	
	// uncheck setting that may be represented with 2 different labels in orgs for some reason
	try {
		
		await utils.uncheckBooleanSetting(frame, "Share all work capacity records with public groups associated with the service territory");
		
	} catch (outerError) {
		
		console.log("Error when unchecking 'Share all work capacity records...' scheduled job settings. Trying alternative label ...");
		
		try {
			
			await utils.uncheckBooleanSetting(frame, "Share all work capacity records with public user groups associated with the service territory");
			console.log("Successfully unchecked 'Share all work capacity records...' scheduled job settings using alternative label.");
			
		} catch (innerError) {
			
			console.log("Error when unchecking 'Share all work capacity records...' scheduled job settings using alternative label!");
			
		}
		
	}
	
	
	await utils.checkBooleanSetting(frame, "Make assigned resources followers of service appointments that are Dispatched or In Progress");
	
	
	await utils.clickSaveSettingButton(frame);
	
});


