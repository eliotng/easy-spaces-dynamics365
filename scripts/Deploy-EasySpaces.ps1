# Easy Spaces Dynamics 365 Deployment Script
# This script helps deploy the Easy Spaces solution to your Dynamics 365 environment

param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [SecureString]$Password,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseInteractiveAuth,
    
    [Parameter(Mandatory=$false)]
    [switch]$ImportSampleData
)

# Function to check if required modules are installed
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Cyan
    
    $requiredModules = @(
        "Microsoft.PowerApps.Administration.PowerShell",
        "Microsoft.PowerApps.PowerShell",
        "Microsoft.Xrm.Data.PowerShell",
        "Microsoft.Xrm.OnlineManagementAPI"
    )
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing $module..." -ForegroundColor Yellow
            Install-Module $module -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module $module -Force
    }
    
    Write-Host "Prerequisites check completed." -ForegroundColor Green
}

# Function to connect to Dynamics 365
function Connect-D365 {
    Write-Host "Connecting to Dynamics 365..." -ForegroundColor Cyan
    
    try {
        if ($UseInteractiveAuth) {
            # Interactive authentication (browser-based)
            $conn = Connect-CrmOnline -ServerUrl $EnvironmentUrl -ForceOAuth
        }
        else {
            # Username/Password authentication
            if (-not $Username) {
                $Username = Read-Host "Enter username"
            }
            if (-not $Password) {
                $Password = Read-Host "Enter password" -AsSecureString
            }
            
            $cred = New-Object System.Management.Automation.PSCredential($Username, $Password)
            $conn = Connect-CrmOnline -ServerUrl $EnvironmentUrl -Credential $cred
        }
        
        Write-Host "Successfully connected to $EnvironmentUrl" -ForegroundColor Green
        return $conn
    }
    catch {
        Write-Host "Failed to connect: $_" -ForegroundColor Red
        exit 1
    }
}

