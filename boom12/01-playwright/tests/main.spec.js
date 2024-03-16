// @ts-check

const basePath = (process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../../../../..");

const { test, expect } = require(basePath + "/scripts/playwright/setup");
const utils = require(basePath + "/scripts/playwright/utils");

const APPS_TO_RELAX_IP = [ 
	"Salesforce Field Service for Android"
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
		
		await basePage.mouse.wheel(0, +40);
		
		let count = await appsTable.getByRole("row").locator("tr").count();
		console.log(`AAAAAAAAAAAAAAAAAAAAAA = ${count}`);
		
		await appsTable
			.getByRole("row")
			.locator("tr").filter({ has: basePage.getByText(appToRelaxIp) })
			//.filter({ hasText: appToRelaxIp })
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

