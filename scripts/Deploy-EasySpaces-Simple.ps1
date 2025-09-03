# Easy Spaces Dynamics 365 Simple Deployment Script
# This version avoids complex object serialization issues

param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseInteractiveAuth,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipEntityCreation
)

# Function to check if required modules are installed
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Cyan
    
    $requiredModules = @(
        "Microsoft.PowerApps.Administration.PowerShell",
        "Microsoft.PowerApps.PowerShell"
    )
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing $module..." -ForegroundColor Yellow
            try {
                Install-Module $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to install $module. Please install manually." -ForegroundColor Red
                Write-Host "Run: Install-Module $module -Scope CurrentUser" -ForegroundColor Yellow
                exit 1
            }
        }
        Import-Module $module -Force
    }
    
    Write-Host "Prerequisites check completed." -ForegroundColor Green
}

# Function to connect to Power Platform
function Connect-PowerPlatform {
    Write-Host "Connecting to Power Platform..." -ForegroundColor Cyan
    
    try {
        if ($UseInteractiveAuth) {
            # Interactive authentication
            Add-PowerAppsAccount -Endpoint prod
        }
        else {
            Write-Host "Please sign in when prompted..." -ForegroundColor Yellow
            Add-PowerAppsAccount -Endpoint prod
        }
        
        Write-Host "Successfully connected to Power Platform" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to connect: $_" -ForegroundColor Red
        return $false
    }
}

# Function to extract environment details
function Get-EnvironmentInfo {
    param($envUrl)
    
    # Extract environment name from URL
    if ($envUrl -match "https://([^.]+)\.") {
        $envName = $matches[1]
        return $envName
    }
    else {
        Write-Host "Could not parse environment name from URL: $envUrl" -ForegroundColor Red
        return $null
    }
}

