# Setup the Business Central to Azure Data Lake Storage Solution
This guide will explain how to utilize Power Automate in the Power Platform as a mediator to execute the pipeline in Azure Synapse Analytics when a export of a table is finished in Business Central. This solution provides a template on which you can expand and improve such as notifications.

## Why use Power Automate?
Inspired by [issue #84](https://github.com/microsoft/bc2adls/issues/84) and [issue #87](https://github.com/microsoft/bc2adls/issues/87) using Power Automate as a mediator between Business Central and Azure Synapse can enable the use cases of both issues. In stead of calling directly from Business Central to Azure Synapse Analytics, this loosely coupled design enables more integration possibilities for the future.

## Import Solution
To import the Business Central to Azure Data Lake Storage solution you may refer to the following guide [Import solutions](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/import-update-export-solutions).

## Cloud flows
The solution exists of multiple Cloud flows. The **BC2ADLS - Trigger from Business Central event** is the main flow on which it will call multiple child flows.
![BC2ADLS - Trigger from Business Central event](/.assets/powerAutomateFlow.png)

The first step is Business Central calling the **when a business event occurs** with the use of the [Business events](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/business-events-overview). In case the state of the export from Business Central to Azure Date Lake Storage wasn't successful the execution stops. For maintaining the credentials in one place the **BC2ADLS - Get Access Token** is responsable for retrieving an access token. The prevent starting a new pipeline, while the previous one isn't finished the **BC2ADLS - Get Queued/Running Synapse Pipelines** retrieves all queued and running pipelines with the matching parameters. When this check succeed the **BC2ADLS - Enqueue Azure Synapse Pipeline** wil enqueue the run of the pipeline in Azure Synapse Analytics.

## Setup Service Principle
Create an App Registration with Secret (Service principal) and add it to the synapse access control like below.
![Setup Service Principle](/.assets/powerAutomateSynapseServicePrincipalAccessControl.png)

## Setup BC2ADLS - Get Access Token
Edit the **BC2ADLS - Get Access Token** flow and provided the necessary variables with the App Registration of the previous step above.
![Setup BC2ADLS - Get Access Token](/.assets/powerAutomateSetupGetAccessToken.png)
> **<em>Note</em>** This exposes the client secret as plain text and on running the pipeline the access token. To increase security you can place the client secret in an Azure Key Vault and configure the Authentication directly on the both HTTP blocks.

## Setup BC2ADLS - Trigger from Business Central event
Edit the **Setup BC2ADLS - Trigger from Business Central event** flow and provided the necessary variables and enable the cloud flow.
![Setup BC2ADLS - Trigger from Business Central event](/.assets/powerAutomateSetupTriggerBusinessCentralEvent.png)