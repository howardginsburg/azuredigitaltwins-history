randomValue=$((100 + $RANDOM % 1000))
resourceGroupName="adthistorydemo$randomValue"
location="eastus"
twinsName="adthistorydemo$randomValue"
eventHubName="adthistorydemo$randomValue"
adxClusterName="adthistorydemo$randomValue"

# allow dynamic extension installs.
az config set extension.use_dynamic_install=yes_without_prompt

# grab the user we're running as and the subscription.
userName=$(az account list --query "[?isDefault].user.name" -o tsv)
subscription=$(az account list --query "[?isDefault].id" -o tsv)

# Enable the ADT provider
echo "Enabling the ADT provider..."
az provider register --namespace 'Microsoft.DigitalTwins'

echo "Upgrading the iot cli"
az extension add --upgrade --name azure-iot

echo "Creating resource group..."
# Create a resource group for the lab.
az group create --location $location --resource-group $resourceGroupName

echo "Creating digital twin..."
## Azure Digital Twins ######
# Create Azure Digital Twins and wait until it's created.
az dt create -n $twinsName -g $resourceGroupName -l $location --assign-identity
az dt wait -n $twinsName --created
# Add the current user as a twins owner so the console app and twins explorer will work.
az dt role-assignment create -n $twinsName --assignee $userName --role "Azure Digital Twins Data Owner"
twinsUri="https://"$(az dt show --dt-name $twinsName --resource-group $resourceGroupName --query "hostName" -o tsv)
#############################


echo "Creating event hubs..."
## Event Hub ###########
# Create an event hub namespace and eventhubs to hold messages coming from IoT Hub and output messages from Digital Twins.
az eventhubs namespace create --resource-group $resourceGroupName --name $eventHubName --location $location --sku Standard
az eventhubs eventhub create --resource-group $resourceGroupName --namespace-name $eventHubName --name output
#########################

az extension add --name kusto
az kusto cluster create --cluster-name $adxClusterName --sku name="Dev(No SLA)_Standard_E2a_v4" tier="Basic" --resource-group $resourceGroupName --location $location --type SystemAssigned
az kusto database create --cluster-name $adxClusterName --database-name "Demo" --resource-group $resourceGroupName --read-write-database soft-delete-period=P365D hot-cache-period=P31D location=$location

az dt data-history connection create adx -n $twinsName -y --cn "adt-history-connection" --adx-cluster-name $adxClusterName --adx-database-name "Demo" --eventhub "output" --eventhub-namespace $eventHubName
adxTable=$(az dt data-history connection list -n $twinsName --query "[0].properties.adxTableName" -o tsv)

echo ""
echo ""
echo "Deployment of Azure resources is successful!"
echo "Resource Group: " $resourceGroupName
echo "Twins URI: " $twinsUri
echo "ADX Table: " $adxTable
echo ""
echo "Simulator: https://explorer.digitaltwins.azure.net/tools/data-pusher"
