
"use strict";


const puppeteer = require.main.require("puppeteer");
const BasicUtils = require("./../utils/BasicUtils.js");


// GLOBAL CONSTANTS
global.DEFAULT_TIMEOUT = 60000;
global.SHORT_TIMEOUT = DEFAULT_TIMEOUT / 5;
global.LONG_TIMEOUT = DEFAULT_TIMEOUT * 5;
global.VERY_LONG_TIMEOUT = LONG_TIMEOUT * 3;
global.INFINITE_TIMEOUT = DEFAULT_TIMEOUT * 1000;


// LOCAL CONSTANTS

// log in
const DEFAULT_LOGIN_RETRY_TIMES = 3;
const DEFAULT_LOGIN_RETRY_PAUSE = 30 * 1000; // 30 sec

// paths
const SWITCH_TO_CLASSIC_PATH = "/ltng/switcher?destination=classic";
const SWITCH_TO_LIGHTNING_PATH = "/ltng/switcher?destination=lex";

// toast (any type)
const TOAST_NOTIF_SELECTOR = ".toastContainer .slds-notify--toast";
const TOAST_NOTIF_CLOSE_BUTTON_SELECTOR = TOAST_NOTIF_SELECTOR + " .slds-button.toastClose";

// success toast
const SUCCESS_TOAST_NOTIF_SELECTOR = TOAST_NOTIF_SELECTOR + ".slds-theme--success";
const SUCCESS_TOAST_NOTIF_CLOSE_BUTTON_SELECTOR = SUCCESS_TOAST_NOTIF_SELECTOR + " .slds-button.toastClose";

// error toast
const ERROR_TOAST_NOTIF_SELECTOR = TOAST_NOTIF_SELECTOR + ".slds-theme--error";
const ERROR_TOAST_NOTIF_CLOSE_BUTTON_SELECTOR = ERROR_TOAST_NOTIF_SELECTOR + " .slds-button.toastClose";


const DEFAULT_COMMON_BROWSER_OPTIONS = {
	slowMo: 	40,
	//headless: 'new'
	headless: true
	//headless: false
	/*
	devtools: true,
	slowMo: 40,
	args: [`--window-size=1920,1080`]
	*/
}


class BasicService {	
	
	
	static async getInstance(userOptions = {}) {
		
		let basicService = new BasicService();
		
		await basicService.init(userOptions);
		
		return basicService;
	
	}
	
	
	
