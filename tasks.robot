*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault

*** Variables ***
# ${URL}      https://robotsparebinindustries.com/#/robot-order
${DRIVER}   C://chromedriver
${URL_CSV}  https://robotsparebinindustries.com/orders.csv

${GLOBAL_RETRY_AMOUNT}     10x
${GLOBAL_RETRY_INTERVAL}   0.5s
${PDF_TEMP_OUTPUT_DIRECTORY}    ${CURDIR}${/}temp

*** Keywords ***
Open the robot order website
    ${URL}=    Get Secret    credentials
    Log Many      ${URL}
    Open Available Browser      ${URL}[robotsparebin]

    # Open Browser    ${URL}[robotsparebin]    chrome    executable_path=${DRIVER}
    Maximize Browser Window
    Sleep    5000ms

*** Keywords ***
Get orders
    Download  ${URL_CSV}    overwrite=True
    ${table}    Read table from CSV    orders.csv
    [Return]    ${table}

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element      xpath://button[@class="btn btn-dark" and contains(text(),"OK")]     timeout=1 minute      error=false  
    Click Element If Visible    xpath://button[@class="btn btn-dark" and contains(text(),"OK")]


*** Keywords ***
Fill the form
    [Arguments]    ${data}
    Wait Until Page Contains Element      id:head    timeout=1 minute      error=false  
    Select From List by Value    id:head    ${data}[Head]

    Wait Until Page Contains Element      id:id-body-${data}[Body]    timeout=1 minute      error=false  
    Click Element    id=id-body-${data}[Body]

    Input Text    css:input[type="number"]  ${data}[Legs]

    Wait Until Page Contains Element      id:address   timeout=1 minute      error=false  
    Input Text    id:address  ${data}[Address]


*** Keywords ***
Preview the robot 
    Wait Until Page Contains Element      id:preview     timeout=1 minute      error=false  
    Click Element If Visible    id:preview

*** Keywords ***
Submit the order 
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Process Submit

*** Keywords ***
Process Submit
    Wait Until Page Contains Element      id:order     timeout=1 minute      error=false  
    Click Element If Visible    id:order
    Wait Until Page Contains Element      id:order-completion

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${number}
    
    ${result}=   Set Variable           Receipt-${number}.pdf
    Wait Until Element Is Visible    id:order-completion
    ${sales_results_html}    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${sales_results_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${result}

    [Return]    ${result}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${number}

    ${result}=   Set Variable           Robot-${number}.png
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${result} 

    [Return]    ${result}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}        ${pdf}      ${number}
    ${files}=    Create List
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${pdf}
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${screenshot}:align=center
    Add Files To PDF    ${files}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}embed-result-${number}.pdf

*** Keywords ***
Go to order another robot
    Wait Until Page Contains Element      id:order-another    timeout=1 minute      error=false 
    Click Element If Visible    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    ${zip_file_name}    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}       

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
          Close the annoying modal
          Fill the form    ${row}
          Preview the robot
          Submit the order
          ${pdf}    Store the receipt as a PDF file    ${row}[Order number]
          ${screenshot}    Take a screenshot of the robot    ${row}[Order number]
          Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}     ${row}[Order number]
          Go to order another robot
    END
    Create a ZIP file of the receipts
