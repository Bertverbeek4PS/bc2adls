[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/Bertverbeek4PS/bc2adls/badge)](https://scorecard.dev/viewer/?uri=github.com/Bertverbeek4PS/bc2adls)

![](.assets/bc2adls_banner.png)
# Starting update
**The original repository "[microsoft/bc2adls](https://github.com/microsoft/bc2adls)" is in read-only mode. But since a lot of partners are using this tool, we want to develop it further as open source software. A special thanks to the creators of this tool: [Soumya Dutta](https://www.linkedin.com/in/soumya-dutta-07813a5/) and [Henri Schulte](https://www.linkedin.com/in/henrischulte/), who put a lot of effort into it!**

## Introduction

The **bc2adls** tool is used to export incremental data from [Dynamics 365 Business Central](https://dynamics.microsoft.com/en-us/business-central/overview/) (BC) to [Microsoft Fabric ](https://learn.microsoft.com/nl-nl/fabric/get-started/microsoft-fabric-overview) or [Azure Data Lake Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction).


More details:
- [Installation and configuration of the connection with Azure Data Lake](/.assets/Setup.md)
- [Executing the export and pipeline](/.assets/Execution.md)
- [Creating shared metadata tables](/.assets/SharedMetadataTables.md)
- [Installation and configuration of the connection with Microsoft Fabric](/.assets/SetupFabric.md)
- [Frequently asked questions](/.assets/FAQs.md)
- Webinars
    - [[Jan 2022] Webinar introducing bc2adls](https://www.microsoft.com/en-us/videoplayer/embed/RWSHHG)
	- [[Apr 2022] Areopa Webinar bc2adls](https://www.youtube.com/watch?v=Fjz9LgviV2Q)
    - [[Mar 2023] Enhancements to bc2adls - CloudChampion](https://www.cloudchampion.dk/c/dynamics-365-business-central-azure-data-lake/)
	- [[Jan 2024] Areopa Webinar MS Fabric](https://www.youtube.com/watch?v=sXZkrFtN5oc)


## Changelog

This project is constantly receiving new features and fixes. Find a list of all major updates in the [changelog](/.assets/Changelog.md).

## Testimonials

Here are a few examples of what our users are saying ...

> “After careful consideration we, as Magnus Digital, advised VolkerWessels Telecom, a large Dutch telecom company, to use and exploit the features of BC2ADLS. We see BC2ADLS currently as the only viable way to export data from Business Central to Azure Data Lake at large scale and over multiple administrations within BC. By the good help of Soumya and Henri, we were able to build a modern data warehouse in Azure Synapse with a happy customer as result.” 

&mdash; Bas Bonekamp, [Magnus Digital](https://www.magnus.nl/) <br/><br/>

> “With the bc2adls we have found a way to export huge amount of data from Business Central to a data warehouse solution. This helps us allot to unburden big customers to move to Business Central Online. Also it is easy to use for our customers so they can define their own set of tables and fields and schedule the exports.”

&mdash; Bert Verbeek, [4PS](https://www.4ps.nl/)<br/><br/>

> “I can't believe how simple and powerful loading data from  Business Central is now. It's like night and day—I'm loving it!”

&mdash; Mathias Halkjær Petersen, [Fellowmind](https://www.fellowmindcompany.com/)<br/><br/>

> “At Kapacity we have utilized the bc2adls tool at several customer projects. These customer cases span from small a project with data extract from 1-3 companies in Dynamics Business Central SaaS (BC) to an enterprise solution with data extract from 150 companies in BC. bc2adls exports multicompany data from BC til Azure Data Lake Storage effectively with incremental updates. The bc2adls extension for BC is easy to configure and maintain. The customer can add new entities (tables and fields) to an existing configuration and even extend the data extract to include new company setup. We have transformed data with the Azure Synapse pipelines using the preconfigured templates from the bc2adls team. The data analyst queries this solution in Power BI using the Shared Metadata db on Serverless SQL. In the enterprise project we did the data transformation using Azure Databricks. Thanks to the bc2adls team providing these tools and great support enabling us to incorporate this tool in our data platform.”

&mdash; Jens Ole Taisbak, [TwoDay Kapacity](https://www.kapacity.com/)<br/><br/>

> “We have had great success using the BC2ADL tool. It is well thought out and straightforward to implement and configure. The Microsoft team that develops the tool continues to add new features and functionality that has made it a great asset to our clients. We looked to the BC2ADL tool to solve a performance issue in reporting for Business Central. Using the BC2ADL tool along with Synapse Serverless SQL we have been able to remove the primary reporting load from the BC transactional database, which has helped alleviate a bottleneck in the environment. When the BC2ADL tool was updated to export from the replicated BC database we were able to really take full advantage of the process and provide intraday updates of the Azure Data Lake with no noticeable affect on BC performance. The Microsoft team has been extremely helpful and responsive to requests from the community on feature requests and support.”

&mdash; Tom Link, [Stoneridge Software](https://stoneridgesoftware.com/)<br/><br/>

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
