# Synapse Instructions

The data history preview feature for ADT does not support Azure Synapse.  I tried to mirror the configuration that takes place under the covers and get the same behavior.  This test revealed that there is clearly some sort of processor that outputs the data to the event hub in a different format from route data.

## Setup Steps

1. Deploy a Synapse Workspace instance.
2. Deploy an Azure Data Explorer cluster in the workspace.
3. Create a Database in your ADX Cluster.
4. Create the table to store the history: `.create table adthistory (TimeStamp: datetime, SourceTimeStamp: datetime, ServiceId: string, Id: string, ModelId: string, Key: string, Value: dynamic, RelationshipTarget: string, RelationshipId: string)`
5. Create a data mapping for the history data: `.create table adthistory ingestion json mapping 'adthistory_mapping' '[{"column":"TimeStamp","path":"$.timeStamp","datatype":"","transform":null},{"column":"SourceTimeStamp","path":"$.sourceTimeStamp","datatype":"","transform":null},{"column":"ServiceId","path":"$.serviceId","datatype":"","transform":null},{"column":"Id","path":"$.id","datatype":"","transform":null},{"column":"ModelId","path":"$.modelId","datatype":"","transform":null},{"column":"Key","path":"$.key","datatype":"","transform":null},{"column":"Value","path":"$.value","datatype":"","transform":null},{"column":"RelationshipTarget","path":"$.relationshipTarget","datatype":"","transform":null},{"column":"RelationshipId","path":"$.relationshipId","datatype":"","transform":null}]'` 
6. Deploy an event hub namespace and event hub named 'synapse'.
7. Create a consumer group on the synapse event hub named 'synapse'.  The cli command below that creates the connection requires a consumer group that is not $default.
8. Grant the ADT managed identity event hub writer permissions to the event hub.
9. Grant the Synapse Workspace managed identity event hub reader permissions to the event hub.
10. Create the data connection between the event hub and adx cluster.  Make sure to replace the <> values.
`az synapse kusto data-connection event-hub create --workspace-name "<SynapseWorkspaceName>" --kusto-pool-name "<SynapseADXClusterName>" --data-connection-name "adthistoryconnection" --database-name "Demo"  --data-format "MULTIJSON" --table-name "adthistory" --mapping-rule-name "adthistory_mapping" --event-hub-resource-id "/subscriptions/<AzureSubcriptionName>/resourceGroups/<ResourceGroupName>/providers/Microsoft.EventHub/namespaces/<EventHubNameSpace>/eventhubs/synapse" --consumer-group "synapse" --resource-group "<ResourceGroupName>" --location "eastus"`

## Results

After running the simulator for a while, the ADX queries revealed that only the modelId field was being populated.  After further evaluation of the data event hub data, structure differences were uncovered.

### Standard output from a route

{
  "modelId": "dtmi:assetGen:PasteurizationMachine;1",
  "patch": [
    {
      "value": 201.5428774161309,
      "path": "/InFlow",
      "op": "replace"
    },
    {
      "value": 199.6461724938995,
      "path": "/OutFlow",
      "op": "replace"
    },
    {
      "value": 122.79210841728452,
      "path": "/Temperature",
      "op": "replace"
    },
    {
      "value": 0.04043378258793628,
      "path": "/PercentFull",
      "op": "replace"
    }
  ]
}

### Output from the ADT to ADX Connector

{
    "timeStamp": "2022-04-28T18:28:39.7618577Z",
    "sourceTimeStamp": null,
    "serviceId": "adthistorydemo823.api.eus.digitaltwins.azure.net",
    "id": "PasteurizationMachine_A04",
    "modelId": "dtmi:assetGen:PasteurizationMachine;1",
    "key": "OutFlow",
    "value": 237.7827339799181,
    "relationshipTarget": null,
    "relationshipId": null,
    "EventProcessedUtcTime": "2022-04-28T18:47:52.6788499Z",
    "PartitionId": 0,
    "EventEnqueuedUtcTime": "2022-04-28T18:28:39.8970000Z"
}

### Conclusion

It's clear there is some sort of processing that happens before ADT lands the data into the event hub that adds some additonal data and does some shaping of the payload.  Thus, for now, you cannot use this feature with Azure Synapse Data Explorer Clusters.  Check the docs for the latest updates on product changes and availability.