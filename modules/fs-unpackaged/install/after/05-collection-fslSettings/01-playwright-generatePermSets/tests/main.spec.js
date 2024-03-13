// @ts-check

const basePath = (process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../../..");

const { test, expect } = require(basePath + "/scripts/playwright/setup");
const utils = require(basePath + "/scripts/playwright/utils");


test('Generate FSL Permission Sets', async ({ basePage, baseUrl }) => {
	
	await utils.openSettings(basePage, baseUrl);
	
	const frame = utils.getMainFrame(basePage);
	
	await utils.switchToSettingsMenu(frame, "Getting Started");
	
	await utils.switchToSettingsTab(frame, "PERMISSION SETS");
	
	
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

