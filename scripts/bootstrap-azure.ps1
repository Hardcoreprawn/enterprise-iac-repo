#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Bootstrap Azure infrastructure for enterprise IaC automation

.DESCRIPTION
    Creates the foundational Azure resources required for Terraform automation:
    - Resource groups for Terraform state storage
    - Storage account and container for state files
    - Service principal for Terraform authentication
    - Key Vault for secrets management

.PARAMETER ConfigFile
    Path to bootstrap configuration file (default: bootstrap-config.json)

.PARAMETER WhatIf
    Show what resources would be created without making changes

.PARAMETER Force
    Recreate resources even if they already exist

.EXAMPLE
    ./bootstrap-azure.ps1
    Uses default bootstrap-config.json

.EXAMPLE
    ./bootstrap-azure.ps1 -ConfigFile "prod-config.json" -WhatIf
    Preview changes for production configuration

.EXAMPLE
    ./bootstrap-azure.ps1 -Force
    Recreate all resources even if they exist
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "bootstrap-config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

# Set strict error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Script configuration
$script:LogFile = "bootstrap-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$script:CreatedResources = @()

# Logging functions
function Write-OperationLog {
    param(
        [string]$Operation,
        [string]$Status,
        [string]$Message,
        [hashtable]$Metadata = @{}
    )
    
    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Operation = $Operation
        Status    = $Status
        Message   = $Message
        Metadata  = $Metadata
    }
    
    # Console output with colors
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        "INFO"    { "Cyan" }
        default   { "White" }
    }
    
    $prefix = switch ($Status) {
        "SUCCESS" { "✓" }
        "WARNING" { "⚠" }
        "ERROR"   { "✗" }
        "INFO"    { "ℹ" }
        default   { "-" }
    }
    
    Write-Host "[$($logEntry.Timestamp)] $prefix $($logEntry.Message)" -ForegroundColor $color
    
    # Structured log for automation
    $logEntry | ConvertTo-Json -Compress | Add-Content -Path $script:LogFile
}

function Test-Prerequisites {
    Write-OperationLog -Operation "Prerequisites" -Status "INFO" -Message "Checking prerequisites..."
    
    $checks = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $checks += @{ Name = "PowerShell"; Status = "FAIL"; Message = "PowerShell 7+ required" }
    } else {
        $checks += @{ Name = "PowerShell"; Status = "OK"; Version = $PSVersionTable.PSVersion.ToString() }
    }
    
    # Check Azure CLI
    try {
        $azVersion = az version --output json 2>$null | ConvertFrom-Json
        $checks += @{ Name = "Azure CLI"; Status = "OK"; Version = $azVersion.'azure-cli' }
    } catch {
        $checks += @{ Name = "Azure CLI"; Status = "FAIL"; Message = "Azure CLI not found or not working" }
    }
    
    # Check Azure authentication
    try {
        $currentUser = az account show --output json 2>$null | ConvertFrom-Json
        if ($currentUser) {
            $checks += @{ Name = "Azure Auth"; Status = "OK"; User = $currentUser.user.name }
        } else {
            $checks += @{ Name = "Azure Auth"; Status = "FAIL"; Message = "Not authenticated to Azure" }
        }
    } catch {
        $checks += @{ Name = "Azure Auth"; Status = "FAIL"; Message = "Authentication check failed" }
    }
    
    # Report results
    $failed = $checks | Where-Object { $_.Status -eq "FAIL" }
    if ($failed) {
        foreach ($check in $failed) {
            Write-OperationLog -Operation "Prerequisites" -Status "ERROR" -Message "❌ $($check.Name): $($check.Message)"
        }
        throw "Prerequisites check failed. Please resolve the issues above."
    }
    
    foreach ($check in $checks | Where-Object { $_.Status -eq "OK" }) {
        $version = if ($check.Version) { " (v$($check.Version))" } else { "" }
        $user = if ($check.User) { " ($($check.User))" } else { "" }
        Write-OperationLog -Operation "Prerequisites" -Status "SUCCESS" -Message "$($check.Name)$version$user"
    }
    
    Write-OperationLog -Operation "Prerequisites" -Status "SUCCESS" -Message "All prerequisites met"
}