# Function to create publisher
function Create-Publisher {
    param($conn)
    
    Write-Host "Creating/Updating Publisher..." -ForegroundColor Cyan
    
    $publisher = @{
        uniquename = "easyspaces"
        friendlyname = "Easy Spaces"
        customizationprefix = "es"
        customizationoptionvalueprefix = 10000
        description = "Easy Spaces Publisher"
    }
    
    # Check if publisher exists
    try {
        $existingPublisher = Get-CrmRecords -conn $conn -EntityLogicalName publisher -FilterAttribute uniquename -FilterOperator eq -FilterValue $publisher.uniquename
        
        if ($existingPublisher.Count -eq 0) {
            # Create new publisher
            Write-Host "  Creating publisher with prefix: $($publisher.customizationprefix) and option value prefix: $($publisher.customizationoptionvalueprefix)" -ForegroundColor White
            $publisherId = New-CrmRecord -conn $conn -EntityLogicalName publisher -Fields $publisher
            Write-Host "Publisher created successfully" -ForegroundColor Green
        }
        else {
            $publisherId = $existingPublisher.CrmRecords[0].publisherid
            Write-Host "Publisher already exists" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error creating publisher: $_" -ForegroundColor Red
        
        # Try using default publisher instead
        Write-Host "Attempting to use default publisher..." -ForegroundColor Yellow
        $defaultPublisher = Get-CrmRecords -conn $conn -EntityLogicalName publisher -FilterAttribute uniquename -FilterOperator eq -FilterValue "default"
        if ($defaultPublisher.Count -gt 0) {
            $publisherId = $defaultPublisher.CrmRecords[0].publisherid
            Write-Host "Using default publisher" -ForegroundColor Green
        }
        else {
            throw "Could not create or find a suitable publisher"
        }
    }
    
    return $publisherId
}

# Function to create solution
function Create-Solution {
    param($conn, $publisherId)
    
    Write-Host "Creating/Updating Solution..." -ForegroundColor Cyan
    
    $solution = @{
        uniquename = "EasySpaces"
        friendlyname = "Easy Spaces"
        version = "1.0.0.0"
        description = "Event management solution for creating and managing custom pop-up spaces"
        publisherid = @{Id=$publisherId;LogicalName="publisher"}
    }
    
    # Check if solution exists
    $existingSolution = Get-CrmRecords -conn $conn -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator eq -FilterValue $solution.uniquename
    
    if ($existingSolution.Count -eq 0) {
        # Create new solution
        $solutionId = New-CrmRecord -conn $conn -EntityLogicalName solution -Fields $solution
        Write-Host "Solution created successfully" -ForegroundColor Green
    }
    else {
        $solutionId = $existingSolution.CrmRecords[0].solutionid
        Write-Host "Solution already exists" -ForegroundColor Yellow
    }
    
    return $solutionId
}

# Function to create entities
function Create-Entities {
    param($conn, $solutionName)
    
    Write-Host "Creating Custom Entities..." -ForegroundColor Cyan
    
    # Define entities
    $entities = @(
        @{
            SchemaName = "es_market"
            DisplayName = "Market"
            DisplayCollectionName = "Markets"
            Description = "Represents a geographical market for Easy Spaces"
            OwnershipType = "UserOwned"
            PrimaryNameAttribute = "es_name"
        },
        @{
            SchemaName = "es_space"
            DisplayName = "Space"
            DisplayCollectionName = "Spaces"
            Description = "Represents a rentable space for events"
            OwnershipType = "UserOwned"
            PrimaryNameAttribute = "es_name"
        },
        @{
            SchemaName = "es_reservation"
            DisplayName = "Reservation"
            DisplayCollectionName = "Reservations"
            Description = "Represents a space reservation for an event"
            OwnershipType = "UserOwned"
            PrimaryNameAttribute = "es_name"
        }
    )
    
    foreach ($entity in $entities) {
        Write-Host "  Creating entity: $($entity.DisplayName)..." -ForegroundColor White
        
        try {
            # Check if entity exists
            $existingEntity = Get-CrmRecords -conn $conn -EntityLogicalName entity -FilterAttribute schemaname -FilterOperator eq -FilterValue $entity.SchemaName
            
            if ($existingEntity.Count -eq 0) {
                # Entity creation would be done through API or SDK
                Write-Host "    Entity $($entity.DisplayName) needs to be created through Power Platform Admin Center" -ForegroundColor Yellow
            }
            else {
                Write-Host "    Entity $($entity.DisplayName) already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "    Note: $($entity.DisplayName) needs manual creation" -ForegroundColor Yellow
        }
    }
}

# Function to import sample data
function Import-SampleData {
    param($conn)
    
    Write-Host "Importing Sample Data..." -ForegroundColor Cyan
    
    # Create sample markets
    $markets = @(
        @{es_name="San Francisco";es_city="San Francisco";es_state="CA";es_country="USA"},
        @{es_name="New York";es_city="New York";es_state="NY";es_country="USA"},
        @{es_name="Chicago";es_city="Chicago";es_state="IL";es_country="USA"},
        @{es_name="Los Angeles";es_city="Los Angeles";es_state="CA";es_country="USA"}
    )
    
    $marketIds = @{}
    foreach ($market in $markets) {
        try {
            $marketId = New-CrmRecord -conn $conn -EntityLogicalName es_market -Fields $market
            $marketIds[$market.es_name] = $marketId
            Write-Host "  Created market: $($market.es_name)" -ForegroundColor Green
        }
        catch {
            Write-Host "  Note: Market data will need manual import" -ForegroundColor Yellow
            break
        }
    }
    
    # Create sample spaces
    $spaces = @(
        @{
            es_name="Starlight Gallery"
            es_type=100000004
            es_category=100000000
            es_minimumcapacity=10
            es_maximumcapacity=100
            es_dailybookingrate=1500
        },
        @{
            es_name="Urban Rooftop"
            es_type=100000005
            es_category=100000001
            es_minimumcapacity=20
            es_maximumcapacity=150
            es_dailybookingrate=2000
        },
        @{
            es_name="Tech Hub"
            es_type=100000001
            es_category=100000000
            es_minimumcapacity=5
            es_maximumcapacity=50
            es_dailybookingrate=800
        }
    )
    
    foreach ($space in $spaces) {
        try {
            # Assign to first market
            if ($marketIds.Count -gt 0) {
                $space.es_marketid = @{Id=$marketIds.Values[0];LogicalName="es_market"}
            }
            
            $spaceId = New-CrmRecord -conn $conn -EntityLogicalName es_space -Fields $space
            Write-Host "  Created space: $($space.es_name)" -ForegroundColor Green
        }
        catch {
            Write-Host "  Note: Space data will need manual import" -ForegroundColor Yellow
            break
        }
    }
}

# Main execution
try {
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " Easy Spaces Deployment Script" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
    
    # Check prerequisites
    Check-Prerequisites
    
    # Connect to Dynamics 365
    $conn = Connect-D365
    
    # Create publisher
    $publisherId = Create-Publisher -conn $conn
    
    # Create solution
    $solutionId = Create-Solution -conn $conn -publisherId $publisherId
    
    # Create entities
    Create-Entities -conn $conn -solutionName "EasySpaces"
    
    # Import sample data if requested
    if ($ImportSampleData) {
        Import-SampleData -conn $conn
    }
    
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " Deployment Process Completed!" -ForegroundColor Green
    Write-Host "================================`n" -ForegroundColor Magenta
    
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Log into Power Platform Admin Center" -ForegroundColor White
    Write-Host "2. Navigate to your environment: $EnvironmentUrl" -ForegroundColor White
    Write-Host "3. Complete entity creation through the UI if needed" -ForegroundColor White
    Write-Host "4. Import the Canvas App from the canvas-app folder" -ForegroundColor White
    Write-Host "5. Configure security roles and permissions" -ForegroundColor White
    Write-Host "6. Test the application" -ForegroundColor White
}
catch {
    Write-Host "`nError occurred: $_" -ForegroundColor Red
    exit 1
}
finally {
    if ($conn) {
        # Disconnect if cmdlet is available
        if (Get-Command Disconnect-CrmOnline -ErrorAction SilentlyContinue) {
            Disconnect-CrmOnline -conn $conn
        }
        else {
            Write-Host "Session cleanup completed" -ForegroundColor Green
        }
    }
}