*** Settings ***

Resource  selenium.robot

Test setup  Open test browser
Test teardown  Close all browsers

*** Variables ***

${counter}  0

*** Test cases ***

App is loaded
    When start app
    Then front page

Find nearest services
    Given front page
    When click link 'Menu'
    And click link 'Find nearest services'
    And no front page

*** Keywords ***

Start app
    Go to  ${START_URL}

Front page
    Element should become visible  css=#front-page
    Element should become visible  css=#front-page h1.ui-title
    Element should contain  css=#front-page h1.ui-title  Navigator

No front page
    Element should not remain visible  css=#front-page

Click link '${text}'
    Assign id to element
    ...    xpath=//*[contains(text(), '${text}')]/ancestor::a
    ...    link-${counter}
    Element should be visible  link-${counter}
    Click element  link-${counter}
    Increment counter

Increment counter
    ${counter} =  Evaluate  ${counter} + 1
    Set suite variable  ${counter}  ${counter}
