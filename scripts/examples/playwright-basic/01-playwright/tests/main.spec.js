// @ts-check

const { test, expect } = require((process.env.PLAYWRIGHT_WORKING_DIR || process.env.BUILD_SOURCESDIRECTORY || "../../../..") + "/scripts/playwright/setup")


const THEME_CODE_TO_ACTIVATE = "cs"; // Cloudy Sky Theme
const THEME_SETUP_URL = `/lightning/setup/ThemingAndBranding/${THEME_CODE_TO_ACTIVATE}/view`;

const APP_NAME_TO_MOVE_TO_TOP = "Otis Service Console";
const APP_MENU_SETUP_URL = `/lightning/setup/AppMenu/home`;



test('Activate Theme', async ({ basePage, baseUrl }) => {
	
	await basePage.goto(baseUrl + THEME_SETUP_URL);
	
	await expect(basePage.getByText("View Cloudy Sky Theme")).toBeVisible();
	
	await basePage.getByText("Activate").click();
	
	await expect(basePage.getByText("View Cloudy Sky Theme")).toBeVisible();
	
});



test('Move OTIS app to top', async ({ basePage, baseUrl }) => {
	
	await basePage.goto(baseUrl + APP_MENU_SETUP_URL);
	
	
	while(true) {
		
		let otisApp = await basePage.locator(".uiDraggable", { has: basePage.locator(`text="${APP_NAME_TO_MOVE_TO_TOP}"`) });
		await otisApp.hover();
		
		let appsAbove = await basePage.locator(`.uiDraggable:above(:text("${APP_NAME_TO_MOVE_TO_TOP}"))`);
		let appsAboveCount = await appsAbove.count();
		
		if (appsAboveCount <= 0) {
			break;
		}
		
		let appAbove = await appsAbove.first();
		
		await basePage.mouse.down();
		await appAbove.hover();
		await otisApp.hover();
		await basePage.mouse.up();
		
	}
	
});

