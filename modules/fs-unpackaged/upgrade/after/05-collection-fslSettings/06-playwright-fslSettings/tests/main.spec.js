// @ts-check

const basePath = (process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../../..");

const { test, expect } = require(basePath + "/scripts/playwright/setup");
const utils = require(basePath + "/scripts/playwright/utils");


const APPS_TO_SET_CUSTOM_ATTRIBUTES = [ 
	{
		"name": "Salesforce Field Service for Android",
		"attributes": [
			{
				"name": "EXCLUDE_RESOURCE_ABSENCE_TYPES",
				"value": "\"Break\""
			}
		]
	},
	{
		"name": "Salesforce Field Service for iOS",
		"attributes": [
			{
				"name": "EXCLUDE_RESOURCE_ABSENCE_TYPES",
				"value": "\"Break\""
			}
		]
	}
];



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



test('Dispatcher Console UI -> Custom Actions', async ({ basePage, baseUrl }) => {
	
	const ACTION_NAME = "Assign Shift Coverage For Selected Horizon";
	const ACTION_TYPE = "Apex Class";
	const ACTION_CLASS = "FSL_CreateShiftformutlipledays";
	const ACTION_PERMISSION = "Schedule";
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Dispatcher Console UI");
	
	await utils.switchToSettingsTab(frame, "Custom Actions");
	
	// select Resources category
	await frame.getByText("Action Category", { exact: true }).locator('..').getByText("Resources").click();
	
	const activeActionsHeaderLocator = frame.getByText("Active Actions", { exact: true });
	
	const newActionButtonLocator = activeActionsHeaderLocator.locator('..').getByText("New Action");
	await newActionButtonLocator.waitFor();
	
	// early exit if action with such name already exists
	if (await activeActionsHeaderLocator.locator('..').getByText(ACTION_NAME, { exact: true }).isVisible()) {
		console.log(`Action named ${ACTION_NAME} is already present - nothing to do here!`);
		return;
	}
	
	await newActionButtonLocator.click();
	
	await frame.getByText("Label in Dispatcher Console", { exact: true }).locator('..').getByRole("textbox").fill(ACTION_NAME);
	
	await frame.getByText("Action Type", { exact: true }).locator('..').getByLabel(ACTION_TYPE).check();
	
	await frame.getByText("Class", { exact: true }).locator('..').getByRole("combobox").selectOption(ACTION_CLASS);
	
	await frame.getByText("Required Custom Permission", { exact: false }).locator('..').getByRole("combobox").selectOption({ label: ACTION_PERMISSION });
	
	//await frame.locator('.CA-iconsContainer').locator('svg').nth(2).click({ force: true });
	
	await utils.clickSaveSettingButton(frame);
	
});



test('Optimization -> Logic', async ({ basePage, baseUrl }) => {
	
	const GLOBAL_OPTIMIZATION_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Accepted",
			"Enroute",
			"Onsite",
			"Canceled",
			"Cannot Complete",
			"Completed"
		]
	);
	
	const INDAY_OPTIMIZATION_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Accepted",
			"Enroute",
			"Onsite",
			"Canceled",
			"Cannot Complete",
			"Completed"
		]
	);
	
	const RESOURCE_OPTIMIZATION_PINNED_STATUSES = new utils.CaseInsensitiveSet(
		[ 
			"Accepted",
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
	
	await utils.selectPicklistSettingByLabel(frame, "Global optimization run time per service appointment", "Medium");
	
	
	// 'Global Optimization' section
	{
		
		const globalOptimizationSection = (
			frame
			.locator("optimization-logic")
			.locator(".guarded-optimization-container")
			.filter({ 
				has: frame.locator(".optimization-title").filter({
					hasText: "Global Optimization"
				})
			})
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
		for (const statusToPin of GLOBAL_OPTIMIZATION_PINNED_STATUSES) {
			await multiselectComponentContainer.locator("ul li").filter({ hasText: statusToPin }).dispatchEvent("click");
		}
		
		// close drop down to select statuses
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
	}
	
	
	// 'In-Day Optimization' section
	{
		
		const inDayOptimizationSection = (
			frame
			.locator("optimization-logic")
			.locator(".guarded-optimization-container")
			.filter({ 
				has: frame.locator(".optimization-title").filter({
					hasText: "In-Day Optimization"
				})
			})
		);
		
		await inDayOptimizationSection.waitFor();
		
		
		const multiselectComponentContainer = inDayOptimizationSection.locator(".multiselect-component-container");
		
		// clear all selected options first
		await multiselectComponentContainer.waitFor();
		const selectedOptionsLocator = multiselectComponentContainer.locator(".multiselect-pillars-container .multiselect-pillar");
		
		for (const selectedOptionLocator of await selectedOptionsLocator.all()) {
			if (await selectedOptionLocator.isVisible()) {
				await selectedOptionLocator.click();
			}
		}
		
		// open drop down to select status
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
		// select statuses
		for (const statusToPin of INDAY_OPTIMIZATION_PINNED_STATUSES) {
			await multiselectComponentContainer.locator("ul li").filter({ hasText: statusToPin }).dispatchEvent("click");
		}
		
		// close drop down to select statuses
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
	}
	
	
	// 'Resource Schedule Optimization' section
	{
		
		const resourceScheduleOptimizationSection = (
			frame
			.locator("optimization-logic")
			.locator(".guarded-optimization-container")
			.filter({ 
				has: frame.locator(".optimization-title").filter({
					hasText: "Resource Schedule Optimization"
				})
			})
		);
		
		await resourceScheduleOptimizationSection.waitFor();
		
		
		const multiselectComponentContainer = resourceScheduleOptimizationSection.locator(".multiselect-component-container");
		
		// clear all selected options first
		await multiselectComponentContainer.waitFor();
		const selectedOptionsLocator = multiselectComponentContainer.locator(".multiselect-pillars-container .multiselect-pillar");
		
		for (const selectedOptionLocator of await selectedOptionsLocator.all()) {
			if (await selectedOptionLocator.isVisible()) {
				await selectedOptionLocator.click();
			}
		}
		
		// open drop down to select status
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
		// select statuses
		for (const statusToPin of RESOURCE_OPTIMIZATION_PINNED_STATUSES) {
			await multiselectComponentContainer.locator("ul li").filter({ hasText: statusToPin }).dispatchEvent("click");
		}
		
		// close drop down to select statuses
		await multiselectComponentContainer.locator(".multi-dropdown-button").dispatchEvent("click");
		
	}
	
	
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



for (
	const appToSetCustomAttributes
	of 
	APPS_TO_SET_CUSTOM_ATTRIBUTES
) {
	
	for (
		const appAttributeToSet
		of
		appToSetCustomAttributes.attributes
	) {
		
		test(`Setup -> App Manager -> Set Custom Attribute ${appAttributeToSet.name} for ${appToSetCustomAttributes.name} connected app`, async ({ basePage, baseUrl }) => {
			
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
				.filter({ hasText: appToSetCustomAttributes.name })
				.getByRole('button')
				.click({ force: true });
			
			await utils.clickMenuItem(basePage, "Manage");
			
			
			let frame = basePage.frameLocator("iframe[tabindex='0'][title^='Connected App']");
			
			// wait for custom attributes table to be loaded
			const customAttributesTableLocator = frame
				.locator("table")
				.filter({ has: frame.getByText("Attribute key") });
				
			await customAttributesTableLocator.waitFor();
			
			// check if custom attribute already exists
			const targetCustomAttributesRowLocator = customAttributesTableLocator
				.locator("tr")
				.filter({ has: frame.getByText(appAttributeToSet.name, { exact: true }) });
			
			let doesCustomAttributeExist = await targetCustomAttributesRowLocator.isVisible();
			
			if (doesCustomAttributeExist === true) {
				
				console.log(`[${appToSetCustomAttributes.name}]: Custom attribute ${appAttributeToSet.name} exists - checking for its value...`);
				
				await utils.clickLink(targetCustomAttributesRowLocator, "Edit");
				
			} else {
				
				console.log(`[${appToSetCustomAttributes.name}]: Custom attribute ${appAttributeToSet.name} doesn't exist - creating new one...`);
				
				await frame.locator("input[title^='New Custom Attribute']").click({ force: true });
				
			}
			
			
			frame = basePage.frameLocator("iframe[tabindex='0'][title*='Attribute']");
			
			const customAttributeNameInputLocator = frame.getByLabel("Attribute key");
			const customAttributeValueInputLocator = frame.locator("textarea[name='value']");
			
			// grab current attribute value from new/edit form
			const customAttributeValue = await customAttributeValueInputLocator.inputValue();
			
			// check if attribute value needs to be updated
			if (customAttributeValue === appAttributeToSet.value) {
				
				console.log(`[${appToSetCustomAttributes.name}]: Custom attribute ${appAttributeToSet.name} already has value ${appAttributeToSet.value} - nothing to do here.`);
				
			// create/update attribute value
			} else {
				
				await customAttributeNameInputLocator.fill(appAttributeToSet.name);
				await customAttributeValueInputLocator.fill(appAttributeToSet.value);
				
				await utils.clickButton(frame, "Save");
				
				await customAttributesTableLocator.waitFor();
				
				console.log(`[${appToSetCustomAttributes.name}]: Custom attribute ${appAttributeToSet.name} has been set to ${appAttributeToSet.value}.`);
				
			}
			
		});
		
	}
	
}


