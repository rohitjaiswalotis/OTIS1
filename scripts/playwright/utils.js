

export const FIELD_SERVICE_SETTINGS_URL = `/lightning/n/FSL__Field_Service_Settings`;


export const openSettings = async (basePage, baseUrl) => {
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
}


export const getMainFrame = (basePage) => {
	
	return basePage.frameLocator('iframe[tabindex="0"]');
	
}


export const switchToSettingsMenu = async (root, menuLabel) => {
	
	await root.locator('#SettingsMenu').getByText(menuLabel, { exact: true }).locator('visible=true').click();
	
}


export const switchToSettingsTab = async (root, tabLabel) => {
	
	await root.getByText(tabLabel).locator('visible=true').click();
	
}


export const getBooleanSettingLocator = (root, label) => {
	
	const booleanSettingLocator = root.locator('boolean-setting');
	const booleanTextSettingLocator = root.locator('boolean-text-setting');
	
	return booleanSettingLocator.or(booleanTextSettingLocator).filter({ hasText: label });
	
}


export const checkBooleanSetting = async (root, label) => {
	
	await getBooleanSettingLocator(root, label).getByRole('checkbox').check({ force: true });
	
}


export const checkOptinalBooleanSetting = async (root, label) => {
	
	if (await getBooleanSettingLocator(root, label).isVisible()) {
		
		await checkBooleanSetting(root, label);
		
	} else {
		
		console.log(`WARNING: Optional boolean settings '${label}' not available!`);
		
	}
	
}


export const uncheckBooleanSetting = async (root, label) => {
	
	await getBooleanSettingLocator(root, label).getByRole('checkbox').uncheck({ force: true });
	
}


export const uncheckOptinalBooleanSetting = async (root, label) => {
	
	if (await getBooleanSettingLocator(root, label).isVisible()) {
		
		await uncheckBooleanSetting(root, label);
		
	} else {
		
		console.log(`WARNING: Optional boolean settings '${label}' not available!`);
		
	}
	
}


export const selectPicklistSettingByLabel = async (root, label, optionLabel) => {
	
	await root.getByLabel(label).locator('visible=true').selectOption({ label: optionLabel });
	
}


export const selectPicklistSettingByValue = async (root, label, optionValue) => {
	
	await root.getByLabel(label).locator('visible=true').selectOption(optionValue);
	
}


export const fillSetting = async (root, label, value) => {
	
	await root.getByLabel(label).locator('visible=true').fill(value ? String(value) : '');
	
}


export const setCheckboxesInGroup = async (root, container, { resetAll = true, labelsToCheck = new Set(), labelsToUncheck = new Set() } = { resetAll: true }) => {
	
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


export const clickSaveSettingButton = async (root) => {
	
	// click Save button
	await root.locator('.save-button').locator('visible=true').click();
	
	// wait for success banner to appear
	await root.locator('.saving-banner.settings-saved').locator('visible=true').waitFor();
	
}


export const clickButton = async (root, label) => {
	
	await root.getByRole("button").filter({ hasText: label }).click({ force: true });
	
}


export const waitForButton = async (root, label) => {
	
	await root.getByRole("button").filter({ hasText: label }).waitFor();
	
}


export const clickMenuItem = async (root, label) => {
	
	await root.getByRole("menuitem").locator('visible=true').getByText(label).click({ force: true });
	
}


export class CaseInsensitiveSet extends Set {
	
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

