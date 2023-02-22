param (
    [Parameter(Mandatory=$true)]
    [bool] $isLocalDeployment,

    [Parameter(Mandatory=$false)]
    [string] $redirectUri)

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

$subscription=$(az account show --query id)
$randomSuffix= (-join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})).ToLower()
$location="northeurope"
$storageAccount="udstorageaccount$randomSuffix"
$storageContainer="udstoragecontainer$randomSuffix"
$resourceGroup="udappsproject$randomSuffix"
$sqlServer="udappssqlserver$randomSuffix"
$database="udappssqldb$randomSuffix"
$login="marek"
$password="P@ssw0rd!"
$startIp="0.0.0.0"
$endIp="0.0.0.0"
$adAppName="udadapp$randomSuffix"
$appServicePlan="udappsvcplan$randomSuffix"
$webappName="udwebapp$randomSuffix"
$gitrepo="https://github.com/mmalek06/udacity-apps-project"

Write-Output "Creating resource group..." | ProcessTitle
Write-Output "az group create --name $resourceGroup --location $location" | ProcessTitle
az group create --name $resourceGroup --location $location

Write-Output "Creating sql-db related infrastructure..." | ProcessTitle
Write-Output "az sql server create --name $sqlServer --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password --enable-public-network true" | ProcessTitle
Write-Output "az sql server firewall-rule create --resource-group $resourceGroup --server $sqlServer -n AllowYourIp --start-ip-address $startIp --end-ip-address $endIp" | ProcessTitle
Write-Output "az sql db create --resource-group $resourceGroup --server $sqlServer --name $database --edition Basic --zone-redundant false" | ProcessTitle
az sql server create --name $sqlServer --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password --enable-public-network true
az sql server firewall-rule create --resource-group $resourceGroup --server $sqlServer -n AllowYourIp --start-ip-address $startIp --end-ip-address $endIp
az sql db create --resource-group $resourceGroup --server $sqlServer --name $database --edition Basic --zone-redundant false

Write-Output "Creating storage account and containers..." | ProcessTitle
Write-Output "az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS --allow-blob-public-access true" | ProcessTitle
az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS --allow-blob-public-access true
Start-Sleep -Seconds 60
Write-Output "az storage container create --name $storageContainer --account-name $storageAccount --public-access container" | ProcessTitle
az storage container create --name $storageContainer --account-name $storageAccount --public-access container

Write-Output "Creating az ad infrastructure..." | ProcessTitle

if ($isLocalDeployment)
{
    Write-Output "az ad app create --display-name $adAppName --sign-in-audience AzureADandPersonalMicrosoftAccount --web-redirect-uris https://localhost:5555/getatoken" | ProcessTitle
    az ad app create --display-name $adAppName --sign-in-audience AzureADandPersonalMicrosoftAccount --web-redirect-uris https://localhost:5555/getatoken
}
else
{
    Write-Output "az ad app create --display-name $adAppName --sign-in-audience AzureADandPersonalMicrosoftAccount --web-redirect-uris $redirectUri" | ProcessTitle
    az ad app create --display-name $adAppName --sign-in-audience AzureADandPersonalMicrosoftAccount --web-redirect-uris $redirectUri
}

Write-Output "Creating app service..." | ProcessTitle
Write-Output "az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku FREE --is-linux" | ProcessTitle
Write-Output "az webapp create --name $webappName --resource-group $resourceGroup --plan $appServicePlan --runtime PYTHON:3.10" | ProcessTitle
Write-Output "az webapp up --resource-group $resourceGroup --name $webappName --sku F1" | ProcessTitle
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku FREE --is-linux
az webapp create --name $webappName --resource-group $resourceGroup --plan $appServicePlan --runtime PYTHON:3.10
az webapp up --resource-group $resourceGroup --name $webappName --sku F1 --plan $appServicePlan
# Uncomment the below if you want to integrate your app deployment with github
#az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku FREE
#az webapp create --name $webappName --resource-group $resourceGroup --plan $appServicePlan
#az webapp deployment source config --name $webappName --resource-group $resourceGroup --repo-url $gitrepo --branch master

Write-Output "Subscription id: $subscription" | PrettyOutput
Write-Output "Storage account name: $storageAccount" | PrettyOutput
Write-Output "Storage container: $storageContainer" | PrettyOutput
Write-Output "Resource group: $resourceGroup" | PrettyOutput
Write-Output "Sql server: $sqlServer" | PrettyOutput
Write-Output "Database: $database" | PrettyOutput
Write-Output "Ad app name: $adAppName" | PrettyOutput
Write-Output "App service plan name: $appServicePlan" | PrettyOutput
Write-Output "Webapp name: $webappName" | PrettyOutput