	constructor() {
		
	}
	
	
	async init(userOptions = {}) {
		
		this.browser = (
			process.env.PUPPETEER_REMOTE_ENDPOINT
			?
			(await puppeteer.connect(
				this.options 
				=
				Object.assign(
					{},
					DEFAULT_COMMON_BROWSER_OPTIONS,
					{
						browserWSEndpoint: process.env.PUPPETEER_REMOTE_ENDPOINT
					},
					userOptions
				)
			))
			:
			(await puppeteer.launch(
				this.options
				=
				Object.assign(
					{},
					DEFAULT_COMMON_BROWSER_OPTIONS,
					userOptions
				)
			))
		);
		
		
		this.page = await this.browser.newPage();
		
	}
	
	
	async cleanup() {
		
		if (this.browser) {
			
			await this.browser.close();
			
		}
		
	}
	
	
	async logIn(options, lightningMode=true) {
		
		let token = options.sessionId || options.accessToken;
		
		return BasicUtils.callWithRetry(
			async () => {
				let urlAfterLogIn = (
					token
					?
						await this.logInWithToken(options.instanceUrl, token)
						:
						await this.logInWithCreds(options.instanceUrl, options.userName, options.password)
				);
				return Promise.resolve(urlAfterLogIn);
			},
			[],
			DEFAULT_LOGIN_RETRY_TIMES,
			DEFAULT_LOGIN_RETRY_PAUSE
		);
		
	}
	
	
	// log in with token
	async logInWithToken(url, token, lightningMode=true) {
		
		BasicService.logMessage("Logging in to the system with token...");
		
		let tokenLogInUrl = `${url}/secur/frontdoor.jsp?sid=${token}`;
		
		let fullLogInUrl = (
			tokenLogInUrl +
			(tokenLogInUrl.indexOf("?") > -1 ? "&" : "?") + 
			"retURL=" + (lightningMode ? SWITCH_TO_LIGHTNING_PATH : SWITCH_TO_CLASSIC_PATH)
		);
		
		await this.page.goto(fullLogInUrl);
		
		//await this.page.waitForNavigation({ timeout: DEFAULT_TIMEOUT });
		await this.page.waitForFunction("!window.location.pathname.toLowerCase().includes('/secur/')");
		
		let pageUrl = this.page.url();
		BasicService.logMessage(`Current Page Url = ${pageUrl}`);
		
		
		// in case of 'change password' window - bypass it by clicking cancel
		await this._handleChangePasswordWindow(lightningMode);
		
		// in case of 'maintenance/downtime' window - bypass it by acknowledging
		await this._handleMaintenanceDowntimeWindow(lightningMode);
		
		// in case of 'register mobile phone' window - bypass it by clicking cancel
		await this._handleRegisterMobilePhone(lightningMode);
		
		
		this.baseUrl = this.page.url();
		BasicService.logMessage(`Base Url = ${this.baseUrl}`);
		
		return this.baseUrl;
		
	}
	
	
	// log in with credentials
	async logInWithCreds(url, userName, password, lightningMode=true) {
		
		BasicService.logMessage("Logging in to the system with credentials...");
		
		let fullLogInUrl = (
			url +
			(url.indexOf("?") > -1 ? "&" : "?") + 
			"retURL=" + (lightningMode ? SWITCH_TO_LIGHTNING_PATH : SWITCH_TO_CLASSIC_PATH)
		);
		
		await this.page.goto(fullLogInUrl);
		
		const userNameInput = await this.page.$("input[name='username']");
		const passwordInput = await this.page.$("input[name='pw']");
		const submitButton = await this.page.$("input[name='Login']");
		
		await userNameInput.type(userName);
		await passwordInput.type(password);
		
		await submitButton.click();
		BasicService.logMessage("'Log In button' has been clicked");
		
		await this.page.waitForNavigation({ waitUntil: "networkidle0", timeout: LONG_TIMEOUT });
		await this.page.waitForFunction("!window.location.href.toLowerCase().includes('login.salesforce.com')");
		await this.page.waitForFunction("!window.location.href.toLowerCase().includes('test.salesforce.com')");
		await this.page.waitForFunction("!window.location.pathname.toLowerCase().includes('/secur/')");
		
		let pageUrl = this.page.url();
		BasicService.logMessage(`Current Page Url = ${pageUrl}`);
		
		
		// in case of 'change password' window - bypass it by clicking cancel
		await this._handleChangePasswordWindow(lightningMode);
		
		// in case of 'maintenance/downtime' window - bypass it by acknowledging
		await this._handleMaintenanceDowntimeWindow(lightningMode);
		
		// in case of 'register mobile phone' window - bypass it by clicking cancel
		await this._handleRegisterMobilePhone(lightningMode);
		
		
		this.baseUrl = this.page.url();
		BasicService.logMessage(`Base Url = ${this.baseUrl}`);
		
		return this.baseUrl;
		
	}
	
	
	async _handleChangePasswordWindow(lightningMode=true) {
		
		let pageUrl = this.page.url();
		
		// early exit - not a Change Password window
		if (!pageUrl.toLowerCase().includes("system/security/ChangePassword".toLowerCase())) {
			return;
		}
		
		
		// bypass Change Password window by clicking cancel
		{
			
			BasicService.logMessage("Detected 'Change Password' window - trying to bypass it by clicking Cancel");
			
			const cancelButton = await this.page.$("#cancel-button");
			
			await cancelButton.click();
			BasicService.logMessage("Cancel button has been clicked");
			
			try {
				
				await this.page.waitForSelector(
					lightningMode ? ".slds-global-header" : "#AppBodyHeader",
					{
						timeout: LONG_TIMEOUT
					}
				);
				
			} catch (changePasswordCancelTimeoutError) {
				
				BasicService.logError(changePasswordCancelTimeoutError);
				
				BasicService.logWarning(
					"Timed out while waiting for start page to open after cancelling 'Change Password'. Proceeding on our own risk."
				);
				
			}
			
			pageUrl = this.page.url();
			BasicService.logMessage(`Current Page Url = ${pageUrl}`);
			
		}
		
	}
	
	
	async _handleMaintenanceDowntimeWindow(lightningMode=true) {
		
		let pageUrl = this.page.url();
		
		// early exit - not a Maintenance/Downtime window
		if (!pageUrl.toLowerCase().includes("/downtime".toLowerCase())) {
			return;
		}
		
		
		// bypass Maintenance/Downtime window by acknowledging it
		{
			
			BasicService.logMessage("Detected 'Downtime/Maintenance' window - trying to bypass it by acknowledging, i.e. clicking 'Got it' or whatever");
			
			const acknowledgeButton = await this.page.$("a.continue");
			
			await acknowledgeButton.click();
			BasicService.logMessage("Acknowledge button has been clicked");
			
			try {
				
				await this.page.waitForSelector(
					lightningMode ? ".slds-global-header" : "#AppBodyHeader",
					{
						timeout: LONG_TIMEOUT
					}
				);
				
			} catch (maintenanceDowntimeAcknowledgeTimeoutError) {
				
				BasicService.logError(maintenanceDowntimeAcknowledgeTimeoutError);
				
				BasicService.logWarning(
					"Timed out while waiting for start page to open after acknowledging 'Maintenance/Downtime'. Proceeding on our own risk."
				);
				
			}
			
			pageUrl = this.page.url();
			BasicService.logMessage(`Current Page Url = ${pageUrl}`);
			
		}
		
	}
	
	
	async _handleRegisterMobilePhone(lightningMode=true) {
		
		let pageUrl = this.page.url();
		
		// early exit - not a Register Mobile Phone window
		if (!pageUrl.toLowerCase().includes("phone/AddPhoneNumber".toLowerCase())) {
			return;
		}
		
		
		// bypass Register Mobile Phone window by clicking cancel
		{	
			
			BasicService.logMessage("Detected 'Register Mobile Phone' window - trying to bypass it by clicking at cancellation link");
			
			await this.clickByTextExact("I Don't Want to Register My Phone", "*");
			BasicService.logMessage("Cancel link has been clicked");
			
			try {
				
				await this.page.waitForSelector(
					lightningMode ? ".slds-global-header" : "#AppBodyHeader",
					{
						timeout: LONG_TIMEOUT
					}
				);
				
			} catch (registerMobilePhoneCancelTimeoutError) {
				
				BasicService.logError(registerMobilePhoneCancelTimeoutError);
				
				BasicService.logWarning(
					"Timed out while waiting for start page to open after cancelling 'Register Mobile Phone'. Proceeding on our own risk."
				);
				
			}
			
			pageUrl = this.page.url();
			BasicService.logMessage(`Current Page Url = ${pageUrl}`);
			
		}
		
	}
	
	
	
