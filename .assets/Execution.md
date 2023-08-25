Now that the steps to setup the tool are complete, let's look at how to run it. The execution consists of 2 steps: exporting the incremental updates from Dynamics 365 Business Central (BC) to the data lake and then consolidating them into a final dataset.

# Exporting data from BC
The export process makes incremental updates to the data lake, based on the amount of changes (adds/ modifies/ deletes) made in BC since the last run. Open the `Page 82560 - Export to Azure Data Lake Storage` and add some tables that should be exported at the bottom grid of [the page](/.assets/bcAdlsePage.png). Do not forget to explicitly (and judiciously) select the fields in the table that should be exported.

> **<em>Note</em>** 
> 1. BLOB, Flow and Filter fields as well as the fields that have been Obsoleted or disabled are not supported. Furthermore, fields that are actually marked by an [Access Property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-access-property) other than `Public` will not be exported either. 
> 2. Records created before the time when [the `SystemCreatedAt` audit field](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields#audit) was introduced, have the field set to null. When exporting, there is an artificial value of 01 Jan 1900 set on the field notwithstanding the timezone of the deployment. 

Click on the `Export` action at the top of the page. This spawns multiple sessions that export each table in parallel and uploads only the incremental updates to the data since the last export. When none of the table rows have a `Last exported status` of `In process`, it indicates that the export process has completed. You should be able to see the data through the CDM endpoint: `deltas.cdm.manifest.json`.

For tables that either have `DataPerCompany` set to `false` or have been reset and exported multiple times, there may be duplicate data in the deltas folder. When running the integration pipeline process, such duplicates should be removed.

In version 21, a new feature called `Report read-only data access` needs to [be enabled](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/feature-management) so that all reads from the tables are made from the replica database. We encourage you to turn this on, as running the exports from the replica database will help minimize the performance impact on the "normal" ERP operations.

## Telemetry
You may switch off the telemetry traces specified inside the code of this extension by turning the "Emit telemetry" flag to off on the main setup page. When switched on, operational telemetry is pushed to any Application Insights account specified on the extension by the publisher. [Read more](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/telemetry-overview).

# Running the integration pipeline
The pipeline execution can be managed as static trigger directly in Azure Synapse Analytics or with the use of Power Automate between Business Central and Azure Synapse as mediator. Power Automate can instantly trigger the pipeline when an export of a table is finished, which could makes pipelines scheduling easier.

## Azure Synapse Analytics
The **Consolidation_AllEntities** pipeline consolidates all the incremental updates made from BC into one view. It should be invoked after one or more export processes from BC has completed and it requires you to specify the following parameters,
- **containerName**: the name of the data lake container to which the data has been exported
- **deleteDeltas**: a flag to delete the deltas, if successful. In the general case, you might want to set this to true, as the deltas will not be deleted if the pipeline results in an error. Set it to false, in case you want to debug/troubleshoot.
- **sparkpoolName**: (optional) the name of the Spark pool that should be used to [create shared metadata tables](/.assets/SharedMetadataTables.md). If left blank, no shared metadata tables will be created.

Follow the instructions at [Pipeline execution and triggers in Azure Data Factory or Azure Synapse Analytics | Microsoft Docs](https://docs.microsoft.com/en-us/azure/data-factory/concepts-pipeline-execution-triggers) to trigger the pipeline. You will be required then to provide values for the parameters mentioned above.
![Trigger pipeline run](/.assets/synapseTriggerNow.png)

> **<em>Note</em>** Ensure that the pipeline is not triggered for an Azure data lake container in which data is either being exported from BC or another pipeline is consolidating data.

## Power Automate
Will only execute The **Consolidation_OneEntity** pipeline without the use of the **Consolidation_OneEntity** and **Consolidation_CheckForDelta** pipelines.
Follow the instructions at [Setup the Business Central to Azure Data Lake Storage Solution](/.assets/BusinessCentraltoAzureDataLakeStorageSolution.md) to trigger the pipeline with Power Automate.
![Manual triggered pipeline runs](/.assets/synapseTriggerPowerAutomate.png)

# Consuming the CDM data
There are [multiple ways](https://learn.microsoft.com/en-us/power-query/connectors/data-lake-storage) of consuming the resulting CDM data, for example using Power BI. To do so, create a new Power BI report and select **Get data**, then select **Azure Data Lake Storage Gen2** and **Connect**.

![](/.assets/PowerBI_get_data.png "Connect to an Azure Data Lake")

On the next screen, enter your Data Lake Storage endpoint, which you can find on the **Endpoints** blade of the Storage Account resource in the Azure Portal. Select **CDM Folder View (Beta)** and **OK**.

![](/.assets/PowerBI_CDM.png)

Expand the database icon labeled **data-manifest** to select which tables to load.

![](/.assets/PowerBI_manifest.png)

# Consuming the shared metadata tables

If you have configured bc2adls to [create shared metadata tables](/.assets/SharedMetadataTables.md) for your exported entities, then you can also access your tables using Spark or Serverless SQL in Azure Synapse Analytics. You can even connect other consumers, like Power BI, through the Serverless SQL endpoint of your Synapse workspace. This allows you to connect in Import mode (as if you were connecting to the Data Lake directly), but also in DirectQuery mode (as if it was a database). See this [tutorial for instructions on how to connect](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/tutorial-connect-power-bi-desktop#4---create-power-bi-report) (from step 4).

To consume the data directly in your Synapse workspace, you can find the lake database in your workspace's **Data** section. Expand the database to see the shared metadata tables it contains. From here you can directly load a table into a SQL script or a Spark notebook.
![](/.assets/shared_metadata_table_sql_query.png "Select TOP 100 FROM shared metadata table")
