
*** Settings ***
Documentation  			Test example with QWeb
Library					QWeb

#Resource				../resources/common.robot
Suite Setup				Setup Browser
Suite Teardown			End Suite


*** Variables ***
${BROWSER}				Chrome
${SF_LOGIN_URL}			${INSTANCE_URL}/secur/frontdoor.jsp?sid=${ACCESS_TOKEN}&retURL=/ltng/switcher?destination=lex



*** Keywords ***

Setup Browser
	
	Set Library Search Order				QWeb
	OpenBrowser			about:blank			${BROWSER}		--headless
	SetConfig			LineBreak			${EMPTY}
	SetConfig			DefaultTimeout		30s

End Suite
	CloseAllBrowsers


*** Test Cases ***
Log In to SF
	[Documentation]			Log in to SF by token
	GoTo					${SF_LOGIN_URL}
	ClickText				Setup
	VerifyTitle				Home | Salesforce


