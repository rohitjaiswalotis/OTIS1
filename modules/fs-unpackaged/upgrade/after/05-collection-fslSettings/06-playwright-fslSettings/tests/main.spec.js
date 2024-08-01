// @ts-check

const basePath = (process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../../..");

const { test, expect } = require(basePath + "/scripts/playwright/setup");
const utils = require(basePath + "/scripts/playwright/utils");



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
	
	
	await utils.uncheckBooleanSetting(frame, "Use 1-100 priority scale");
	
	
	await utils.clickSaveSettingButton(frame);
	
});


