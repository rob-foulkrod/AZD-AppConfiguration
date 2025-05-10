[comment]: <> (please keep all comment items at the top of the markdown file)
[comment]: <> (please do not change the ***, as well as <div> placeholders for Note and Tip layout)
[comment]: <> (please keep the ### 1. and 2. titles as is for consistency across all demoguides)
[comment]: <> (section 1 provides a bullet list of resources + clarifying screenshots of the key resources details)
[comment]: <> (section 2 provides summarized step-by-step instructions on what to demo)


[comment]: <> (this is the section for the Note: item; please do not make any changes here)
***
### Azure App Congfiruation - demo scenario

<div style="background: lightgreen; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">

**Note:** Below demo steps should be used **as a guideline** for doing your own demos. Please consider contributing to add additional demo steps.
</div>

***
### 1. What Resources are getting deployed
This scenario deploys a sample application inside a **Azure Function**. When deployed, the following resources are available:

* function-%uniqueid% - Azure Function
* serviceplan-%uniqueid% - Azure Service Plan
* %app configuration name% - Azure App Configuration
* identity-%uniqueid% - User Managed Identity for setting up the configuration for the sample application
* storage%uniqueid% - Azure Storage Account 

**Note:** You might see a Deployment script resource as well. This one will be automatically removed after one hour after a succesfull deployment.

The url of the function can be requested when running the command `AZD ENV get-value AZURE_FUNCTION_BASE_URL`

<img src="img/ResourceGroup_Overview.png" alt="Resource Group" style="width:100%;">
<br></br>

### 2. What can I demo from this scenario after deployment
1. Key value: 
    - https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-azure-functions-csharp
    - https://learn.microsoft.com/en-us/azure/azure-app-configuration/enable-dynamic-configuration-azure-functions-csharp
        - Instead of running the app locally you can browse to: `AZURE_FUNCTION_BASE_URL/api/showmessage`
        - To verify that the message has been picked up:
            - Place a message on the queue (base64 encoded)
            - Ensure that it is not poisoned, by checking that only one queue is available after the message has been picked up. If there is a demo-poison queue something went wrong.
2. Feature flag
    - https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-feature-flag-azure-functions-csharp
        Instead of running the app locally you can browser to: `AZURE_FUNCTION_BASE_URL/api/showbetafeature`

[comment]: <> (this is the closing section of the demo steps. Please do not change anything here to keep the layout consistant with the other demoguides.)
<br></br>
***
<div style="background: lightgray; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">

**Note:** This is the end of the current demo guide instructions.
</div>
