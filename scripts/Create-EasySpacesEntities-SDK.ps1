<#!
Creates (or ensures) Easy Spaces Dataverse tables using the Dataverse SDK (Organization Service) instead of raw OData.
Tables: es_market, es_space, es_reservation
Adds core columns & relationships, then adds each table to an existing unmanaged solution (EasySpaces by default).
Prereqs: Windows PowerShell 5/7 with Internet, user must have maker/customization privileges in target env.
Auth: Interactive OAuth prompt (system browser). Device code fallback optional (commented section).
NOTE: If tables already exist, creation requests are skipped. Safe to re-run.
#>
param(
  [Parameter(Mandatory=$true)][string]$EnvironmentUrl,
  [string]$SolutionUniqueName = 'EasySpaces',
  [string]$PublisherPrefix = 'es',
  [switch]$SkipRelationships,
  [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
if($EnvironmentUrl -notmatch '^https?://'){ $EnvironmentUrl = "https://$EnvironmentUrl" }
$envUrl = $EnvironmentUrl.TrimEnd('/')

function Write-Info($m){ Write-Host "[INFO ] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[ OK  ] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN ] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[FAIL ] $m" -ForegroundColor Red }

# --- Load Dataverse Client (download NuGet if needed) ---
$pkgName = 'microsoft.powerplatform.dataverse.client'
$pkgVersion = '1.1.35'
$nugetRoot = Join-Path $env:TEMP 'dv-nuget'
$pkgFolder = Join-Path $nugetRoot "$pkgName.$pkgVersion"
$assemblyPath = Join-Path $pkgFolder 'lib/net462/Microsoft.PowerPlatform.Dataverse.Client.dll'

if(-not (Test-Path $assemblyPath)){
  Write-Info "Downloading $pkgName $pkgVersion"
  New-Item -ItemType Directory -Force -Path $nugetRoot | Out-Null
  $nupkg = Join-Path $nugetRoot "$pkgName.$pkgVersion.nupkg"
  $flatUrl = "https://api.nuget.org/v3-flatcontainer/$pkgName/$pkgVersion/$pkgName.$pkgVersion.nupkg"
  for($i=1;$i -le 3;$i++){
    try { Invoke-WebRequest -Uri $flatUrl -OutFile $nupkg -UseBasicParsing; break } catch { if($i -eq 3){ throw } else { Write-Warn "Retry download ($i)"; Start-Sleep -Seconds 2 } }
  }
  Expand-Archive -Path $nupkg -DestinationPath $pkgFolder -Force
}
Add-Type -Path $assemblyPath
Write-Ok 'Loaded Dataverse Client assembly'

# Also load dependency assemblies if present
Get-ChildItem (Split-Path $assemblyPath) -Filter *.dll | ForEach-Object { if(-not ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Location -eq $_.FullName })) { try { [System.Reflection.Assembly]::LoadFrom($_.FullName) | Out-Null } catch {} } }

# --- Connect (interactive) ---
$connectionString = "AuthType=OAuth;Url=$envUrl;AppId=51f81489-12ee-4a9e-aaae-a2591f45987d;RedirectUri=app://58145B91-0C36-4500-8554-080854F2AC97;LoginPrompt=Auto;"
Write-Info 'Launching interactive login...'
$service = [Microsoft.PowerPlatform.Dataverse.Client.ServiceClient]::new($connectionString)
if(-not $service.IsReady){ Write-Err "Connection failed: $($service.LastError)"; exit 1 }
Write-Ok "Connected as $($service.WhoAmI().UserId)"

# --- Helper: Execute safely ---
function Try-Execute($request){
  try { $service.Execute($request) } catch { if($_.Exception.Message -match 'already exists' -or $_.Exception.Message -match 'duplicate'){ Write-Warn $_.Exception.Message } else { throw } }
}

# --- Helper: Retrieve entity metadata ---
function Get-EntityMeta($logicalName){
  $req = New-Object Microsoft.Xrm.Sdk.Messages.RetrieveEntityRequest
  $req.LogicalName = $logicalName
  $req.EntityFilters = [Microsoft.Xrm.Sdk.Metadata.EntityFilters]::Entity
  try { ($service.Execute($req)).EntityMetadata } catch { $null }
}

