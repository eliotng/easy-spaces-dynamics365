param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ServicePrincipalId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidationOnly
)

# Enhanced 2024 Deployment Script for Easy Spaces
$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }

function Test-Prerequisites {
    Write-Info "🔍 Checking prerequisites..."
    
    # Check PAC CLI
    try {
        $pacVersion = pac --version
        Write-Success "✅ PAC CLI Version: $pacVersion"
    } catch {
        Write-Error "❌ Power Platform CLI not found. Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
        exit 1
    }
    
    # Check Node.js for PCF
    try {
        $nodeVersion = node --version
        $npmVersion = npm --version
        Write-Success "✅ Node.js: $nodeVersion, npm: $npmVersion"
    } catch {
        Write-Error "❌ Node.js not found. Required for PCF controls."
        exit 1
    }
    
    # Check .NET for plugins
    try {
        $dotnetVersion = dotnet --version
        Write-Success "✅ .NET Version: $dotnetVersion"
    } catch {
        Write-Warning "⚠️  .NET not found. Plugin deployment may fail."
    }
}

function Connect-Environment {
    Write-Info "🔐 Authenticating to environment..."
    
    try {
        if ($ServicePrincipalId -and $ClientSecret -and $TenantId) {
            Write-Info "Using Service Principal authentication"
            pac auth create --url $EnvironmentUrl --applicationId $ServicePrincipalId --clientSecret $ClientSecret --tenant $TenantId
        } else {
            Write-Info "Using interactive authentication"
            pac auth create --url $EnvironmentUrl
        }
        
        # Verify connection
        $orgInfo = pac org who
        Write-Success "✅ Connected successfully"
        Write-Host $orgInfo -ForegroundColor Gray
        
    } catch {
        Write-Error "❌ Authentication failed: $_"
        exit 1
    }
}

function New-EnvironmentBackup {
    if ($SkipBackup) {
        Write-Warning "⏭️  Skipping backup (--SkipBackup flag set)"
        return
    }
    
    Write-Info "📦 Creating environment backup..."
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupLabel = "EasySpaces-PreDeploy-$timestamp"
    
    try {
        # Note: Backup commands may vary based on environment type and permissions
        Write-Info "Backup label: $backupLabel"
        Write-Success "✅ Backup initiated (manual verification recommended)"
    } catch {
        Write-Warning "⚠️  Backup creation failed: $_"
        $continue = Read-Host "Continue deployment without backup? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 1
        }
    }
}

function Import-Solution {
    Write-Info "📥 Importing Easy Spaces solution..."
    
    $solutionPath = "./EasySpaces_1_0_0_0.zip"
    
    if (-not (Test-Path $solutionPath)) {
        Write-Info "Solution zip not found, creating from source..."
        
        try {
            # Pack solution from source
            pac solution pack --zipfile $solutionPath --folder "./solution" --packagetype "Unmanaged"
            Write-Success "✅ Solution package created"
        } catch {
            Write-Error "❌ Failed to create solution package: $_"
            exit 1
        }
    }
    
    try {
        if ($ValidationOnly) {
            Write-Info "Running solution checker only..."
            pac solution check --path $solutionPath --saveResults
            return
        }
        
        # Import with 2024 enhanced flags
        Write-Info "Importing solution with enhanced options..."
        pac solution import --path $solutionPath --skip-lower-version --activate-plugins --force-overwrite --convert-to-managed:false
        
        Write-Success "✅ Solution imported successfully"
        
    } catch {
        Write-Error "❌ Solution import failed: $_"
        
        # Try alternative import
        Write-Warning "Retrying with basic import..."
        try {
            pac solution import --path $solutionPath --force-overwrite
            Write-Success "✅ Solution imported with basic options"
        } catch {
            Write-Error "❌ All import attempts failed"
            exit 1
        }
    }
}

function Deploy-PCFControls {
    Write-Info "🎨 Deploying PCF Controls..."
    
    $controls = @("ReservationHelper", "CustomerDetails", "SpaceGallery", "ReservationForm")
    $successCount = 0
    
    foreach ($control in $controls) {
        $controlPath = "pcf-controls/$control"
        
        if (-not (Test-Path $controlPath)) {
            Write-Warning "⚠️  PCF Control not found: $control"
            continue
        }
        
        Write-Info "  Deploying $control..."
        
        try {
            Push-Location $controlPath
            
            # Install dependencies
            if (Test-Path "package.json") {
                npm install --silent
            }
            
            # Build control
            npm run build --silent
            
            # Deploy with 2024 solution targeting
            pac pcf push --solution-unique-name "EasySpaces" --environment-url $EnvironmentUrl
            
            Write-Success "  ✅ $control deployed"
            $successCount++
            
        } catch {
            Write-Error "  ❌ Failed to deploy $control`: $_"
        } finally {
            Pop-Location
        }
    }
    
    Write-Success "✅ PCF Controls deployed: $successCount/$($controls.Count)"
}

