The components for exporting to Microsoft Fabric involved are the following,
- the **[businessCentral](/tree/main/businessCentral/)** folder holds a [BC extension](https://docs.microsoft.com/en-gb/dynamics365/business-central/ui-extensions) called `Azure Data Lake Storage Export` (ADLSE) which enables export of incremental data updates to a container on the data lake. The increments are stored in the lakehouse folder in csv format.
- the **[fabric](/tree/main/fabric/)** folder holds the template needed to create an `notebook` to move the delta files to delta parquet table in the lakehouse.

The following diagram illustrates the flow of data through a usage scenario- the main points being,
- Incremental update data from BC is moved to Microsoft Fabric through the ADLSE extension into the `deltas` folder in the lakehouse.
- Triggering the notebook consolidates the increments into the delta parqeut tables.
- The resulting data can be consumed by Power BI or other tools inside Microsoft Fabric.:

![Architecture](/.assets/architectureFabric.png "Flow of data")

The following steps take you through configuring your Dynamics 365 Business Central (BC) as well as Azure resources to enable the feature.

## Configuring Azure

### Step 1. Create an Azure service principal
You will need an Azure credential to be able to connect BC to the Azure Data Lake Storage account, something we will configure later on. The general process is described at [Quickstart: Register an app in the Microsoft identity platform | Microsoft Docs](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#register-an-application). The one I created for the demo looks like,
![Sample App Registration](/.assets/appRegistration.png)

Take particular note of the **a)** and **b)** fields on it. Also note that you will need to generate a secret **c)** by following the steps detailed in the [Option 2: Create a new application secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#authentication-two-options). Add a redirected URI **d)** , `https://businesscentral.dynamics.com/OAuthLanding.htm`, so that BC can connect to Azure resources, say the Blob storage, using this credential. 

### Step 2. Add permissions to the service principal
For communication to Microsoft Fabric we need to add one more permission to the service principal. This is done by going to the **API permissions** tab and clicking on **Add a permission**. Select **Azure storage** and then **Delegated permissions**. Search for **User_impersonation** and select it. Click on **Add permissions** to add it to the service principal.
![Sample API permissions](/.assets/apiPermissions.png)

## Configuring Microsoft Fabric

### Step 2. Creating a lakehouse
In Microsoft Fabric you need to create a lakehouse. Go to the appropeate workspace and click on **new** and select
**Lakehouse (preview)**. Give it a name and click on **Create**. This will create a lakehouse with a default configuration.
![Fabric Create New](/.assets/fabricCreateNew.png)

### Step 3. Creating a notebook
For moving the delta files to tables you need to create a notebook.
Go to the appropeate workspace and choose **Home**. Click on **New** and select 
**import notebook**.
Upload the [notebook](/fabric/CopyBusinessCentral.ipynb) from the [fabric](/fabric) folder.

Read more at:
[How to use notebooks - Microsoft Fabric | Microsoft Learn](https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook#import-existing-notebooks)

You can also schedule the notebook to run at a specific time. Click on **Schedule** in the ribbon and select the time and frequency.

### Step 4. Adding service principle to the workspace
The service principal that you have created in step 1 needs to be added to the workspace. Go to the workspace and click on **Manage access** and search for your service principal. Select the service principal and click on **Add**.
![Access Management](/.assets/manageAccessFabric.png)

*it is possible that you cannot see the service principal then go to the admin tenant settings and enable the setting "Allow service principals to use Power BI API's"*
![Fabric Tenant Settings](/.assets/fabricTenantSettings.png)

## Configuring the Dynamics 365 Business Central
Install the extension into BC using the code given in the [businessCentral](/businessCentral) folder using the general guidance for [developing extensions in Visual Studio code](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview#developing-extensions-in-visual-studio-code). 

The app exposes [3 permission sets](/businessCentral/permissions/) for different user roles that work with this app. Remember to assign the right permission set to the user, based on the scope of their tasks:
1. `ADLSE - Setup`- The permission set to be used when administering the Azure Data Lake Storage export tool.
1. `ADLSE - Execute`- The permission set to be used when running the Azure Data Lake Storage export tool.

Once you have the `Azure Data Lake Storage Export` extension deployed, open the `Page 82560 - Export to Azure data lake Storage`. In order to export the data from inside BC to the data lake, you will need to add a configuration to make BC aware of the location in the data lake.

### Step 5. Enter the BC settings
Let us take a look at the settings show in the sample screenshot below,
- **Storage Type** choose here the storage type. Choose "Microsoft Fabric"
- **Tenant ID** The tenant id at which the app registration created above resides (refer to **b)** in the picture at [Step 1](/.assets/Setup.md#step-1-create-an-azure-service-principal))
- **Workspace** The workspace in your Microsoft Fabric environment where the lakehouse is located. This can also be a GUID. Be aware that the workspace name cannot contain spaces.
- **Lakehouse** The name or GUID of the lakehouse inside the workspace. The same naming convention applies here as for the workspace.
- **Skip row version sorting** Allows the records to be exported as they are fetched through SQL. This can be useful to avoid query timeouts when there is a large amount of records to be exported to the lake from a table, say, during the first export. The records are usually sorted ascending on their row version so that in case of a failure, the next export can re-start by exporting only those records that have a row version higher than that of the last exported one. This helps incremental updates to reach the lake in the same order that the updates were made. Enabling this check, however, may thus cause a subsequent export job to re-send records that had been exported to the lake already, thus leading to performance degradation on the next run. It is recommended to use this cautiously for only a few tables (while disabling export for all other tables), and disabling this check once all the data has been transferred to the lake.
- **Emit telemetry** The flag to enable or disable operational telemetry from this extension. It is set to True by default. 
- **Translations** Choose the languages that you want to export the enum translations. You have to refresh this every time there is new translation added. This you can do to go to `Related` and then `Enum translations`.
- **Export Enum as Integer** The flag to enable or disable exporting the enum values as integers. It is set to False by default.
- **Add delivered DateTime** If you want the exported time in the CSV file yes or no.
- **Export Company Database Tables** Choose the company in which you want to export the DataPerCompany = false tables. This gives better performance for exporting data of that or not on company level.

![Business Central Fabric](/.assets/businessCentralFabric.png)

### Step 6. Schedule export
You can also schedule the export. For each company you need to create Job Queue's. How you can do that you can read here:
[`How do I run the export to the lake in a recurring schedule`](https://github.com/Bertverbeek4PS/bc2adls/blob/main/.assets/FAQs.md#how-do-i-run-the-export-to-the-lake-in-a-recurring-schedule)
