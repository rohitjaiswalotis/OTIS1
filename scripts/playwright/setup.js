// @ts-check

const { test: base, expect } = require.main.require('@playwright/test');


exports.test = base.extend({
	
	basePage: async ({ baseURL, page }, use) => {
		
		// log in with access token
		if (process.env.PLAYWRIGHT_ACCESS_TOKEN && process.env.PLAYWRIGHT_INSTANCE_URL) {
			
			await page.goto(`${process.env.PLAYWRIGHT_INSTANCE_URL}/secur/frontdoor.jsp?sid=${process.env.PLAYWRIGHT_ACCESS_TOKEN}&retURL=/ltng/switcher?destination=lex`);
			
		// log in with username and password
		} else if (process.env.PLAYWRIGHT_USERNAME && process.env.PLAYWRIGHT_PASSWORD && process.env.PLAYWRIGHT_INSTANCE_URL) {
			
			await page.goto(process.env.PLAYWRIGHT_INSTANCE_URL);
			
			await page.getByLabel("Username").fill(process.env.PLAYWRIGHT_USERNAME);
			await page.getByLabel("Password").fill(process.env.PLAYWRIGHT_PASSWORD);
			
			await page.getByRole("button", { name: /log in/i }).click();
			
		} else {
			
			throw new Error("Username/password or access token should be provided to log in!");
			
		}

		// assert logged in page open
		await expect(page).toHaveTitle(/Salesforce/);
		await expect(page.locator("div.appLauncher")).toBeVisible();
		await expect(page.locator("div.setupGear")).toBeVisible();
		
		
		await use(page);
	
	},
	
	
	baseUrl: async ({ basePage }, use) => {
		
		let urlParts = basePage.url().split("/");
		
		await use(urlParts[0] + "//" + urlParts[2]);
		
	}
	
});


exports.expect = base.expect;

