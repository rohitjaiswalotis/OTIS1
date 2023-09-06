
*** Settings ***
Documentation  			Test example with Selenium Library
Library					SeleniumLibrary

#Resource				../resources/common.robot
#Suite Setup			Setup Browser
#Suite Teardown			End suite


*** Variables ***
#${BROWSER}				Chrome
${BROWSER}				headlesschrome
${SF_LOGIN_URL}			${INSTANCE_URL}/secur/frontdoor.jsp?sid=${ACCESS_TOKEN}&retURL=/ltng/switcher?destination=lex


*** Keywords ***


*** Test Cases ***
Log In to SF
	[Documentation]					Log in to SF by token
	Open Browser  					${SF_LOGIN_URL}  	${BROWSER}
	Wait Until Element Is Visible	css:div.appLauncher
	Wait Until Element Is Visible	css:div.setupGear
	Close Browser