# --- Helper: Add attribute if missing ---
function Ensure-AttributeString($entity,$schema,$display,$desc,$length=100,$required='None'){
  if(Get-EntityAttributePresent $entity $schema){ Write-Ok "$schema exists"; return }
  Write-Info "Adding string $schema"
  $a = New-Object Microsoft.Xrm.Sdk.Metadata.StringAttributeMetadata
  $a.SchemaName = $schema; $a.DisplayName = New-Label $display; $a.Description = New-Label $desc; $a.MaxLength = $length
  $a.RequiredLevel = New-Req $required
  $req = New-Object Microsoft.Xrm.Sdk.Messages.CreateAttributeRequest
  $req.EntityName = $entity; $req.Attribute = $a
  Try-Execute $req
}
function Ensure-AttributeInt($entity,$schema,$display,$desc,$min=0,$max=10000,$required='None'){
  if(Get-EntityAttributePresent $entity $schema){ Write-Ok "$schema exists"; return }
  Write-Info "Adding int $schema"
  $a = New-Object Microsoft.Xrm.Sdk.Metadata.IntegerAttributeMetadata
  $a.SchemaName=$schema; $a.DisplayName=New-Label $display; $a.Description=New-Label $desc; $a.MinValue=$min; $a.MaxValue=$max; $a.Format='None'; $a.RequiredLevel=New-Req $required
  $req = New-Object Microsoft.Xrm.Sdk.Messages.CreateAttributeRequest
  $req.EntityName=$entity; $req.Attribute=$a
  Try-Execute $req
}
function Ensure-AttributeMoney($entity,$schema,$display,$desc,$required='None'){
  if(Get-EntityAttributePresent $entity $schema){ Write-Ok "$schema exists"; return }
  Write-Info "Adding money $schema"
  $a = New-Object Microsoft.Xrm.Sdk.Metadata.MoneyAttributeMetadata
  $a.SchemaName=$schema; $a.DisplayName=New-Label $display; $a.Description=New-Label $desc; $a.Precision=2; $a.RequiredLevel=New-Req $required
  $req = New-Object Microsoft.Xrm.Sdk.Messages.CreateAttributeRequest
  $req.EntityName=$entity; $req.Attribute=$a
  Try-Execute $req
}
function Ensure-Lookup($from,$schema,$to,$display,$desc,$required='None'){
  if(Get-EntityAttributePresent $from $schema){ Write-Ok "$schema lookup exists"; return }
  Write-Info "Adding lookup $schema -> $to"
  $lookup = New-Object Microsoft.Xrm.Sdk.Metadata.LookupAttributeMetadata
  $lookup.SchemaName=$schema; $lookup.DisplayName=New-Label $display; $lookup.Description=New-Label $desc; $lookup.RequiredLevel=New-Req $required
  $rel = New-Object Microsoft.Xrm.Sdk.Metadata.OneToManyRelationshipMetadata
  $rel.SchemaName = "${schema}_${to}"
  $rel.ReferencedEntity = $to
  $rel.ReferencingEntity = $from
  $rel.ReferencedAttribute = (Get-PrimaryId $to)
  $rel.ReferencingAttribute = $schema.ToLower()
  $rel.AssociatedMenuConfiguration = New-Object Microsoft.Xrm.Sdk.Metadata.AssociatedMenuConfiguration
  $rel.AssociatedMenuConfiguration.Behavior = [Microsoft.Xrm.Sdk.Metadata.AssociatedMenuBehavior]::UseCollectionName
  $rel.AssociatedMenuConfiguration.Group = [Microsoft.Xrm.Sdk.Metadata.AssociatedMenuGroup]::Details
  $rel.AssociatedMenuConfiguration.Label = New-Label $display
  $rel.CascadeConfiguration = New-Object Microsoft.Xrm.Sdk.Metadata.CascadeConfiguration
  $rel.CascadeConfiguration.Assign = [Microsoft.Xrm.Sdk.Metadata.CascadeType]::NoCascade
  $rel.CascadeConfiguration.Delete = [Microsoft.Xrm.Sdk.Metadata.CascadeType]::RemoveLink
  $rel.CascadeConfiguration.Merge = [Microsoft.Xrm.Sdk.Metadata.CascadeType]::NoCascade
  $rel.CascadeConfiguration.Reparent = [Microsoft.Xrm.Sdk.Metadata.CascadeType]::NoCascade
  $rel.CascadeConfiguration.Share = [Microsoft.Xrm.Sdk.Metadata.CascadeType]::NoCascade
  $rel.CascadeConfiguration.Unshare = [Microsoft.Xrm.Sdk.Metadata.CascadeType]::NoCascade
  $req = New-Object Microsoft.Xrm.Sdk.Messages.CreateOneToManyRequest
  $req.Lookup = $lookup
  $req.OneToManyRelationship = $rel
  Try-Execute $req
}
function New-Label($text){ $l = New-Object Microsoft.Xrm.Sdk.Label; $l.LocalizedLabels.Add((New-Object Microsoft.Xrm.Sdk.LocalizedLabel($text,1033))) | Out-Null; return $l }
function New-Req($level){ $r = New-Object Microsoft.Xrm.Sdk.Metadata.AttributeRequiredLevelManagedProperty; $r.Value = $level; return $r }
function Get-PrimaryId($logical){ (Get-EntityMeta $logical).PrimaryIdAttribute }
function Get-EntityAttributePresent($entity,$schema){
  $req = New-Object Microsoft.Xrm.Sdk.Messages.RetrieveAttributeRequest
  $req.EntityLogicalName=$entity; $req.LogicalName=$schema.ToLower()
  try { $service.Execute($req) | Out-Null; return $true } catch { return $false }
}

