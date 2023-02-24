param (
    [Parameter(Mandatory=$true)]
    [string] $rootPath,

    [Parameter(Mandatory=$true)]
    [string] $mongoDirName)

$ErrorActionPreference = "Stop"

function ProcessTitle
{
    process { Write-Host $_ -ForegroundColor DarkGreen }
}

function PrettyOutput
{
    process { Write-Host $_ -ForegroundColor DarkMagenta }
}

az login

$subscription = $(az account show --query id)
$randomSuffix = (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})).ToLower()
$location = "northeurope"
$storageAccount = "udstorageaccount$randomSuffix"
$storageContainer = "udstoragecontainer$randomSuffix"
$resourceGroup = "udappsproject$randomSuffix"
$sqlServer = "udappssqlserver$randomSuffix"
$database = "udappssqldb$randomSuffix"
$login = "marek"
$password = "P@ssw0rd!"
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"
$adAppName ="udadapp$randomSuffix"
$appServicePlan = "udappsvcplan$randomSuffix"
$functionappName = "udfunc$randomSuffix"
$cosmosdbName = "udcosmo$randomSuffix"
$webappName = "udwebapp$randomSuffix"
$databaseName = "microservicesdb"

Write-Output "Creating resource group..." | ProcessTitle
Write-Output "az group create --name $resourceGroup --location $location" | ProcessTitle
az group create --name $resourceGroup --location $location

Write-Output "Creating storage account and containers..." | ProcessTitle
Write-Output "az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS --allow-blob-public-access true" | ProcessTitle
az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS --allow-blob-public-access true

Write-Output "Creating appservice plan" | ProcessTitle
Write-Output "az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku B1 --is-linux" | ProcessTitle
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku B1 --is-linux
Start-Sleep -Seconds 30

$planName = $(az appservice plan list --resource-group $resourceGroup --query "[].[name]" --output tsv)

Write-Output "Creating function app..." | ProcessTitle
Write-Output "az functionapp create --name $functionappName --resource-group $resourceGroup --storage-account $storageAccount --os-type Linux --plan $planName --runtime python --runtime-version 3.9" | ProcessTitle
az functionapp create --name $functionappName --resource-group $resourceGroup --storage-account $storageAccount --os-type Linux --plan $planName --runtime python --runtime-version 3.9

Write-Output "Creating CosmosDB related infrastructure..." | ProcessTitle
Write-Output "az cosmosdb create --name $cosmosdbName --resource-group $resourceGroup --kind MongoDB" | ProcessTitle
Write-Output "az cosmosdb mongodb database create --account-name $cosmosdbName --resource-group $resourceGroup --name $databaseName" | ProcessTitle
Write-Output "az cosmosdb mongodb collection create --account-name $cosmosdbName --resource-group $resourceGroup --database-name $databaseName --name advertisements" | ProcessTitle
Write-Output "az cosmosdb mongodb collection create --account-name $cosmosdbName --resource-group $resourceGroup --database-name $databaseName --name posts" | ProcessTitle
az cosmosdb create --name $cosmosdbName --resource-group $resourceGroup --kind MongoDB
Start-Sleep -Seconds 10
az cosmosdb mongodb database create --account-name $cosmosdbName --resource-group $resourceGroup --name $databaseName
az cosmosdb mongodb collection create --account-name $cosmosdbName --resource-group $resourceGroup --database-name $databaseName --name advertisements
az cosmosdb mongodb collection create --account-name $cosmosdbName --resource-group $resourceGroup --database-name $databaseName --name posts

$rawJson = $(az cosmosdb keys list --type connection-strings --resource-group $resourceGroup --name $cosmosdbName)
$actualJson = $rawJson | ConvertFrom-Json
$primaryMdbConnection = $actualJson.connectionStrings[0].connectionString
$secondaryMdbConnection = $actualJson.connectionStrings[1].connectionString
$primaryRoMdbConnection = $actualJson.connectionStrings[2].connectionString
$secondaryRoMdbConnection = $actualJson.connectionStrings[3].connectionString
$settings = "MongoCosmosConnectionString=$primaryMdbConnection"

Write-Output "CosmosDB connection strings are: " | ProcessTitle
Write-Output "Primary: $primaryMdbConnection"  | ProcessTitle
Write-Output "Secondary: $secondaryMdbConnection" | ProcessTitle
Write-Output "Primary read-only: $primaryRoMdbConnection" | ProcessTitle
Write-Output "Secondary read-only: $secondaryRoMdbConnection" | ProcessTitle

Write-Output "Setting connection string..." | ProcessTitle
Write-Output "az functionapp config appsettings set --name $functionappName --resource-group $resourceGroup --settings $settings" | ProcessTitle 
az functionapp config appsettings set --name $functionappName --resource-group $resourceGroup --settings "MongoCosmosConnectionString=$primaryMdbConnection"

$resourceGroup = "udappsprojectahorp"

Write-Output "Installing MongoDB locally..." | ProcessTitle
docker pull mongo
New-Item -Path $rootPath -Name $mongoDirName -ItemType "directory" -ErrorAction Ignore
New-Item -Path $rootPath -Name "$mongoDirName\db" -ItemType "directory" -ErrorAction Ignore
New-Item "$rootPath\.env" -ErrorAction Ignore
Set-Content "$rootPath\.env" "MONGO_HOST_DATA=$rootPath"
docker compose -f .\aks_exercises\docker-compose.mongodb.yml up -d --build --force-recreate