# Function to create deployment package
function Create-DeploymentPackage {
    Write-Host "Creating deployment package..." -ForegroundColor Cyan
    
    $packagePath = Join-Path (Get-Location) "EasySpaces-DeploymentPackage"
    
    if (Test-Path $packagePath) {
        Remove-Item $packagePath -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    
    # Copy solution files
    $sourcePaths = @(
        "../solution",
        "../model-driven-app", 
        "../canvas-app",
        "../power-automate",
        "../data"
    )
    
    foreach ($path in $sourcePaths) {
        if (Test-Path $path) {
            $destPath = Join-Path $packagePath (Split-Path $path -Leaf)
            Copy-Item $path $destPath -Recurse -Force
        }
    }
    
    Write-Host "Deployment package created at: $packagePath" -ForegroundColor Green
    return $packagePath
}

# Function to generate manual deployment instructions
function Generate-ManualInstructions {
    param($envUrl, $packagePath)
    
    $instructionsPath = Join-Path $packagePath "MANUAL_DEPLOYMENT_STEPS.md"
    
    $instructions = @"
# Easy Spaces - Manual Deployment Instructions

## Environment Information
- **Target Environment**: $envUrl
- **Package Location**: $packagePath

## Step-by-Step Deployment

### 1. Create Custom Tables (Entities)

#### A. Create Market Table
1. Go to https://make.powerapps.com/
2. Select your environment
3. Click "Tables" → "New table"
4. Configure:
   - **Display name**: Market
   - **Plural name**: Markets
   - **Primary column**: Market Name (Text)
5. Add these columns:
   - City (Text, Required)
   - State (Text, Optional)
   - Country (Text, Optional)
   - Total Daily Booking Rate (Currency, Optional)
   - Predicted Booking Rate (Decimal, Optional)

#### B. Create Space Table
1. Click "Tables" → "New table"
2. Configure:
   - **Display name**: Space
   - **Plural name**: Spaces
   - **Primary column**: Space Name (Text)
3. Add these columns:
   - Type (Choice: Warehouse, Office, Café, Game Room, Gallery, Rooftop, Theater)
   - Category (Choice: Indoor, Outdoor, Hybrid)
   - Minimum Capacity (Whole Number, Required)
   - Maximum Capacity (Whole Number, Required)
   - Daily Booking Rate (Currency, Required)
   - Picture URL (Text, 500 chars)
   - Market (Lookup to Market table, Required)
   - Predicted Demand (Choice: Low, Medium, High)
   - Predicted Booking Rate (Decimal)

#### C. Create Reservation Table
1. Click "Tables" → "New table"
2. Configure:
   - **Display name**: Reservation
   - **Plural name**: Reservations
   - **Primary column**: Reservation Name (Text)
3. Add these columns:
   - Status (Choice: Draft, Submitted, Confirmed, Cancelled, Completed)
   - Start Date (Date Only, Required)
   - End Date (Date Only, Required)
   - Start Time (Text, 10 chars)
   - End Time (Text, 10 chars)
   - Total Number of Guests (Whole Number, Required)
   - Space (Lookup to Space table, Required)
   - Market (Lookup to Market table)
   - Contact (Lookup to Contact table)
   - Lead (Lookup to Lead table)
   - Account (Lookup to Account table)

### 2. Import Sample Data
1. Open your Model-driven app (create one if needed)
2. Navigate to Markets
3. Click "Import from Excel" 
4. Use the file: ``data/sample-data.csv``
5. Map columns appropriately
6. Repeat for Spaces

### 3. Create Model-Driven App
1. In Power Apps, click "Apps" → "New app" → "Model-driven"
2. Name: "Easy Spaces Management"
3. Add tables: Market, Space, Reservation, Contact, Lead, Account
4. Configure site map navigation
5. Save and publish

### 4. Import Canvas App
1. In Power Apps, click "Apps" → "Import canvas app"
2. Upload the file: ``canvas-app/EasySpacesCanvas.json``
3. Configure data connections during import
4. Test and publish

### 5. Set up Power Automate Flows
1. Go to https://make.powerautomate.com/
2. Click "Import" → "Import package"
3. Import flows from ``power-automate/`` folder
4. Update connections and activate

### 6. Test the Solution
1. Open Canvas app and browse spaces
2. Create a test reservation
3. Verify flows trigger correctly
4. Check data in Model-driven app

## Troubleshooting
- Ensure all lookup relationships are properly configured
- Verify security roles allow access to custom tables
- Check that flows are activated and connections work
- Test with sample data first

## Need Help?
Refer to the main documentation in the repository for detailed guidance.
"@

    $instructions | Out-File -FilePath $instructionsPath -Encoding UTF8
    Write-Host "Manual deployment instructions created at: $instructionsPath" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " Easy Spaces Simple Deployment" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
    
    # Check prerequisites
    Check-Prerequisites
    
    # Connect to Power Platform
    if (-not (Connect-PowerPlatform)) {
        throw "Failed to connect to Power Platform"
    }
    
    # Get environment info
    $envName = Get-EnvironmentInfo -envUrl $EnvironmentUrl
    if (-not $envName) {
        throw "Could not determine environment name"
    }
    
    Write-Host "Target Environment: $envName" -ForegroundColor Green
    
    # Create deployment package
    $packagePath = Create-DeploymentPackage
    
    # Generate manual instructions
    Generate-ManualInstructions -envUrl $EnvironmentUrl -packagePath $packagePath
    
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " Deployment Package Ready!" -ForegroundColor Green
    Write-Host "================================`n" -ForegroundColor Magenta
    
    Write-Host "Due to API limitations, manual deployment is recommended." -ForegroundColor Yellow
    Write-Host "Please follow the instructions in: $packagePath\MANUAL_DEPLOYMENT_STEPS.md" -ForegroundColor Cyan
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Open the manual deployment instructions" -ForegroundColor White
    Write-Host "2. Create the custom tables in Power Apps" -ForegroundColor White
    Write-Host "3. Import the Canvas app and flows" -ForegroundColor White
    Write-Host "4. Load sample data and test" -ForegroundColor White
    
    # Open the instructions file
    if (Test-Path $packagePath) {
        Write-Host "`nOpening deployment folder..." -ForegroundColor Green
        Start-Process explorer $packagePath
    }
}
catch {
    Write-Host "`nError occurred: $_" -ForegroundColor Red
    Write-Host "Recommendation: Use manual deployment through Power Apps web interface" -ForegroundColor Yellow
    exit 1
}
finally {
    Write-Host "`nDeployment preparation completed." -ForegroundColor Green
}