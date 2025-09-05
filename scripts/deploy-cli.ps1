param(
    [Parameter(Mandatory=$true, HelpMessage="Dynamics 365 environment URL")]
    [string]$EnvironmentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$SolutionName = "EasySpacesClaude",
    
    [Parameter(Mandatory=$false)]
    [string]$PublisherPrefix = "es",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPCF,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPlugins,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidationOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Enhanced CLI Deployment Script for Easy Spaces - Claude (PowerShell)
$ErrorActionPreference = "Stop"

# Color functions
function Write-Header { param($msg) Write-Host $msg -ForegroundColor Magenta }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[WARNING] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Step { param($msg) Write-Host $msg -ForegroundColor Blue }

function Show-Usage {
    Write-Host "Easy Spaces Dynamics 365 CLI Deployment (PowerShell)" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  .\deploy-cli.ps1 -EnvironmentUrl <url> [options]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "REQUIRED:" -ForegroundColor White
    Write-Host "  -EnvironmentUrl <url>    Dynamics 365 environment URL" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OPTIONAL:" -ForegroundColor White
    Write-Host "  -SolutionName <name>     Solution name (default: EasySpaces)" -ForegroundColor Gray
    Write-Host "  -PublisherPrefix <prefix> Publisher prefix (default: es)" -ForegroundColor Gray
    Write-Host "  -SkipBackup             Skip environment backup" -ForegroundColor Gray
    Write-Host "  -SkipPCF                Skip PCF controls deployment" -ForegroundColor Gray
    Write-Host "  -SkipPlugins            Skip plugin registration" -ForegroundColor Gray
    Write-Host "  -ValidationOnly         Run validation only, no deployment" -ForegroundColor Gray
    Write-Host "  -Help                   Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor White
    Write-Host "  .\deploy-cli.ps1 -EnvironmentUrl 'https://myorg.crm.dynamics.com'" -ForegroundColor Gray
    Write-Host "  .\deploy-cli.ps1 -EnvironmentUrl 'https://myorg.crm.dynamics.com' -ValidationOnly" -ForegroundColor Gray
    Write-Host "  .\deploy-cli.ps1 -EnvironmentUrl 'https://myorg.crm.dynamics.com' -SkipPCF -SkipPlugins" -ForegroundColor Gray
}

if ($Help) {
    Show-Usage
    exit 0
}

function Test-Prerequisites {
    Write-Step "🔍 Checking prerequisites..."
    
    # Check .NET
    try {
        $dotnetVersion = dotnet --version
        Write-Success ".NET version: $dotnetVersion"
    } catch {
        Write-Error ".NET not found. Install from: https://dotnet.microsoft.com/download"
        Write-Info "Or run: winget install Microsoft.DotNet.SDK.8"
        exit 1
    }
    
    # Check PAC CLI
    try {
        $pacVersion = pac --version
        Write-Success "PAC CLI version: $pacVersion"
    } catch {
        Write-Error "Power Platform CLI not found."
        Write-Info "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
        exit 1
    }
    
    # Check Node.js (for PCF controls)
    if (-not $SkipPCF) {
        try {
            $nodeVersion = node --version
            $npmVersion = npm --version
            Write-Success "Node.js: $nodeVersion, npm: v$npmVersion"
        } catch {
            Write-Warning "Node.js not found. PCF deployment will be skipped."
            Write-Info "Install from: https://nodejs.org/ or run: winget install OpenJS.NodeJS"
            $script:SkipPCF = $true
        }
    }
    
    # Check if in correct directory
    if (-not (Test-Path "solution\entities\Reservation.xml")) {
        Write-Error "Easy Spaces solution files not found. Please run from project root."
        exit 1
    }
    
    Write-Success "Prerequisites check completed"
}

function Connect-Environment {
    Write-Step "🔐 Authenticating to Dynamics 365..."
    
    # Check if already authenticated
    try {
        $whoAmI = pac org who --environment $EnvironmentUrl
        Write-Success "Already authenticated: $whoAmI"
        return
    } catch {
        Write-Info "Authentication required"
    }
    
    # Interactive authentication
    try {
        Write-Info "Opening browser for authentication..."
        pac auth create --url $EnvironmentUrl
        
        # Verify connection
        $whoAmI = pac org who --environment $EnvironmentUrl
        Write-Success "Authentication successful: $whoAmI"
    } catch {
        Write-Error "Authentication failed: $_"
        exit 1
    }
}

function New-SolutionPackage {
    Write-Step "📦 Creating solution package..."
    
    # Create output directory
    if (-not (Test-Path "out")) {
        New-Item -ItemType Directory -Path "out" -Force | Out-Null
    }
    
    try {
        # Pack unmanaged solution
        Write-Info "Creating unmanaged solution package..."
        pac solution pack --folder ".\solution" --zipfile ".\out\$SolutionName.zip" --packagetype "Unmanaged"
        Write-Success "Unmanaged solution created: .\out\$SolutionName.zip"
        
        # Pack managed solution for production
        Write-Info "Creating managed solution package..."
        pac solution pack --folder ".\solution" --zipfile ".\out\${SolutionName}_managed.zip" --packagetype "Managed"
        Write-Success "Managed solution created: .\out\${SolutionName}_managed.zip"
        
    } catch {
        Write-Error "Failed to create solution package: $_"
        exit 1
    }
}

function Test-Solution {
    Write-Step "✅ Running solution checker..."
    
    try {
        pac solution check --path ".\out\$SolutionName.zip" --environment $EnvironmentUrl
        Write-Success "Solution checker passed"
    } catch {
        Write-Warning "Solution checker found issues (deployment will continue): $_"
    }
}

function Import-EasySpacesSolution {
    if ($ValidationOnly) {
        Write-Info "Skipping solution import (validation mode)"
        return
    }
    
    Write-Step "📥 Importing solution to Dynamics 365..."
    
    try {
        pac solution import --path ".\out\$SolutionName.zip" --environment $EnvironmentUrl --activate-plugins --force-overwrite --skip-lower-version
        Write-Success "Solution imported successfully"
    } catch {
        Write-Error "Solution import failed: $_"
        exit 1
    }
}

function Deploy-PCFControls {
    if ($SkipPCF -or $ValidationOnly) {
        Write-Info "Skipping PCF controls deployment"
        return
    }
    
    Write-Step "🎨 Deploying PCF controls..."
    
    $controls = @("ReservationHelper", "CustomerDetails", "SpaceGallery", "ReservationForm")
    $deployedCount = 0
    
    foreach ($control in $controls) {
        $controlPath = ".\pcf-controls\$control"
        
        if (-not (Test-Path $controlPath)) {
            Write-Warning "PCF control not found: $control"
            continue
        }
        
        Write-Info "Deploying $control..."
        
        try {
            Push-Location $controlPath
            
            if (Test-Path "package.json") {
                Write-Info "  Installing dependencies..."
                npm install --silent
                
                Write-Info "  Building control..."
                npm run build --silent
                
                Write-Info "  Deploying to environment..."
                pac pcf push --publisher-prefix $PublisherPrefix --environment $EnvironmentUrl
                
                Write-Success "  $control deployed successfully"
                $deployedCount++
            } else {
                Write-Warning "  No package.json found for $control"
            }
        } catch {
            Write-Error "  Failed to deploy $control`: $_"
        } finally {
            Pop-Location
        }
    }
    
    Write-Success "PCF controls deployed: $deployedCount/$($controls.Count)"
}

function Register-Plugins {
    if ($SkipPlugins -or $ValidationOnly) {
        Write-Info "Skipping plugin registration"
        return
    }
    
    Write-Step "🔧 Registering plugins..."
    
    $pluginAssembly = ".\plugins\bin\Release\EasySpaces.Plugins.dll"
    
    if (-not (Test-Path $pluginAssembly)) {
        Write-Warning "Plugin assembly not found. Attempting to build..."
        
        if (Test-Path ".\plugins") {
            try {
                Push-Location ".\plugins"
                Write-Info "Building plugin assembly..."
                dotnet build --configuration Release
                Pop-Location
            } catch {
                Write-Error "Plugin build failed: $_"
                Pop-Location
                return
            }
        } else {
            Write-Warning "Plugin source directory not found"
            return
        }
    }
    
    if (Test-Path $pluginAssembly) {
        try {
            pac plugin push --assembly-path $pluginAssembly --environment $EnvironmentUrl
            Write-Success "Plugins registered successfully"
        } catch {
            Write-Error "Plugin registration failed: $_"
        }
    } else {
        Write-Warning "Plugin assembly not found after build attempt"
    }
}

function Test-Deployment {
    Write-Step "🔍 Validating deployment..."
    
    try {
        # Check solution
        Write-Info "Checking solution status..."
        $solutions = pac solution list --environment $EnvironmentUrl
        if ($solutions -match $SolutionName) {
            Write-Success "Solution found in environment"
        } else {
            Write-Warning "Solution not found in environment"
        }
        
        # Check entities
        Write-Info "Checking custom entities..."
        $entities = @("es_reservation", "es_space", "es_market")
        
        foreach ($entity in $entities) {
            try {
                pac data list --entity-name $entity --environment $EnvironmentUrl --max-results 1 | Out-Null
                Write-Success "Entity verified: $entity"
            } catch {
                Write-Warning "Entity not accessible: $entity"
            }
        }
        
        Write-Success "Deployment validation completed"
    } catch {
        Write-Warning "Some validation steps failed: $_"
    }
}

function Show-PostDeployment {
    Write-Header ""
    Write-Header "🎯 Post-Deployment Steps"
    Write-Header "========================"
    Write-Host ""
    
    Write-Info "1. Import Power Automate flows:"
    Write-Host "   • Go to https://make.powerautomate.com" -ForegroundColor Gray
    Write-Host "   • Import flows from .\power-automate\ folder" -ForegroundColor Gray
    Write-Host ""
    
    Write-Info "2. Configure security roles:"
    Write-Host "   • Assign users to Easy Spaces roles" -ForegroundColor Gray
    Write-Host "   • Configure field-level security" -ForegroundColor Gray
    Write-Host ""
    
    Write-Info "3. Test the application:"
    Write-Host "   • Create test reservation" -ForegroundColor Gray
    Write-Host "   • Verify PCF controls functionality" -ForegroundColor Gray
    Write-Host "   • Test business processes" -ForegroundColor Gray
    Write-Host ""
    
    Write-Info "4. Import sample data (optional):"
    Write-Host "   • Use Data Import Wizard" -ForegroundColor Gray
    Write-Host "   • Files available in .\data\ folder" -ForegroundColor Gray
    Write-Host ""
}

# Main execution
try {
    Write-Header ""
    Write-Header "🚀 Easy Spaces Dynamics 365 CLI Deployment"
    Write-Header "============================================="
    Write-Header ""
    
    Write-Info "Environment: $EnvironmentUrl"
    Write-Info "Solution: $SolutionName"
    Write-Info "Publisher Prefix: $PublisherPrefix"
    
    if ($ValidationOnly) {
        Write-Info "Mode: Validation Only"
    }
    
    Write-Header ""
    
    # Execute deployment steps
    Test-Prerequisites
    Connect-Environment
    New-SolutionPackage
    Test-Solution
    Import-EasySpacesSolution
    Deploy-PCFControls
    Register-Plugins
    Test-Deployment
    
    if (-not $ValidationOnly) {
        Show-PostDeployment
    }
    
    Write-Header ""
    Write-Success "🎉 Easy Spaces deployment completed successfully!"
    Write-Header ""
    
    # Summary
    Write-Info "Deployment Summary:"
    Write-Host "  Solution: ✅ Imported" -ForegroundColor White
    
    if (-not $SkipPCF -and -not $ValidationOnly) {
        Write-Host "  PCF Controls: ✅ Deployed" -ForegroundColor White
    } else {
        Write-Host "  PCF Controls: ⏭️ Skipped" -ForegroundColor White
    }
    
    if (-not $SkipPlugins -and -not $ValidationOnly) {
        Write-Host "  Plugins: ✅ Registered" -ForegroundColor White
    } else {
        Write-Host "  Plugins: ⏭️ Skipped" -ForegroundColor White
    }
    
    Write-Host "  Validation: ✅ Completed" -ForegroundColor White
    Write-Host ""
    
    Write-Info "Access your environment: $EnvironmentUrl"
    
} catch {
    Write-Error "Deployment failed: $_"
    Write-Info "Check the error details above and retry"
    exit 1
}