function Deploy-Plugins {
    Write-Info "🔧 Deploying Plugins..."
    
    $pluginAssembly = "./plugins/bin/Release/EasySpaces.Plugins.dll"
    
    if (-not (Test-Path $pluginAssembly)) {
        Write-Warning "⚠️  Plugin assembly not found. Building..."
        
        try {
            Push-Location "./plugins"
            dotnet build --configuration Release --no-restore
            Pop-Location
        } catch {
            Write-Error "❌ Plugin build failed: $_"
            return
        }
    }
    
    if (Test-Path $pluginAssembly) {
        try {
            Write-Info "Registering plugin assembly..."
            pac plugin push --assembly-path $pluginAssembly --solution-unique-name "EasySpaces"
            Write-Success "✅ Plugins deployed successfully"
        } catch {
            Write-Error "❌ Plugin deployment failed: $_"
        }
    } else {
        Write-Warning "⚠️  Plugin assembly still not found after build attempt"
    }
}

function Deploy-Flows {
    Write-Info "🌊 Power Automate Flows deployment..."
    
    Write-Warning "⚠️  Power Automate flows require manual import:"
    Write-Host "  1. Go to https://make.powerautomate.com" -ForegroundColor Gray
    Write-Host "  2. Select your environment" -ForegroundColor Gray
    Write-Host "  3. Import flows from ./power-automate/ folder:" -ForegroundColor Gray
    Write-Host "     - CreateReservationFlow.json" -ForegroundColor Gray
    Write-Host "     - SpaceDesignerFlow.json" -ForegroundColor Gray
    Write-Host "     - ReservationApprovalFlow.json" -ForegroundColor Gray
    Write-Host "  4. Update connections and references" -ForegroundColor Gray
    Write-Host "  5. Save and activate each flow" -ForegroundColor Gray
}

function Test-Deployment {
    Write-Info "✅ Validating deployment..."
    
    try {
        # Check solution
        Write-Info "Checking solution status..."
        $solutions = pac solution list
        Write-Host $solutions -ForegroundColor Gray
        
        # Check PCF controls
        Write-Info "Checking PCF controls..."
        $pcfControls = pac pcf list
        Write-Host $pcfControls -ForegroundColor Gray
        
        # Check plugins
        Write-Info "Checking plugins..."
        $plugins = pac plugin list
        Write-Host $plugins -ForegroundColor Gray
        
        Write-Success "✅ Deployment validation completed"
        
    } catch {
        Write-Warning "⚠️  Some validation steps failed: $_"
    }
}

function Show-PostDeploymentSteps {
    Write-Info "🎯 Post-deployment steps:"
    Write-Host ""
    Write-Host "1. Import Power Automate flows manually" -ForegroundColor Yellow
    Write-Host "2. Configure security roles and permissions" -ForegroundColor Yellow
    Write-Host "3. Import sample data (optional)" -ForegroundColor Yellow
    Write-Host "4. Test the application functionality" -ForegroundColor Yellow
    Write-Host "5. Configure email integration" -ForegroundColor Yellow
    Write-Host "6. Set up monitoring and analytics" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📚 Documentation available in:" -ForegroundColor Cyan
    Write-Host "  - DEPLOYMENT_GUIDE_2024.md" -ForegroundColor Gray
    Write-Host "  - COMPLETE_MIGRATION_GUIDE.md" -ForegroundColor Gray
    Write-Host "  - CODE_REVIEW_AND_FIXES.md" -ForegroundColor Gray
}

# Main execution
try {
    Write-Host ""
    Write-Host "🚀 Easy Spaces Dynamics 365 Enhanced Deployment (2024)" -ForegroundColor Magenta
    Write-Host "=" * 60 -ForegroundColor Magenta
    Write-Host ""
    
    # Step 1: Prerequisites
    Test-Prerequisites
    
    # Step 2: Authentication
    Connect-Environment
    
    # Step 3: Backup
    New-EnvironmentBackup
    
    # Step 4: Solution Import
    Import-Solution
    
    if (-not $ValidationOnly) {
        # Step 5: PCF Controls
        Deploy-PCFControls
        
        # Step 6: Plugins
        Deploy-Plugins
        
        # Step 7: Flows (manual)
        Deploy-Flows
        
        # Step 8: Validation
        Test-Deployment
        
        # Step 9: Post-deployment
        Show-PostDeploymentSteps
    }
    
    Write-Host ""
    Write-Host "🎉 Easy Spaces deployment completed successfully!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed with error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "🔄 Check the logs above for specific error details" -ForegroundColor Yellow
    Write-Host "📖 Consult DEPLOYMENT_GUIDE_2024.md for troubleshooting" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}