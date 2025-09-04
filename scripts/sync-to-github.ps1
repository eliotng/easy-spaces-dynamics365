param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$SolutionName = "EasySpaces",
    
    [Parameter(Mandatory=$false)]
    [string]$CommitMessage,
    
    [Parameter(Mandatory=$false)]
    [switch]$Push = $true
)

# Enhanced sync script for Easy Spaces to GitHub
$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColorOutput "🔍 Checking prerequisites..." "Cyan"
    
    # Check PAC CLI
    try {
        $pacVersion = pac --version
        Write-ColorOutput "✅ PAC CLI: $pacVersion" "Green"
    } catch {
        Write-ColorOutput "❌ Power Platform CLI not found" "Red"
        Write-ColorOutput "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool" "Yellow"
        exit 1
    }
    
    # Check Git
    try {
        $gitVersion = git --version
        Write-ColorOutput "✅ Git: $gitVersion" "Green"
    } catch {
        Write-ColorOutput "❌ Git not found" "Red"
        exit 1
    }
    
    # Check if we're in a git repository
    try {
        git rev-parse --git-dir | Out-Null
        Write-ColorOutput "✅ Git repository detected" "Green"
    } catch {
        Write-ColorOutput "❌ Not in a Git repository" "Red"
        Write-ColorOutput "Run 'git init' first" "Yellow"
        exit 1
    }
}

function Export-Solution {
    param($SolutionName, $EnvironmentUrl)
    
    Write-ColorOutput "📦 Exporting solution: $SolutionName" "Cyan"
    
    $tempDir = "./temp"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    try {
        # Export solution
        $solutionPath = "$tempDir/$SolutionName.zip"
        pac solution export --name $SolutionName --path $solutionPath --environment $EnvironmentUrl --managed false
        
        if (Test-Path $solutionPath) {
            Write-ColorOutput "✅ Solution exported successfully" "Green"
            return $solutionPath
        } else {
            throw "Solution export failed - file not found"
        }
    } catch {
        Write-ColorOutput "❌ Solution export failed: $_" "Red"
        exit 1
    }
}

function Unpack-Solution {
    param($SolutionPath, $SolutionName)
    
    Write-ColorOutput "📂 Unpacking solution for source control..." "Cyan"
    
    $solutionDir = "./solution/$SolutionName"
    
    try {
        # Remove existing solution folder if it exists
        if (Test-Path $solutionDir) {
            Remove-Item -Path $solutionDir -Recurse -Force
        }
        
        # Create solution directory
        New-Item -ItemType Directory -Path $solutionDir -Force | Out-Null
        
        # Unpack solution
        pac solution unpack --zipfile $SolutionPath --folder $solutionDir --packagetype "Unmanaged" --allowWrite
        
        Write-ColorOutput "✅ Solution unpacked successfully" "Green"
        return $solutionDir
    } catch {
        Write-ColorOutput "❌ Solution unpacking failed: $_" "Red"
        exit 1
    }
}

function Update-GitRepository {
    param($CommitMessage, $Push)
    
    Write-ColorOutput "📝 Updating Git repository..." "Cyan"
    
    try {
        # Check for changes
        $gitStatus = git status --porcelain
        
        if (-not $gitStatus) {
            Write-ColorOutput "ℹ️ No changes detected in the repository" "Yellow"
            return
        }
        
        # Stage all changes
        git add --all
        
        # Create commit message if not provided
        if (-not $CommitMessage) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $CommitMessage = "Auto-sync from D365: $SolutionName - $timestamp"
        }
        
        # Commit changes
        git commit -m $CommitMessage
        Write-ColorOutput "✅ Changes committed: $CommitMessage" "Green"
        
        # Push if requested
        if ($Push) {
            Write-ColorOutput "⬆️ Pushing to remote repository..." "Cyan"
            
            # Get current branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            
            # Push to origin
            git push origin $currentBranch
            Write-ColorOutput "✅ Changes pushed to origin/$currentBranch" "Green"
        } else {
            Write-ColorOutput "ℹ️ Skipping push (use -Push to enable)" "Yellow"
        }
        
    } catch {
        Write-ColorOutput "❌ Git operations failed: $_" "Red"
        exit 1
    }
}

function Get-SolutionInfo {
    param($EnvironmentUrl)
    
    Write-ColorOutput "ℹ️ Getting solution information..." "Cyan"
    
    try {
        # List solutions to verify our solution exists
        $solutions = pac solution list --environment $EnvironmentUrl
        Write-ColorOutput $solutions "Gray"
        
        # Get who-am-i info
        $whoAmI = pac org who --environment $EnvironmentUrl
        Write-ColorOutput "Current user: $whoAmI" "Gray"
        
    } catch {
        Write-ColorOutput "⚠️ Could not retrieve solution info: $_" "Yellow"
    }
}

function Show-Summary {
    param($SolutionName, $EnvironmentUrl, $CommitMessage)
    
    Write-ColorOutput "`n📋 Sync Summary" "Magenta"
    Write-ColorOutput "=" * 40 "Magenta"
    Write-ColorOutput "Solution: $SolutionName" "White"
    Write-ColorOutput "Environment: $EnvironmentUrl" "White"
    Write-ColorOutput "Commit: $CommitMessage" "White"
    Write-ColorOutput "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"
    Write-ColorOutput "=" * 40 "Magenta"
}

function Cleanup-TempFiles {
    Write-ColorOutput "🧹 Cleaning up temporary files..." "Cyan"
    
    try {
        if (Test-Path "./temp") {
            Remove-Item -Path "./temp" -Recurse -Force
            Write-ColorOutput "✅ Temporary files cleaned up" "Green"
        }
    } catch {
        Write-ColorOutput "⚠️ Could not clean up temp files: $_" "Yellow"
    }
}

# Main execution
try {
    Write-ColorOutput "`n🚀 Easy Spaces GitHub Sync Tool" "Magenta"
    Write-ColorOutput "=" * 50 "Magenta"
    Write-ColorOutput ""
    
    # Step 1: Check prerequisites
    Test-Prerequisites
    
    # Step 2: Get solution info
    Get-SolutionInfo -EnvironmentUrl $EnvironmentUrl
    
    # Step 3: Export solution from D365
    $solutionPath = Export-Solution -SolutionName $SolutionName -EnvironmentUrl $EnvironmentUrl
    
    # Step 4: Unpack solution for source control
    $solutionDir = Unpack-Solution -SolutionPath $solutionPath -SolutionName $SolutionName
    
    # Step 5: Update Git repository
    Update-GitRepository -CommitMessage $CommitMessage -Push $Push
    
    # Step 6: Show summary
    Show-Summary -SolutionName $SolutionName -EnvironmentUrl $EnvironmentUrl -CommitMessage $CommitMessage
    
    Write-ColorOutput "`n✅ Sync completed successfully!" "Green"
    
} catch {
    Write-ColorOutput "`n❌ Sync failed: $_" "Red"
    exit 1
} finally {
    # Always cleanup temp files
    Cleanup-TempFiles
}

Write-ColorOutput "`n📚 Next Steps:" "Cyan"
Write-ColorOutput "1. Review changes in your GitHub repository" "White"
Write-ColorOutput "2. Create pull request if working on feature branch" "White"
Write-ColorOutput "3. Deploy to other environments using GitHub Actions" "White"
Write-ColorOutput "4. Update documentation if needed" "White"