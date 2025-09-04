# Easy Spaces Dynamics 365 - GitHub Integration Guide 2024

## Yes, it's absolutely possible to connect Dynamics 365 solutions to GitHub! 

Microsoft provides multiple ways to integrate Power Platform/Dynamics 365 with source control in 2024.

## 🎯 Available Integration Methods

### 1. **Native Git Integration (Preview)** - Azure DevOps Only
### 2. **GitHub Actions** - Full GitHub Support  
### 3. **Manual Source Control** - Traditional Approach
### 4. **Power Platform Pipelines** - Enterprise ALM

## Method 1: GitHub Actions Integration (Recommended for GitHub)

### Prerequisites
- GitHub repository
- Dynamics 365/Power Platform environment
- Service Principal for authentication
- Power Platform Build Tools

### Step 1: Set up GitHub Repository

```bash
# Clone or create your GitHub repository
git clone https://github.com/yourusername/easy-spaces-dynamics365.git
cd easy-spaces-dynamics365

# Copy your solution files
cp -r /path/to/easy-spaces-dynamics365/* .

# Initial commit
git add .
git commit -m "Initial Easy Spaces solution"
git push origin main
```

### Step 2: Create Service Principal

```powershell
# Install required modules
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell
Install-Module -Name Microsoft.PowerApps.PowerShell

# Create service principal
$app = New-AzureADApplication -DisplayName "EasySpaces-GitHub-Actions"
$sp = New-AzureADServicePrincipal -AppId $app.AppId
$secret = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId

# Save these values for GitHub secrets
Write-Host "Application ID: $($app.AppId)"
Write-Host "Client Secret: $($secret.Value)"
Write-Host "Tenant ID: $(Get-AzureADCurrentSessionInfo).TenantId"
```

### Step 3: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `POWERPLATFORM_APP_ID`: Your service principal app ID
- `POWERPLATFORM_CLIENT_SECRET`: Your client secret
- `POWERPLATFORM_TENANT_ID`: Your tenant ID
- `DEV_ENVIRONMENT_URL`: Your development environment URL
- `TEST_ENVIRONMENT_URL`: Your test environment URL
- `PROD_ENVIRONMENT_URL`: Your production environment URL

### Step 4: Create GitHub Actions Workflow

Create `.github/workflows/power-platform-ci-cd.yml`:

```yaml
name: Easy Spaces CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  SOLUTION_NAME: EasySpaces
  SOLUTION_SHIPPING_FOLDER: out/ship/
  SOLUTION_OUTBOUND_FOLDER: out/
  SOLUTION_SOURCE_FOLDER: solution/
  SOLUTION_RELEASE_FOLDER: out/release/

jobs:
  export-from-dev:
    runs-on: windows-latest
    if: github.event_name == 'workflow_dispatch' || (github.event_name == 'push' && github.ref == 'refs/heads/main')
    
    steps:
    - uses: actions/checkout@v3
      with:
        lfs: true

    - name: Power Platform Tool Installer
      uses: microsoft/powerplatform-actions/actions-install@v1.0.0

    - name: Export solution
      uses: microsoft/powerplatform-actions/export-solution@v1.0.0
      with:
        environment-url: ${{ secrets.DEV_ENVIRONMENT_URL }}
        app-id: ${{ secrets.POWERPLATFORM_APP_ID }}
        client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
        tenant-id: ${{ secrets.POWERPLATFORM_TENANT_ID }}
        solution-name: ${{ env.SOLUTION_NAME }}
        solution-output-file: ${{ env.SOLUTION_OUTBOUND_FOLDER }}/${{ env.SOLUTION_NAME }}.zip

    - name: Unpack solution
      uses: microsoft/powerplatform-actions/unpack-solution@v1.0.0
      with:
        solution-file: ${{ env.SOLUTION_OUTBOUND_FOLDER }}/${{ env.SOLUTION_NAME }}.zip
        solution-folder: ${{ env.SOLUTION_SOURCE_FOLDER }}/${{ env.SOLUTION_NAME }}
        solution-type: 'Unmanaged'
        overwrite-files: true

    - name: Branch solution
      uses: microsoft/powerplatform-actions/branch-solution@v1.0.0
      with:
        solution-folder: ${{ env.SOLUTION_SOURCE_FOLDER }}/${{ env.SOLUTION_NAME }}
        solution-target-folder: ${{ env.SOLUTION_SOURCE_FOLDER }}/${{ env.SOLUTION_NAME }}_managed
        repo-token: ${{ secrets.GITHUB_TOKEN }}

    - name: Commit changes
      run: |
        git config user.name "GitHub Actions Bot"
        git config user.email "actions@github.com"
        git add .
        git commit -m "Automated solution export from dev environment" || exit 0
        git push

  build-solution:
    runs-on: windows-latest
    needs: [export-from-dev]
    if: always() && (needs.export-from-dev.result == 'success' || needs.export-from-dev.result == 'skipped')

    steps:
    - uses: actions/checkout@v3

    - name: Power Platform Tool Installer
      uses: microsoft/powerplatform-actions/actions-install@v1.0.0

    - name: Pack solution
      uses: microsoft/powerplatform-actions/pack-solution@v1.0.0
      with:
        solution-folder: ${{ env.SOLUTION_SOURCE_FOLDER }}/${{ env.SOLUTION_NAME }}
        solution-file: ${{ env.SOLUTION_OUTBOUND_FOLDER }}/${{ env.SOLUTION_NAME }}.zip
        solution-type: Unmanaged

    - name: Pack managed solution
      uses: microsoft/powerplatform-actions/pack-solution@v1.0.0
      with:
        solution-folder: ${{ env.SOLUTION_SOURCE_FOLDER }}/${{ env.SOLUTION_NAME }}_managed
        solution-file: ${{ env.SOLUTION_RELEASE_FOLDER }}/${{ env.SOLUTION_NAME }}_managed.zip
        solution-type: Managed

    - name: Solution Checker
      uses: microsoft/powerplatform-actions/check-solution@v1.0.0
      with:
        environment-url: ${{ secrets.DEV_ENVIRONMENT_URL }}
        app-id: ${{ secrets.POWERPLATFORM_APP_ID }}
        client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
        tenant-id: ${{ secrets.POWERPLATFORM_TENANT_ID }}
        path: ${{ env.SOLUTION_OUTBOUND_FOLDER }}/${{ env.SOLUTION_NAME }}.zip

    - name: Upload solution artifacts
      uses: actions/upload-artifact@v3
      with:
        name: solution-artifacts
        path: |
          ${{ env.SOLUTION_OUTBOUND_FOLDER }}/${{ env.SOLUTION_NAME }}.zip
          ${{ env.SOLUTION_RELEASE_FOLDER }}/${{ env.SOLUTION_NAME }}_managed.zip

  deploy-to-test:
    runs-on: windows-latest
    needs: [build-solution]
    if: github.ref == 'refs/heads/main'
    environment: test

    steps:
    - uses: actions/checkout@v3

    - name: Download solution artifacts
      uses: actions/download-artifact@v3
      with:
        name: solution-artifacts
        path: ${{ env.SOLUTION_RELEASE_FOLDER }}

    - name: Power Platform Tool Installer
      uses: microsoft/powerplatform-actions/actions-install@v1.0.0

    - name: Import solution to test
      uses: microsoft/powerplatform-actions/import-solution@v1.0.0
      with:
        environment-url: ${{ secrets.TEST_ENVIRONMENT_URL }}
        app-id: ${{ secrets.POWERPLATFORM_APP_ID }}
        client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
        tenant-id: ${{ secrets.POWERPLATFORM_TENANT_ID }}
        solution-file: ${{ env.SOLUTION_RELEASE_FOLDER }}/${{ env.SOLUTION_NAME }}_managed.zip

  deploy-pcf-controls:
    runs-on: windows-latest
    needs: [deploy-to-test]
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Power Platform Tool Installer
      uses: microsoft/powerplatform-actions/actions-install@v1.0.0

    - name: Build and Deploy PCF Controls
      run: |
        # Deploy ReservationHelper PCF Control
        cd pcf-controls/ReservationHelper
        npm install
        npm run build
        pac auth create --environment ${{ secrets.TEST_ENVIRONMENT_URL }} --applicationId ${{ secrets.POWERPLATFORM_APP_ID }} --clientSecret ${{ secrets.POWERPLATFORM_CLIENT_SECRET }} --tenant ${{ secrets.POWERPLATFORM_TENANT_ID }}
        pac pcf push --publisher-prefix es

  deploy-to-production:
    runs-on: windows-latest
    needs: [deploy-to-test, deploy-pcf-controls]
    if: github.ref == 'refs/heads/main'
    environment: production

    steps:
    - uses: actions/checkout@v3

    - name: Download solution artifacts
      uses: actions/download-artifact@v3
      with:
        name: solution-artifacts
        path: ${{ env.SOLUTION_RELEASE_FOLDER }}

    - name: Power Platform Tool Installer
      uses: microsoft/powerplatform-actions/actions-install@v1.0.0

    - name: Import solution to production
      uses: microsoft/powerplatform-actions/import-solution@v1.0.0
      with:
        environment-url: ${{ secrets.PROD_ENVIRONMENT_URL }}
        app-id: ${{ secrets.POWERPLATFORM_APP_ID }}
        client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
        tenant-id: ${{ secrets.POWERPLATFORM_TENANT_ID }}
        solution-file: ${{ env.SOLUTION_RELEASE_FOLDER }}/${{ env.SOLUTION_NAME }}_managed.zip
        force-overwrite: true
```