function Import-Configuration {
    param([string]$ConfigPath)
    
    Write-OperationLog -Operation "Configuration" -Status "INFO" -Message "Loading configuration from $ConfigPath"
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        
        # Validate required fields
        $requiredFields = @(
            "organization.prefix",
            "organization.location",
            "azure.subscription_id",
            "azure.tenant_id"
        )
        
        foreach ($field in $requiredFields) {
            $parts = $field.Split('.')
            $value = $config
            foreach ($part in $parts) {
                $value = $value.$part
            }
            if (-not $value) {
                throw "Required configuration field missing: $field"
            }
        }
        
        # Validate organization prefix
        if ($config.organization.prefix -notmatch '^[a-z0-9]{2,10}$') {
            throw "Organization prefix must be 2-10 lowercase alphanumeric characters"
        }
        
        Write-OperationLog -Operation "Configuration" -Status "SUCCESS" -Message "Configuration loaded and validated"
        return $config
        
    } catch {
        Write-OperationLog -Operation "Configuration" -Status "ERROR" -Message "Failed to load configuration: $($_.Exception.Message)"
        throw
    }
}

function Set-AzureContext {
    param($Config)
    
    Write-OperationLog -Operation "AzureContext" -Status "INFO" -Message "Setting Azure context"
    
    try {
        # Set subscription
        az account set --subscription $Config.azure.subscription_id
        
        # Verify access
        $subscription = az account show --output json | ConvertFrom-Json
        if ($subscription.id -ne $Config.azure.subscription_id) {
            throw "Failed to set subscription context"
        }
        
        Write-OperationLog -Operation "AzureContext" -Status "SUCCESS" -Message "Using subscription: $($subscription.name) ($($subscription.id))"
        
    } catch {
        Write-OperationLog -Operation "AzureContext" -Status "ERROR" -Message "Failed to set Azure context: $($_.Exception.Message)"
        throw
    }
}

