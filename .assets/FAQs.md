Here you will find answers to the most frequently asked questions. Please also refer to the [issues](/issues) site to know more or to ask your own questions in the community. 

### How do I run the export to the lake in a recurring schedule?
The [Job Queue](https://learn.microsoft.com/en-us/dynamics365/business-central/admin-job-queues-schedule-tasks) feature in Business Central is used to schedule background tasks in a periodic way. You may invoke the [Codeunit `ADLSE Execution`](https://github.com/Bertverbeek4PS/bc2adls/blob/main/businessCentral/app/src/Execution.Codeunit.al) through the feature to export the data increments to the lake as a scheduled job. You may click `Schedule export` on the main setup page to create this job queue.

If you want to export multiple tables at different frequencies, you can use report [Report `ADLSE Schedule Task Assignment`](https://github.com/Bertverbeek4PS/bc2adls/blob/main/businessCentral/app/src/ScheduleTaskAssignment.Report.al).
In the Job Queue you can set the option "Report Request Page Options"
![Report Request page options](/.assets/JQ_ReportRequestPageOptions.png)
If you go to "Job Queue" -> "Report Request Page" option in the ribbon you can select the category or the table id's you want to export on that specific Job Queue.
![Report Options](/.assets/JQ_ReportOptions.png)

### I have many BC environments in the same tenant. How should I distribute the BC data to my lake?
We recommend that a data lake container holds data only for **only one** Business Central environment. After copying environments, ensure that the export destination on the setup page on the new environment points to a new data lake container.

### How do I export data from multiple companies in the same environment?
The export process copies the updated data to the lake for ONLY the company it has been invoked from. This is true whether you start the process by a click on the `Export` button or by scheduling a `Job Queue Entry`. Therefore, one should log in and click the button or setup scheduled jobs from the company whose data needs to be exported. If you want to export the data from multiple companies the `export schema` must be done first.

### Can I export calculated fields into the lake?
No, only persistent fields on the BC tables can be exported. But, the [issue #88](/issues/88) describes a way to show up those fields when consuming the lake data.

### How can I export BLOB data to the lake?
Data from blob fields in tables are not exported today to the lake. It should be possible however to convert the (possibly, binary) data to text using the [Codeunit `Base64 Convert`](https://learn.microsoft.com/en-us/dynamics365/business-central/application/reference/system%20application/codeunit/system_application_codeunit_base64_convert) and then store it as a separate field in a new table and exporting it to the lake using the bc2adls solution.

### How do I export some tables at a different frequency than the rest?
Yes you can have different frequencies for different tables. Just look into the line "How do I run the export to the lake in a recurring schedule?" above.

### How do I track the files in the `deltas` folder in my data lake container?
Incremental exports create files in the `deltas` folder in the lake container. Each such file has a `Modified` field that indicates the time when it was last updated, in other words, when the export process finished with that file. Each export process for an entity and in a company logs its execution on the  [`ADLSE Run`](https://github.com/microsoft/bc2adls/blob/main/businessCentral/src/ADLSERun.Table.al) table using the `Started` and `Ended` fields. Thus you may tally the value in the `Modified` field of the file to these fields and determine which run resulted in creation of that file. You may also use telemetry to determine which run created which file.

### What should I do when a field I was exporting has been made obsolete?
Table fields that are obsoleted already cannot be configured to be exported but the system actually allows you to add fields that are pending obsoletion. In case you are already using such a field, you will get upgrade errors for upgrade to newer versions of the application where the field has been removed. It is recommended that you read the documentation of the obsoletion to determine if there are different fields that will hold the information from the new version onwards and then to enable those fields thereby. Of course, you will also have to disable the obsoleted field from the export. Such a change will alter the schema of export, thus changing the entity Jsons on the data lake. We advise you to archive the "older" data and if possible, create pipelines to correctly map the older data to the new schema.

### I need help because my export job is timing out!
Let's look at addressing timeout issues have been seen to occur at two possible places in the solution, both of them happening typically during the initial export of records,  
1. The query to fetch the records during before the export to the lake may timeout if it takes more than the [operation limits](/business-central/dev-itpro/administration/operational-limits-online) defined. This may happen when bc2adls attempts to sort a large set of records as per the row version. You may _suspend_ the sorting temporarily using the field `Skip row version sorting` on the setup page. 
1. Chunks of data (or [blocks](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction#:~:text=Block%20blobs), in the data lake parlance) are added to a lake file during the export. Adding too many such large chunks may cause timeout issues in the form of an error message like `Could not commit blocks to <redacted>. OperationTimedOutOperation could not be completed within the specified time.` We are using default timeouts in the bc2adls app, but you may add [additional timeout URL parameter](https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-list?tabs=azure-ad#:~:text=timeout) if you want by suffixing the URL call in the procedure [`CommitAllBlocksOnDataBlob`](https://github.com/microsoft/bc2adls/blob/main/businessCentral/src/ADLSEGen2Util.Codeunit.al#:~:text=CommitAllBlocksOnDataBlob) with `?timeout=XX`, XX being the number of seconds for timeout to expire. This issue could typically happen when you are pushing a large payload to the server. Also consider reducing the number at the field [Max payload size (MiBs)](https://github.com/microsoft/bc2adls/blob/main/.assets/Setup.md#:~:text=Max%20payload%20size%20(MiBs)).