	// switch to lightning mode
	async switchToLightning() {
		
		await this.page.goto(this.baseUrl + SWITCH_TO_LIGHTNING_PATH);
		
		await this.page.waitForSelector(
			".slds-global-header", 
			{
				timeout: LONG_TIMEOUT
			}
		);
		
	}
	
	
	// switch to classic mode
	async switchToClassic() {
		
		await this.page.goto(this.baseUrl + SWITCH_TO_CLASSIC_PATH);
		
		await this.page.waitForSelector(
			"#AppBodyHeader",
			{
				timeout: DEFAULT_TIMEOUT
			}
		);
		
	}
	
	
	async goToPage(relativeUrl) {
		
		// navigate to app launcher page
		await this.page.goto(
			
			// extract only protocol and host part from current url
			this.baseUrl.substr(
				0, 
				this.baseUrl.indexOf(
					'/', 
					this.baseUrl.indexOf('://') + 3
				)
			)
			
			+ 
			
			// append relative path
			relativeUrl
			
		);
		
	}
	
	
	async switchToFrame(selector, hidden=false) {
		
		this.frame = await (
			await this.page.waitForSelector(
				selector,
				{
					timeout: LONG_TIMEOUT,
					hidden: hidden
				}
			)
		)?.contentFrame();
		
	}
	
	
	async switchBetweenFrames(sourceSelector, destinationSelector=sourceSelector) {
		
		await this.switchToFrame(sourceSelector, true);
		await this.switchToFrame(destinationSelector);
		
	}
	
	
	async tickCheckbox(selector) {
		
		let checkbox = await this.frame.waitForSelector(selector);
		let currentState = await (await checkbox.getProperty("checked")).jsonValue();
		
		if (currentState === true) {
			return false;
		}
		
		await checkbox.click();
		
		return true;
		
	}
	
	
	async untickCheckbox(selector) {
		
		let checkbox = await this.frame.waitForSelector(selector);
		let currentState = await (await checkbox.getProperty("checked")).jsonValue();
		
		if (currentState === false) {
			return false;
		}
		
		await checkbox.click();
		
		return true;
		
	}
	
	
	async closeToast() {
		
		const closeButton = await this.page.$(TOAST_NOTIF_CLOSE_BUTTON_SELECTOR);
		
		await closeButton.click();
		
	}
	
	
	async closeOptionalToast() {
		
		try {
			
			await this.closeToast();
			
		} catch(error) {
			
			// deliberately suppressing error assuming no error toast present
			
		}
		
	}
	
	
	async closeSuccessToast() {
		
		const closeButton = await this.page.$(SUCCESS_TOAST_NOTIF_CLOSE_BUTTON_SELECTOR);
		
		await closeButton.click();
		
	}
	
	
	async closeOptionalSuccessToast() {
		
		try {
			
			await this.closeSuccessToast();
			
		} catch(error) {
			
			// deliberately suppressing error assuming no error toast present
			
		}
		
	}
	
	
	async closeErrorToast() {
		
		const closeButton = await this.page.$(ERROR_TOAST_NOTIF_CLOSE_BUTTON_SELECTOR);
		
		await closeButton.click();
		
	}
	
	
	async closeOptionalErrorToast() {
		
		try {
			
			await this.closeErrorToast();
			
		} catch(error) {
			
			// deliberately suppressing error assuming no error toast present
			
		}
		
	}
	
	
	async waitForText(text, timeout=DEFAULT_TIMEOUT, selector="body") {
		
		await this.page.waitForFunction(
			`document.querySelector("${selector}").innerText.includes("${text}")`,
			{
				timeout: timeout
			}
		);
		
	}
	
	
	async clickByTextContains(text, tag = "*") {
		
		await this.page.evaluate(
		
			function(text, tag, cssClass) {
				
				document.evaluate(
					`//${tag}[contains(text(), "${text}")]` + (cssClass ? `[contains(@class, "{$cssClass}")]` : ""), 
					document, 
					null, 
					XPathResult.FIRST_ORDERED_NODE_TYPE, 
					null
				).singleNodeValue.click();
			
			},
			
			text, 
			tag,
			cssClass
			
		);
		
	}
	
	
	async clickByText(text, tag, cssClass) {
		
		await this.clickByTextExact(text, tag, cssClass);
		
	}
	
	
	async clickByTextExact(text, tag = "*", cssClass = "") {
		
		await this.page.evaluate(
		
			function(text, tag, cssClass) {
				
				document.evaluate(
					`//${tag}[text() = "${text}"]` + (cssClass ? `[contains(@class, "{$cssClass}")]` : ""), 
					document, 
					null, 
					XPathResult.FIRST_ORDERED_NODE_TYPE, 
					null
				).singleNodeValue.click();
			
			},
			
			text, 
			tag,
			cssClass
			
		);
		
	}
	
	
	async checkForTextExact(text, tag = "*", cssClass = "") {
		
		return await this.page.evaluate(
		
			function(text, tag, cssClass) {
				
				return document.evaluate(
					`//${tag}[text() = "${text}"]` + (cssClass ? `[contains(@class, "{$cssClass}")]` : ""), 
					document, 
					null, 
					XPathResult.FIRST_ORDERED_NODE_TYPE, 
					null
				).singleNodeValue ? true : false;
			
			},
			
			text, 
			tag,
			cssClass
			
		);
		
	}
	
	
	async fetchText(selector) {
		
		const elementHandle = await this.page.$(selector);
		const text = await this.page.evaluate(element => element.textContent, elementHandle);
		elementHandle.dispose();
		
		return text;
		
	}
	
	
	async takeScreenshot(path, type = "jpeg", fullPage = true) {
		
		await this.page.screenshot(
			{
				path: 		path,		// e.g. "./screenshot_test.jpg"
				type: 		type,
				fullPage: 	fullPage
			}
		);
		
	}
	
	
	async wait(time) {
		return (
			new Promise(
				function(resolve) { 
					setTimeout(resolve, time);
				}
			)
		);
	}
	
	
	// log message
	static logMessage(message) {
		
		console.info("[" + BasicUtils.getUtcTimestamp() + "] " + message);
		
	}	
	
	
	// log warning
	static logWarning(warning) {
		
		console.warn("[" + BasicUtils.getUtcTimestamp() + "] " + warning);
		
	}
	
	
	// log error
	static logError(error) {
		
		console.error("[" + BasicUtils.getUtcTimestamp() + "] " + error);
		
	}
	
	
};
	
	
module.exports = BasicService;

