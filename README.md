# Azure Digital Twins and Azure Data Explorer Lab

This lab is based on [How to Use Data History](https://docs.microsoft.com/azure/digital-twins/how-to-use-data-history).  It automates the creation of resources and has the attendee explore some of the aspects of the model within Azure Digital Twins.

## Setup

1. Open an Azure Cloud Shell session.
2. Run `curl –L https://raw.githubusercontent.com/howardginsburg/azuredigitaltwins-history/main/provision.sh > provision.sh`
3. Run `bash provision.sh`
4. Make note of your Azure Digital Twins URI and ADX table names.

The provisioning script is performing the following actions:

1. Create an ADT instance
2. Create an Event Hub
3. Create an ADX cluster and Database
4. Setup the ADT to ADX Update History Connector

## Lab Steps

1. Open the [simulator](https://explorer.digitaltwins.azure.net/tools/data-pusher).
2. Paste your Azure Digital Twins URI.
3. Click the "Generate environment" button.
4. In a new tab, Open an Azure Portal session and navigate to you resource group that was created for this lab.
5. Open your Azure Digital Twins resource.
6. Open the Azure Digital Twins Explorer.
7. Explore the model definitions and twin instances.
8. Click on the settings cog and enable 'Output'.
9. Run the query to see how the digital twins query language is structured.
    `SELECT t.$dtId as Factories FROM DIGITALTWINS t WHERE IS_OF_MODEL(t , 'dtmi:assetGen:Factory;1')`
10. Open your Azure Data Explorer resource.
11. Click on "Query your data".
12. Increase the batch ingestion time to be every 10 seconds.
    `.alter table <table-name> policy ingestionbatching @'{"MaximumBatchingTimeSpan":"00:00:10", "MaximumNumberOfItems": 500, "MaximumRawDataSizeMB": 1024}'`
13. In the simulator, click "Start simulation".
14. In the Digital Twins Explorer, click on some of the twins and notice that the properties are now being updated.
15. Run some of the [sample queries](/queries.kql).
16. In the simulator, click "Stop simulation".
17. Delete the Azure Resource Group for the lab.

## Azure Synapse Data Explorer Test

Azure Data Explorer clusters within Azure Synapse is currently in preview.  I tried to get the ADT history plug in to work by manually creating a connection.  You can see the results at [Synapse Test](/synapse%20setup.md).