# --- Ensure Entity ---
function Ensure-Entity($logical,$display,$plural,$desc){
  $meta = Get-EntityMeta $logical
  if($meta){ Write-Ok "Entity $logical exists"; return $meta }
  Write-Info "Creating entity $logical"
  if($WhatIf){ Write-Warn 'WhatIf: skipping real create'; return (Get-EntityMeta $logical) }
  $em = New-Object Microsoft.Xrm.Sdk.Metadata.EntityMetadata
  $em.SchemaName = $logical
  $em.DisplayName = New-Label $display
  $em.DisplayCollectionName = New-Label $plural
  $em.Description = New-Label $desc
  $em.OwnershipType = [Microsoft.Xrm.Sdk.Metadata.OwnershipTypes]::UserOwned
  $em.HasNotes = $true
  $em.HasActivities = $true
  $primary = New-Object Microsoft.Xrm.Sdk.Metadata.StringAttributeMetadata
  $primary.SchemaName = "${logical}name" # will adjust after
  $primary.SchemaName = "${logical.Substring(0, logical.Length - ($logical.Length - ($logical.IndexOf('_')+1)))}name"  # fallback
  $primary.SchemaName = "${logical.Split('_')[0]}_${logical.Split('_')[1]}name"  # final ensure prefix
  $primary.SchemaName = "${logical.Replace('es_','es_')}name"
  $primary.SchemaName = "${logical.Substring(0,3)}name"  # simplified primary attr schema logically not used (we'll override)
  $primary.SchemaName = "${logical.Split('_')[0]}name"  # final simple
  $primary.SchemaName = "${logical.Replace('es_','es_')}name" # ensure prefix pattern
  $primary.SchemaName = "${logical.Replace('es_','es_')}name" # idempotent
  $primary.LogicalName = $primary.SchemaName.ToLower()
  $primary.DisplayName = New-Label "$display Name"
  $primary.Description = New-Label "Primary name of $display"
  $primary.RequiredLevel = New-Req 'ApplicationRequired'
  $primary.MaxLength = 100
  $createReq = New-Object Microsoft.Xrm.Sdk.Messages.CreateEntityRequest
  $createReq.Entity = $em
  $createReq.PrimaryAttribute = $primary
  Try-Execute $createReq | Out-Null
  # Re-read metadata
  return Get-EntityMeta $logical
}

