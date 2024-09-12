

export const FIELD_SERVICE_SETTINGS_URL = `/lightning/n/FSL__Field_Service_Settings`;



export const acceptDialog = (basePage) => {
	
	basePage.on('dialog', dialog => dialog.accept());
	
}



export const openSettings = async (basePage, baseUrl) => {
	
	acceptDialog(basePage);
	
	await basePage.goto(baseUrl + FIELD_SERVICE_SETTINGS_URL);
	
}


export const getMainFrame = (basePage) => {
	
	return basePage.frameLocator('iframe[tabindex="0"]');
	
}


export const getMainFrameWithTitlePrefix = (basePage, titlePrefix) => {
	
	return basePage.frameLocator(`iframe[tabindex='0'][title^='${titlePrefix}']`);
	
}


export const getMainFrameWithTitleContains = (basePage, titleMarker) => {
	
	return basePage.frameLocator(`iframe[tabindex='0'][title*='${titleMarker}']`);
	
}


export const switchToSettingsMenu = async (root, menuLabel) => {
	
	await root.locator('#SettingsMenu').getByText(menuLabel, { exact: true }).locator('visible=true').click();
	
}


export const switchToSettingsTab = async (root, tabLabel) => {
	
	await root.getByText(tabLabel).locator('visible=true').click();
	
}


export const getBooleanSettingLocator = (root, labelPositive, labelNegative) => {
	
	const booleanSettingLocator = root.locator('boolean-setting');
	const booleanTextSettingLocator = root.locator('boolean-text-setting');
	
	let componentFilter = {};
	
	if (labelPositive) {
		componentFilter.hasText = labelPositive;
	}
	
	if (labelNegative) {
		componentFilter.hasNotText = labelNegative;
	}
	
	return booleanSettingLocator.or(booleanTextSettingLocator).filter(componentFilter);
	
}


export const checkBooleanSetting = async (root, labelPositive, labelNegative) => {
	
	let checkboxLocator = getBooleanSettingLocator(root, labelPositive, labelNegative).getByRole('checkbox');
	
	try {
		
		await checkboxLocator.check({ force: true });
		
	} catch (error) {
		
		console.log(`Error when ticking boolean settings '${labelPositive}' checkbox!`);
		console.log(error);
		
		console.log(`Trying alternative approach to tick boolean settings '${labelPositive}' checkbox...`);
		
		if ( (await checkboxLocator.isChecked()) !== true ) {
			await checkboxLocator.dispatchEvent("click");
		}
		
	}
	
}


export const checkOptionalBooleanSetting = async (root, labelPositive, labelNegative) => {
	
	if (await getBooleanSettingLocator(root, labelPositive, labelNegative).isVisible()) {
		
		await checkBooleanSetting(root, labelPositive, labelNegative);
		
	} else {
		
		console.log(`WARNING: Optional boolean settings '${labelPositive}' not available!`);
		
	}
	
}


export const uncheckBooleanSetting = async (root, labelPositive, labelNegative) => {
	
	let checkboxLocator = getBooleanSettingLocator(root, labelPositive, labelNegative).getByRole('checkbox');
	
	try {
		
		await checkboxLocator.uncheck({ force: true });
		
	} catch (error) {
		
		console.log(`Error when unticking boolean settings '${labelPositive}' checkbox!`);
		console.log(error);
		
		console.log(`Trying alternative approach to untick boolean settings '${labelPositive}' checkbox...`);
		
		if ( (await checkboxLocator.isChecked()) === true ) {
			await checkboxLocator.dispatchEvent("click");
		}
		
	}
	
}


export const uncheckOptionalBooleanSetting = async (root, labelPositive, labelNegative) => {
	
	if (await getBooleanSettingLocator(root, labelPositive, labelNegative).isVisible()) {
		
		await uncheckBooleanSetting(root, labelPositive, labelNegative);
		
	} else {
		
		console.log(`WARNING: Optional boolean settings '${labelPositive}' not available!`);
		
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


export const setCheckboxes = async (root, labels, exactMatch = true) => {
	
	for (const label of labels) {
		
		await root.getByRole(
			"checkbox", 
			{ 
				name: label, 
				exact: exactMatch 
			}
		).check(
			{
				force: true 
			}
		);
		
	}
	
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


export const setRadio = async (root, label, exactMatch = true) => {
	
	await root.getByRole("radio", { name: label, exact: exactMatch }).check({ force: true });
	
}


export const getPicklistOptions = async (root, label) => {
	
	await waitForLabel(root, label);
	
	let selectedOptions = [];
	
	for (const selectedOptionLocator of await root.getByLabel(label).locator('option').all()) {
		
		selectedOptions.push(
			await selectedOptionLocator.textContent()
		);
		
	}
	
	return selectedOptions;
	
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


export const clickLink = async (root, label) => {
	
	await root.getByRole("link", { name: label }).click();
	
}


export const clickCombobox = async (root, label, exactMatch = true) => {
	
	await root.getByRole("combobox", { name: label, exact: exactMatch }).click({ force: true });
	
}


export const waitForLink = async (root, label) => {
	
	await root.getByRole("link", { name: label }).waitFor();
	
}


export const waitForLabel = async (root, label) => {
	
	await root.getByLabel(label).waitFor();
	
}


export const clickByText = async (root, text, exactMatch = true) => {
	
	await root.getByText(text, { exact: exactMatch }).click({ force: true });
	
}


export const clickByTitle = async (root, text, exactMatch = true) => {
	
	await root.getByTitle(text, { exact: exactMatch }).click({ force: true });
	
}


export const waitToDisappear = async (root) => {
	
	await root.waitFor({ "state" : "hidden" });
	
}


export const isEquivalent = (source, target) => {
	
	return (
		(
			source === null
			&&
			target === null
		)
		||
		(
			String(source).trim().toLowerCase()
			===
			String(target).trim().toLowerCase()
		)
	);
	
}


export class CaseInsensitiveSet extends Set {
	
	constructor(values = []) {
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