function New-ResourceGroupIfNotExists {
    param($Name, $Location, $Tags = @{})
    
    Write-OperationLog -Operation "ResourceGroup" -Status "INFO" -Message "Checking resource group: $Name"
    
    try {
        # Check if exists
        $existing = az group show --name $Name --output json 2>$null | ConvertFrom-Json
        
        if ($existing -and -not $Force) {
            Write-OperationLog -Operation "ResourceGroup" -Status "SUCCESS" -Message "Resource group '$Name' already exists"
            return $existing
        }
        
        if ($WhatIf) {
            Write-OperationLog -Operation "ResourceGroup" -Status "WARNING" -Message "WHATIF: Would create resource group '$Name' in '$Location'"
            return @{ name = $Name; location = $Location }
        }
        
        # Create resource group
        Write-OperationLog -Operation "ResourceGroup" -Status "INFO" -Message "Creating resource group '$Name' in '$Location'"
        
        $tagParams = ""
        if ($Tags.Count -gt 0) {
            $tagString = ($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
            $tagParams = "--tags $tagString"
        }
        
        $result = az group create --name $Name --location $Location $tagParams --output json | ConvertFrom-Json
        
        Write-OperationLog -Operation "ResourceGroup" -Status "SUCCESS" -Message "Created resource group '$Name'"
        $script:CreatedResources += @{ Type = "ResourceGroup"; Name = $Name; Id = $result.id }
        
        return $result
        
    } catch {
        Write-OperationLog -Operation "ResourceGroup" -Status "ERROR" -Message "Failed to create resource group '$Name': $($_.Exception.Message)"
        throw
    }
}

function New-StorageAccountIfNotExists {
    param($Name, $ResourceGroupName, $Location)
    
    Write-OperationLog -Operation "StorageAccount" -Status "INFO" -Message "Checking storage account: $Name"
    
    try {
        # Check if exists
        $existing = az storage account show --name $Name --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
        
        if ($existing -and -not $Force) {
            Write-OperationLog -Operation "StorageAccount" -Status "SUCCESS" -Message "Storage account '$Name' already exists"
            return $existing
        }
        
        if ($WhatIf) {
            Write-OperationLog -Operation "StorageAccount" -Status "WARNING" -Message "WHATIF: Would create storage account '$Name'"
            return @{ name = $Name }
        }
        
        # Create storage account
        Write-OperationLog -Operation "StorageAccount" -Status "INFO" -Message "Creating storage account '$Name'"
        
        $result = az storage account create `
            --name $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku "Standard_LRS" `
            --kind "StorageV2" `
            --https-only true `
            --min-tls-version "TLS1_2" `
            --allow-blob-public-access false `
            --output json | ConvertFrom-Json
        
        Write-OperationLog -Operation "StorageAccount" -Status "SUCCESS" -Message "Created storage account '$Name'"
        $script:CreatedResources += @{ Type = "StorageAccount"; Name = $Name; Id = $result.id }
        
        return $result
        
    } catch {
        Write-OperationLog -Operation "StorageAccount" -Status "ERROR" -Message "Failed to create storage account '$Name': $($_.Exception.Message)"
        throw
    }
}

function New-StorageContainerIfNotExists {
    param($ContainerName, $StorageAccountName)
    
    Write-OperationLog -Operation "StorageContainer" -Status "INFO" -Message "Checking storage container: $ContainerName"
    
    try {
        # Check if exists
        $existing = az storage container show --name $ContainerName --account-name $StorageAccountName --output json 2>$null | ConvertFrom-Json
        
        if ($existing -and -not $Force) {
            Write-OperationLog -Operation "StorageContainer" -Status "SUCCESS" -Message "Storage container '$ContainerName' already exists"
            return $existing
        }
        
        if ($WhatIf) {
            Write-OperationLog -Operation "StorageContainer" -Status "WARNING" -Message "WHATIF: Would create storage container '$ContainerName'"
            return @{ name = $ContainerName }
        }
        
        # Create container
        Write-OperationLog -Operation "StorageContainer" -Status "INFO" -Message "Creating storage container '$ContainerName'"
        
        $result = az storage container create `
            --name $ContainerName `
            --account-name $StorageAccountName `
            --output json | ConvertFrom-Json
        
        Write-OperationLog -Operation "StorageContainer" -Status "SUCCESS" -Message "Created storage container '$ContainerName'"
        
        return $result
        
    } catch {
        Write-OperationLog -Operation "StorageContainer" -Status "ERROR" -Message "Failed to create storage container '$ContainerName': $($_.Exception.Message)"
        throw
    }
}

function New-ServicePrincipalIfNotExists {
    param($Name, $SubscriptionId)
    
    Write-OperationLog -Operation "ServicePrincipal" -Status "INFO" -Message "Checking service principal: $Name"
    
    try {
        # Check if exists
        $existing = az ad sp list --display-name $Name --output json 2>$null | ConvertFrom-Json
        
        if ($existing -and $existing.Count -gt 0 -and -not $Force) {
            Write-OperationLog -Operation "ServicePrincipal" -Status "SUCCESS" -Message "Service principal '$Name' already exists"
            return @{
                appId = $existing[0].appId
                objectId = $existing[0].id
                displayName = $existing[0].displayName
            }
        }
        
        if ($WhatIf) {
            Write-OperationLog -Operation "ServicePrincipal" -Status "WARNING" -Message "WHATIF: Would create service principal '$Name'"
            return @{ displayName = $Name }
        }
        
        # Create service principal
        Write-OperationLog -Operation "ServicePrincipal" -Status "INFO" -Message "Creating service principal '$Name'"
        
        $result = az ad sp create-for-rbac `
            --name $Name `
            --role "Contributor" `
            --scopes "/subscriptions/$SubscriptionId" `
            --output json | ConvertFrom-Json
        
        Write-OperationLog -Operation "ServicePrincipal" -Status "SUCCESS" -Message "Created service principal '$Name'"
        Write-OperationLog -Operation "ServicePrincipal" -Status "WARNING" -Message "⚠️  IMPORTANT: Save these credentials securely!"
        Write-OperationLog -Operation "ServicePrincipal" -Status "INFO" -Message "App ID: $($result.appId)"
        Write-OperationLog -Operation "ServicePrincipal" -Status "INFO" -Message "Tenant ID: $($result.tenant)"
        
        $script:CreatedResources += @{ Type = "ServicePrincipal"; Name = $Name; AppId = $result.appId }
        
        return $result
        
    } catch {
        Write-OperationLog -Operation "ServicePrincipal" -Status "ERROR" -Message "Failed to create service principal '$Name': $($_.Exception.Message)"
        throw
    }
}

function Write-BootstrapSummary {
    param($Config, $Results)
    
    Write-Host ""
    Write-Host "🎉 Bootstrap Complete!" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Created Resources:" -ForegroundColor Cyan
    foreach ($resource in $script:CreatedResources) {
        Write-Host "  ✓ $($resource.Type): $($resource.Name)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Set environment variables for Terraform:" -ForegroundColor White
    
    if ($Results.ServicePrincipal -and $Results.ServicePrincipal.appId) {
        Write-Host "   export ARM_CLIENT_ID='$($Results.ServicePrincipal.appId)'" -ForegroundColor Yellow
        Write-Host "   export ARM_CLIENT_SECRET='<service-principal-password>'" -ForegroundColor Yellow
        Write-Host "   export ARM_SUBSCRIPTION_ID='$($Config.azure.subscription_id)'" -ForegroundColor Yellow
        Write-Host "   export ARM_TENANT_ID='$($Config.azure.tenant_id)'" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "2. Configure Terraform backend in your configuration:" -ForegroundColor White
    Write-Host "   resource_group_name  = '$($Results.ResourceGroup.name)'" -ForegroundColor Yellow
    Write-Host "   storage_account_name = '$($Results.StorageAccount.name)'" -ForegroundColor Yellow
    Write-Host "   container_name       = '$($Results.StorageContainer.name)'" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "3. Initialize Terraform in your environment directory" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Log file: $script:LogFile" -ForegroundColor Cyan
}

# Main execution
try {
    Write-Host "🚀 Azure Infrastructure Bootstrap" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host ""
    
    if ($WhatIf) {
        Write-Host "🔍 WHATIF MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Step 1: Prerequisites
    Test-Prerequisites
    
    # Step 2: Load configuration
    $config = Import-Configuration -ConfigPath $ConfigFile
    
    # Step 3: Set Azure context
    Set-AzureContext -Config $config
    
    # Step 4: Generate resource names
    $resourceNames = @{
        StateResourceGroup = "rg-$($config.organization.prefix)-terraform-state"
        StateStorageAccount = "$($config.organization.prefix)$($config.terraform.state_storage_account_prefix)$(Get-Random -Minimum 1000 -Maximum 9999)"
        StateContainer = $config.terraform.state_container_name
        ServicePrincipal = "$($config.organization.prefix)-terraform-bootstrap"
    }
    
    # Step 5: Create resources
    $results = @{}
    
    $commonTags = @{
        "Purpose" = "Terraform State Management"
        "Environment" = $config.organization.environment
        "ManagedBy" = "Bootstrap Script"
        "Organization" = $config.organization.prefix
    }
    
    $results.ResourceGroup = New-ResourceGroupIfNotExists -Name $resourceNames.StateResourceGroup -Location $config.organization.location -Tags $commonTags
    $results.StorageAccount = New-StorageAccountIfNotExists -Name $resourceNames.StateStorageAccount -ResourceGroupName $resourceNames.StateResourceGroup -Location $config.organization.location
    $results.StorageContainer = New-StorageContainerIfNotExists -ContainerName $resourceNames.StateContainer -StorageAccountName $resourceNames.StateStorageAccount
    $results.ServicePrincipal = New-ServicePrincipalIfNotExists -Name $resourceNames.ServicePrincipal -SubscriptionId $config.azure.subscription_id
    
    # Step 6: Summary
    Write-BootstrapSummary -Config $config -Results $results
    
} catch {
    Write-OperationLog -Operation "Bootstrap" -Status "ERROR" -Message "Bootstrap failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "❌ Bootstrap failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "📋 Check log file for details: $script:LogFile" -ForegroundColor Yellow
    exit 1
}