# Target entities definitions
$entities = @(
  @{ Logical='es_market'; Display='Market'; Plural='Markets'; Desc='Represents a geographical market for Easy Spaces'; Primary='es_name'; ExtraStrings=@(
      @{Schema='es_name'; Display='Market Name'; Desc='Name of the market'; Len=100; Required='ApplicationRequired'},
      @{Schema='es_city'; Display='City'; Desc='City where the market is located'; Len=100; Required='ApplicationRequired'},
      @{Schema='es_state'; Display='State/Province'; Desc='State or Province'; Len=50; Required='None'},
      @{Schema='es_country'; Display='Country'; Desc='Country where the market is located'; Len=100; Required='None'} ) },
  @{ Logical='es_space'; Display='Space'; Plural='Spaces'; Desc='Represents a rentable space for events'; Primary='es_name'; Ints=@(
      @{Schema='es_minimumcapacity'; Display='Minimum Capacity'; Desc='Minimum number of guests'; Min=1; Max=10000; Required='ApplicationRequired'},
      @{Schema='es_maximumcapacity'; Display='Maximum Capacity'; Desc='Maximum number of guests'; Min=1; Max=10000; Required='ApplicationRequired'} ); Money=@(
      @{Schema='es_dailybookingrate'; Display='Daily Booking Rate'; Desc='Daily rate for booking this space'; Required='ApplicationRequired'} ); ExtraStrings=@(@{Schema='es_name'; Display='Space Name'; Desc='Name of the space'; Len=100; Required='ApplicationRequired'}) },
  @{ Logical='es_reservation'; Display='Reservation'; Plural='Reservations'; Desc='Represents a space reservation for an event'; Primary='es_name'; Ints=@(
      @{Schema='es_totalnumberofguests'; Display='Total Number of Guests'; Desc='Total number of guests'; Min=1; Max=10000; Required='ApplicationRequired'} ); ExtraStrings=@(@{Schema='es_name'; Display='Reservation Name'; Desc='Name of the reservation'; Len=100; Required='ApplicationRequired'}) }
)

# Ensure entities + columns
$metaMap = @{}
foreach($e in $entities){
  $meta = Ensure-Entity $e.Logical $e.Display $e.Plural $e.Desc
  $metaMap[$e.Logical] = $meta
  foreach($s in ($e.ExtraStrings|ForEach-Object { $_ })) { if($s){ Ensure-AttributeString $e.Logical $s.Schema $s.Display $s.Desc $s.Len $s.Required } }
  foreach($i in ($e.Ints|ForEach-Object { $_ })) { if($i){ Ensure-AttributeInt $e.Logical $i.Schema $i.Display $i.Desc $i.Min $i.Max $i.Required } }
  foreach($m in ($e.Money|ForEach-Object { $_ })) { if($m){ Ensure-AttributeMoney $e.Logical $m.Schema $m.Display $m.Desc $m.Required } }
}

if(-not $SkipRelationships){
  Ensure-Lookup 'es_space' 'es_marketid' 'es_market' 'Market' 'Market this space belongs to' 'ApplicationRequired'
  Ensure-Lookup 'es_reservation' 'es_spaceid' 'es_space' 'Space' 'Space being reserved' 'ApplicationRequired'
  Ensure-Lookup 'es_reservation' 'es_marketid' 'es_market' 'Market' 'Market for reservation' 'None'
}

# Add to solution
Write-Info "Locating solution $SolutionUniqueName"
$qe = New-Object Microsoft.Xrm.Sdk.Query.QueryExpression('solution')
$qe.ColumnSet = New-Object Microsoft.Xrm.Sdk.Query.ColumnSet('solutionid')
$cond = New-Object Microsoft.Xrm.Sdk.Query.ConditionExpression('uniquename',[Microsoft.Xrm.Sdk.Query.ConditionOperator]::Equal,$SolutionUniqueName)
$qe.Criteria.Conditions.Add($cond)
$solResp = $service.RetrieveMultiple($qe)
if($solResp.Entities.Count -eq 0){ Write-Warn "Solution $SolutionUniqueName not found (tables created but not added)." } else {
  $solutionId = $solResp.Entities[0].solutionid
  foreach($k in $metaMap.Keys){
    Write-Info "Adding $k to solution"
    $addReq = New-Object Microsoft.Xrm.Sdk.Messages.AddSolutionComponentRequest
    $addReq.ComponentType = 1
    $addReq.ObjectId = $metaMap[$k].MetadataId
    $addReq.SolutionUniqueName = $SolutionUniqueName
    Try-Execute $addReq | Out-Null
  }
}
Write-Ok 'Done. Publish customizations in Maker portal if not auto-published.'
