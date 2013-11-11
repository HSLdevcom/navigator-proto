*** Settings ***

Library  Selenium2Library  timeout=${SELENIUM_TIMEOUT}
...                        implicit_wait=${SELENIUM_IMPLICIT_WAIT}

Resource  Selenium2Screenshots/keywords.robot

*** Variables ***

${HOSTNAME}  localhost
${PORT}  9001
${START_URL}  http://${HOSTNAME}:${PORT}/#testem

${SELENIUM_IMPLICIT_WAIT}  0.5
${SELENIUM_TIMEOUT}  30

${BROWSER}  Firefox
${REMOTE_URL}
${FF_PROFILE_DIR}

${counter}  0

*** Keywords ***

Open test browser
    Open browser  ${START_URL}  ${BROWSER}
    ...           remote_url=${REMOTE_URL}
    ...           ff_profile_dir=${FF_PROFILE_DIR}
    Set window size  400  800

Wait until location is
    [Arguments]  ${expected_url}
    ${TIMEOUT} =  Get Selenium timeout
    ${IMPLICIT_WAIT} =  Get Selenium implicit wait
    Wait until keyword succeeds  ${TIMEOUT}  ${IMPLICIT_WAIT}
    ...                          Location should be  ${expected_url}

Possibly stale element should not be visible
    [Arguments]  ${locator}
    @{value} =  Run keyword and ignore error
    ...         Element should not be visible  ${locator}
    Should be equal  @{value}[0]  PASS

Element should not remain visible
    [Documentation]  Due to the internals of Selenium2Library, a disappearing
    ...              element may rise StaleElementReferenceException (element
    ...              disappears between it's located and inspected). This
    ...              keyword is a workaround that tries again until success.
    [Arguments]  ${locator}
    ${timeout} =  Get Selenium timeout
    ${implicit_wait} =  Get Selenium implicit wait
    Wait until keyword succeeds  ${timeout}  ${implicit_wait}
    ...                          Possibly stale element should not be visible
    ...                          ${locator}

Possibly stale element should become visible
    [Arguments]  ${locator}
    @{value} =  Run keyword and ignore error
    ...         Element should be visible  ${locator}
    Should be equal  @{value}[0]  PASS

Element should become visible
    [Documentation]  Due to the internals of Selenium2Library, an appearing
    ...              element may rise StaleElementReferenceException (element
    ...              disappears between it's located and inspected). This
    ...              keyword is a workaround that tries again until success.
    [Arguments]  ${locator}
    ${timeout} =  Get Selenium timeout
    ${implicit_wait} =  Get Selenium implicit wait
    Wait until keyword succeeds  ${timeout}  ${implicit_wait}
    ...                          Possibly stale element should become visible
    ...                          ${locator}

Input text for sure
    [Documentation]  Locate input element by ${locator} and enter the given
    ...              ${text}. Validate that the text has been entered.
    ...              Retry until the set Selenium timeout. (The purpose of
    ...              this keyword is to fix random input issues on slow test
    ...              machines.)
    [Arguments]  ${locator}  ${text}
    ${timeout} =  Get Selenium timeout
    ${implicit_wait} =  Get Selenium implicit wait
    Wait until keyword succeeds  ${timeout}  ${implicit_wait}
    ...                          Input text and validate  ${locator}  ${text}

Input text and validate
    [Documentation]  Locate input element by ${locator} and enter the given
    ...              ${text}. Validate that the text has been entered.
    [Arguments]  ${locator}  ${text}
    Focus  ${locator}
    Input text  ${locator}  ${text}
    ${value} =  Get value  ${locator}
    Should be equal  ${text}  ${value}

Click link '${text}'
   Assign id to element
   ...    xpath=//div[contains(concat(' ',normalize-space(@class),' '),' ui-page-active ')]//*[contains(text(), '${text}')]/ancestor::a
   ...    link-${counter}
   Element should be visible  link-${counter}
   Click element  link-${counter}
   Increment counter

Click link "${text}"
   Assign id to element
   ...    xpath=//div[contains(concat(' ',normalize-space(@class),' '),' ui-page-active ')]//*[contains(text(), "${text}")]/ancestor::a
   ...    link-${counter}
   Element should be visible  link-${counter}
   Click element  link-${counter}
   Increment counter

Increment counter
   ${counter} =  Evaluate  ${counter} + 1
   Set suite variable  ${counter}  ${counter}

Pause
   Import library  Dialogs
   Pause execution