## Method 2: Native Git Integration (Azure DevOps)

If you want to use native Git integration, you'll need to use Azure DevOps:

### Step 1: Create Azure DevOps Repository

1. Go to [Azure DevOps](https://dev.azure.com)
2. Create new project with Git version control
3. Initialize repository

### Step 2: Connect from Power Platform

1. Go to [Power Apps](https://make.powerapps.com)
2. Navigate to Solutions
3. Click "Connect to Git"
4. Choose "Solution" binding type
5. Select your Azure DevOps organization and project
6. Select your solution

### Step 3: Sync Changes

```powershell
# Push changes from Power Platform to Git
# This happens automatically when you commit in the Power Apps interface

# Pull changes from Git to Power Platform  
# Use the "Sync" button in Power Apps Solutions area
```

## Method 3: Manual Source Control Setup

### Step 1: Export Solutions Regularly

```powershell
# Export solution using PAC CLI
pac solution export --name "EasySpaces" --path "./solution/EasySpaces.zip"

# Unpack for source control
pac solution unpack --zipfile "./solution/EasySpaces.zip" --folder "./solution/EasySpaces" --packagetype "Unmanaged"

# Commit to GitHub
git add .
git commit -m "Solution update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push origin main
```

### Step 2: Create Automation Script

Create `scripts/sync-to-github.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl,
    [string]$SolutionName = "EasySpaces"
)

# Export and unpack solution
Write-Host "Exporting solution..." -ForegroundColor Green
pac solution export --name $SolutionName --path "./temp/$SolutionName.zip" --environment $EnvironmentUrl

Write-Host "Unpacking solution..." -ForegroundColor Green
pac solution unpack --zipfile "./temp/$SolutionName.zip" --folder "./solution/$SolutionName" --packagetype "Unmanaged" --allowWrite

# Commit changes
Write-Host "Committing to GitHub..." -ForegroundColor Green
git add .
$commitMessage = "Auto-sync from D365: $SolutionName - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMessage
git push origin main

Write-Host "Sync completed!" -ForegroundColor Green
```

## Method 4: Power Platform Pipelines + GitHub

### Step 1: Set up Power Platform Pipelines

1. Install Power Platform Pipelines app in your environment
2. Configure deployment stages (Dev → Test → Prod)
3. Set up approvals and gates

### Step 2: Integrate with GitHub

```yaml
# .github/workflows/pp-pipeline-trigger.yml
name: Trigger Power Platform Pipeline

on:
  push:
    branches: [ main ]

jobs:
  trigger-pipeline:
    runs-on: ubuntu-latest
    steps:
    - name: Trigger Power Platform Pipeline
      run: |
        # Use Power Platform API to trigger pipeline
        curl -X POST "https://api.powerplatform.com/pipelines/trigger" \
          -H "Authorization: Bearer ${{ secrets.PP_ACCESS_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d '{"pipelineId": "${{ secrets.PIPELINE_ID }}"}'
```

## Repository Structure

Your GitHub repository should follow this structure:

```
easy-spaces-dynamics365/
├── .github/
│   └── workflows/
│       └── power-platform-ci-cd.yml
├── solution/
│   └── EasySpaces/
│       ├── Entities/
│       ├── OptionSets/
│       └── Other/
├── pcf-controls/
│   ├── ReservationHelper/
│   ├── CustomerDetails/
│   └── SpaceGallery/
├── plugins/
│   └── ReservationManager/
├── power-automate/
│   ├── CreateReservationFlow.json
│   └── SpaceDesignerFlow.json
├── scripts/
│   ├── deploy-enhanced-2024.ps1
│   └── sync-to-github.ps1
└── docs/
    ├── DEPLOYMENT_GUIDE_2024.md
    └── GITHUB_INTEGRATION_GUIDE.md
```

## Benefits of GitHub Integration

### ✅ Version Control
- Track all changes to your Dynamics 365 solution
- Compare versions and see what changed
- Rollback to previous versions if needed

### ✅ Collaboration  
- Multiple developers can work on the same solution
- Pull requests for code reviews
- Merge conflicts resolution

### ✅ Automated Deployment
- CI/CD pipelines for automatic deployment
- Automated testing and validation
- Environment promotion (Dev → Test → Prod)

### ✅ Backup and Recovery
- Complete solution history in Git
- Disaster recovery capabilities
- Cross-platform accessibility

## Best Practices

### 1. Branching Strategy
```bash
# Feature branch workflow
git checkout -b feature/reservation-enhancements
# Make changes
git commit -m "Add reservation validation logic"
git push origin feature/reservation-enhancements
# Create pull request
```

### 2. Commit Messages
Use descriptive commit messages:
```bash
git commit -m "feat: Add customer detail PCF control"
git commit -m "fix: Resolve plugin validation issue"  
git commit -m "docs: Update deployment guide"
```

### 3. Solution Segmentation
- Keep logical solutions separate
- Use solution dependencies properly
- Maintain clean solution architecture

### 4. Secrets Management
- Never commit credentials to Git
- Use GitHub secrets for sensitive data
- Rotate service principal credentials regularly

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify service principal permissions
   - Check secret expiration dates
   - Ensure proper environment URLs

2. **Solution Import Errors**
   - Check solution dependencies
   - Verify environment compatibility
   - Review solution checker results

3. **PCF Control Deployment Issues**
   - Verify Node.js version compatibility
   - Check package dependencies
   - Ensure proper build configuration

## Conclusion

GitHub integration with Dynamics 365 is not only possible but recommended for professional development. Choose the method that best fits your organization:

- **GitHub Actions**: Full GitHub experience with automated CI/CD
- **Native Git Integration**: Seamless experience with Azure DevOps  
- **Manual Process**: Simple export/import with version control
- **Power Platform Pipelines**: Enterprise-grade ALM with approvals

The GitHub Actions approach provides the most comprehensive integration with GitHub while maintaining all the benefits of modern DevOps practices.