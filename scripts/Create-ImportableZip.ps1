# Create Importable Solution Package for Easy Spaces
# This creates a proper .zip file that can be imported into Dynamics 365

param(
    [string]$OutputPath = ".\EasySpaces_v1_0_0_0.zip"
)

# Create temporary directory structure
$tempDir = ".\temp_solution"
$solutionDir = "$tempDir\EasySpaces"

Write-Host "Creating importable Easy Spaces solution package..." -ForegroundColor Cyan

# Clean up any existing temp directory
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}

# Create directory structure
New-Item -ItemType Directory -Path $solutionDir -Force | Out-Null
New-Item -ItemType Directory -Path "$solutionDir\Entities" -Force | Out-Null
New-Item -ItemType Directory -Path "$solutionDir\WebResources" -Force | Out-Null
New-Item -ItemType Directory -Path "$solutionDir\Workflows" -Force | Out-Null

# Create solution.xml with proper structure
$solutionXml = @"
<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml version="9.2.24081.10375" SolutionPackageVersion="9.2" languagecode="1033">
  <SolutionManifest>
    <UniqueName>EasySpaces</UniqueName>
    <LocalizedNames>
      <LocalizedName description="Easy Spaces" languagecode="1033"/>
    </LocalizedNames>
    <Descriptions>
      <Description description="Event management solution converted from Salesforce LWC" languagecode="1033"/>
    </Descriptions>
    <Version>1.0.0.0</Version>
    <Managed>0</Managed>
    <Publisher>
      <UniqueName>EasySpacesPublisher</UniqueName>
      <LocalizedNames>
        <LocalizedName description="Easy Spaces Publisher" languagecode="1033"/>
      </LocalizedNames>
      <Descriptions>
        <Description description="Publisher for Easy Spaces solution" languagecode="1033"/>
      </Descriptions>
      <CustomizationPrefix>es</CustomizationPrefix>
      <CustomizationOptionValuePrefix>10000</CustomizationOptionValuePrefix>
    </Publisher>
    <RootComponents>
      <RootComponent type="1" schemaName="es_market"/>
      <RootComponent type="1" schemaName="es_space"/>
      <RootComponent type="1" schemaName="es_reservation"/>
    </RootComponents>
  </SolutionManifest>
</ImportExportXml>
"@

$solutionXml | Out-File -FilePath "$solutionDir\solution.xml" -Encoding UTF8

# Create [Content_Types].xml
$contentTypes = @"
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="xml" ContentType="application/xml"/>
</Types>
"@

$contentTypes | Out-File -FilePath "$solutionDir\[Content_Types].xml" -Encoding UTF8

# Copy and convert our entity definitions
$entities = @("Market", "Space", "Reservation")

foreach ($entity in $entities) {
    $entityFile = ".\solution\entities\$entity.xml"
    if (Test-Path $entityFile) {
        Copy-Item $entityFile "$solutionDir\Entities\$entity.xml"
        Write-Host "  Added $entity entity definition" -ForegroundColor Green
    }
}

# Create deployment instructions
$deployInstructions = @"
# Easy Spaces Solution Package

This package contains the converted Easy Spaces entities for Dynamics 365.

## Import Instructions:

### Method 1: Power Platform Admin Center
1. Go to: https://admin.powerplatform.microsoft.com/
2. Select your environment
3. Click "Solutions" 
4. Click "Import solution"
5. Upload: EasySpaces_v1_0_0_0.zip
6. Follow import wizard

### Method 2: Power Apps Portal
1. Go to: https://make.powerapps.com/
2. Click "Solutions" 
3. Click "Import solution"
4. Upload this zip file
5. Configure publisher if prompted

## After Import:
1. Verify entities are created: Markets, Spaces, Reservations
2. Import Canvas app: ../canvas-app/EasySpacesCanvas.json
3. Import flows: ../power-automate/*.json
4. Import sample data: ../data/sample-data.csv

## Package Contents:
- solution.xml (Solution manifest)
- Entities/Market.xml (Market entity definition)
- Entities/Space.xml (Space entity definition) 
- Entities/Reservation.xml (Reservation entity definition)
- [Content_Types].xml (Package metadata)

Generated: $(Get-Date)
Version: 1.0.0.0
"@

$deployInstructions | Out-File -FilePath "$solutionDir\IMPORT_INSTRUCTIONS.txt" -Encoding UTF8

# Create the ZIP file
Write-Host "Creating ZIP package..." -ForegroundColor Yellow

if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

# Use .NET compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($solutionDir, $OutputPath)

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host "`n✅ SUCCESS! Easy Spaces solution package created:" -ForegroundColor Green
Write-Host "   📦 File: $OutputPath" -ForegroundColor Cyan
Write-Host "   📁 Size: $((Get-Item $OutputPath).Length / 1KB) KB" -ForegroundColor Cyan
Write-Host "`nSUCCESS! Easy Spaces solution package created:" -ForegroundColor Green
Write-Host "   File: $OutputPath" -ForegroundColor Cyan
Write-Host "   Size: $([math]::Round((Get-Item $OutputPath).Length / 1KB,2)) KB" -ForegroundColor Cyan

Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Go to: https://admin.powerplatform.microsoft.com/" -ForegroundColor White
Write-Host "2. Select your environment" -ForegroundColor White
Write-Host "3. Click Solutions -> Import solution" -ForegroundColor White
Write-Host "4. Upload: $OutputPath" -ForegroundColor Cyan
Write-Host "5. After entity import, import Canvas app and flows separately" -ForegroundColor White

Write-Host "`nThis package contains the converted app entities." -ForegroundColor Green
Write-Host "Import completed artifacts then add canvas app, flows, and sample data." -ForegroundColor Green