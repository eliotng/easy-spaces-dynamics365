<#!
Creates Easy Spaces Dataverse tables (es_market, es_space, es_reservation) + core columns and adds them to an unmanaged solution (EasySpaces) using the Dataverse Web API.
Authentication: OAuth 2.0 device code flow against common tenant using public client id (first‑party) 51f81489-12ee-4a9e-aaae-a2591f45987d.
Scope: https://<env>/.default (delegated). User must have Maker privileges to create tables & solution.
Limitations: Minimal set of columns (core text / number / money / lookup). Picklists & extra columns can be added later. Relationships are created via lookup attributes.
After run: Publish customizations manually or let the script publish at the end.
#>
param(
  [Parameter(Mandatory=$true)][string]$EnvironmentUrl,
  [switch]$Force,
  [switch]$SkipSolution,
  [string]$SolutionUniqueName = 'EasySpaces',
  [string]$SolutionFriendlyName = 'Easy Spaces',
  [string]$PublisherUniqueName = 'easyspaces',
  [string]$PublisherFriendlyName = 'Easy Spaces',
  [string]$CustomizationPrefix = 'es'
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "[INFO ] $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Host "[WARN ] $msg" -ForegroundColor Yellow }
function Write-Ok($msg){ Write-Host "[ OK  ] $msg" -ForegroundColor Green }
function Write-Err($msg){ Write-Host "[FAIL ] $msg" -ForegroundColor Red }

if($EnvironmentUrl -notmatch '^https?://'){ $EnvironmentUrl = "https://$EnvironmentUrl" }
$envBase = $EnvironmentUrl.TrimEnd('/')
$apiBase = "$envBase/api/data/v9.2"

# ------------------- OAuth Device Code Flow -------------------
$clientId = '51f81489-12ee-4a9e-aaae-a2591f45987d'
$deviceCodeEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/devicecode'
$tokenEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
$scope = "$envBase/.default offline_access openid profile"

function Get-AccessToken {
  Write-Info 'Requesting device code...'
  $dcResp = Invoke-RestMethod -Method Post -Uri $deviceCodeEndpoint -Body @{ client_id=$clientId; scope=$scope }
  Write-Host "\n==== DEVICE LOGIN ====" -ForegroundColor Magenta
  Write-Host "Go to: $($dcResp.verification_uri)" -ForegroundColor White
  Write-Host "Enter code: $($dcResp.user_code)" -ForegroundColor Yellow
  Write-Host "(This window will poll until you complete sign-in or it times out)" -ForegroundColor DarkGray
  $interval = [int]$dcResp.interval
  while($true){
    Start-Sleep -Seconds $interval
    try {
      $tok = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body @{
        grant_type='urn:ietf:params:oauth:grant-type:device_code'
        client_id=$clientId
        device_code=$($dcResp.device_code)
      }
      if($tok.access_token){
        Write-Ok 'Authentication successful.'
        return $tok.access_token
      }
    } catch {
      $err = $_.ErrorDetails.Message
      if($err -and $err -match 'authorization_pending'){ continue }
      if($err -and $err -match 'slow_down'){ $interval += 2; continue }
      throw $_
    }
  }
}

$global:AccessToken = Get-AccessToken
$authHeader = @{ Authorization = "Bearer $AccessToken"; 'Content-Type'='application/json' }

function Invoke-DVGet($relative){ Invoke-RestMethod -Method Get -Headers $authHeader -Uri ($apiBase + $relative) }
function Invoke-DVPost($relative,$body){ Invoke-RestMethod -Method Post -Headers $authHeader -Uri ($apiBase + $relative) -Body ($body | ConvertTo-Json -Depth 15) }
function Invoke-DVPatch($relative,$body){ Invoke-RestMethod -Method Patch -Headers $authHeader -Uri ($apiBase + $relative) -Body ($body | ConvertTo-Json -Depth 15) }

# ------------------- Publisher -------------------
Write-Info "Ensuring publisher '$PublisherUniqueName'"
$filterPublisher = [System.Web.HttpUtility]::UrlEncode("uniquename eq '$PublisherUniqueName'")
$pub = Invoke-DVGet("/publishers?%24select=publisherid&%24filter=$filterPublisher")
if($pub.value.Count -eq 0){
  Write-Info 'Creating publisher'
  $pubBody = @{ uniquename=$PublisherUniqueName; friendlyname=$PublisherFriendlyName; customizationprefix=$CustomizationPrefix; customizationoptionvalueprefix=10000; description='Easy Spaces Publisher'}
  $pubResp = Invoke-DVPost('/publishers',$pubBody)
  # Location header has the entity URI
  $pubId = ($pubResp.'@odata.id' -split '[()]')[-2]
  Write-Ok "Publisher created: $pubId"
}else{
  $pubId = $pub.value[0].publisherid
  Write-Ok "Publisher exists: $pubId"
}

# ------------------- Solution -------------------
if(-not $SkipSolution){
  Write-Info "Ensuring solution '$SolutionUniqueName'"
  $filterSolution = [System.Web.HttpUtility]::UrlEncode("uniquename eq '$SolutionUniqueName'")
  $sol = Invoke-DVGet("/solutions?%24select=solutionid&%24filter=$filterSolution")
  if($sol.value.Count -eq 0){
    Write-Info 'Creating solution'
    $solBody = @{ uniquename=$SolutionUniqueName; friendlyname=$SolutionFriendlyName; version='1.0.0.0'; description='Easy Spaces core solution'; 'publisherid@odata.bind'="/publishers($pubId)" }
    $solResp = Invoke-DVPost('/solutions',$solBody)
    $solutionId = ($solResp.'@odata.id' -split '[()]')[-2]
    Write-Ok "Solution created: $solutionId"
  }else{ $solutionId = $sol.value[0].solutionid; Write-Ok "Solution exists: $solutionId" }
}else{ Write-Warn 'Skipping solution creation per flag'; }

# ------------------- Table Definitions -------------------
$tables = @(
  @{ Schema='es_market'; Singular='Market'; Plural='Markets'; Desc='Represents a geographical market for Easy Spaces'; PrimaryDisplay='Market Name'; PrimaryDesc='The name of the market'; Primary='es_name'; PrimaryLen=100; ExtraStrings=@(
      @{Schema='es_city'; Name='City'; Desc='City where the market is located'; Len=100; Required='ApplicationRequired'},
      @{Schema='es_state'; Name='State/Province'; Desc='State or Province'; Len=50; Required='None'},
      @{Schema='es_country'; Name='Country'; Desc='Country where the market is located'; Len=100; Required='None'} ) },
  @{ Schema='es_space'; Singular='Space'; Plural='Spaces'; Desc='Represents a rentable space for events'; PrimaryDisplay='Space Name'; PrimaryDesc='The name of the space'; Primary='es_name'; PrimaryLen=100; ExtraStrings=@(); Ints=@(
      @{Schema='es_minimumcapacity'; Name='Minimum Capacity'; Desc='Minimum number of guests'; Min=1; Max=10000; Required='ApplicationRequired'},
      @{Schema='es_maximumcapacity'; Name='Maximum Capacity'; Desc='Maximum number of guests'; Min=1; Max=10000; Required='ApplicationRequired'} ); Money=@(
      @{Schema='es_dailybookingrate'; Name='Daily Booking Rate'; Desc='Daily rate for booking this space'; Min=0; Max=1000000} ) },
  @{ Schema='es_reservation'; Singular='Reservation'; Plural='Reservations'; Desc='Represents a space reservation for an event'; PrimaryDisplay='Reservation Name'; PrimaryDesc='The name/title of the reservation'; Primary='es_name'; PrimaryLen=100; ExtraStrings=@(); Ints=@(
      @{Schema='es_totalnumberofguests'; Name='Total Number of Guests'; Desc='Total number of guests'; Min=1; Max=10000; Required='ApplicationRequired'} ) }
)

function Ensure-Table($t){
  $schema = $t.Schema
  Write-Info "Processing table $schema"
  $filterEnt = [System.Web.HttpUtility]::UrlEncode("LogicalName eq '$schema'")
  $exists = Invoke-DVGet("/EntityDefinitions?%24select=MetadataId&%24filter=$filterEnt")
  if($exists.value.Count -eq 0){
    Write-Info 'Creating entity metadata'
    $body = @{ 
      '@odata.type'='Microsoft.Dynamics.CRM.EntityMetadata'
      SchemaName=$schema
      DisplayName=@{ LocalizedLabels=@(@{ Label=$t.Singular; LanguageCode=1033 }) }
      DisplayCollectionName=@{ LocalizedLabels=@(@{ Label=$t.Plural; LanguageCode=1033 }) }
      Description=@{ LocalizedLabels=@(@{ Label=$t.Desc; LanguageCode=1033 }) }
      OwnershipType='UserOwned'
      HasActivities=$true
      HasNotes=$true
      PrimaryAttribute=@{ '@odata.type'='Microsoft.Dynamics.CRM.StringAttributeMetadata'; SchemaName=$t.Primary; RequiredLevel=@{ Value='ApplicationRequired'}; MaxLength=$t.PrimaryLen; DisplayName=@{ LocalizedLabels=@(@{ Label=$t.PrimaryDisplay; LanguageCode=1033 }) }; Description=@{ LocalizedLabels=@(@{ Label=$t.PrimaryDesc; LanguageCode=1033 }) }; FormatName=@{ Value='Text' } }
    }
    $resp = Invoke-DVPost('/EntityDefinitions',$body)
    $metaId = ($resp.'@odata.id' -split '[()]')[-2]
    Write-Ok "Created $schema ($metaId)"
  } else {
    $metaId = $exists.value[0].MetadataId
    Write-Ok "Table exists ($metaId)"
  }
  return $metaId
}

function Add-StringAttribute($logical,$schema,$a){
  Write-Info "  String: $($a.Schema)"
  $body = @{ '@odata.type'='Microsoft.Dynamics.CRM.StringAttributeMetadata'; SchemaName=$a.Schema; RequiredLevel=@{ Value=$a.Required }; MaxLength=$a.Len; DisplayName=@{ LocalizedLabels=@(@{ Label=$a.Name; LanguageCode=1033 }) }; Description=@{ LocalizedLabels=@(@{ Label=$a.Desc; LanguageCode=1033 }) } }
  Invoke-DVPost("/EntityDefinitions(LogicalName='$logical')/Attributes",$body) | Out-Null
}
function Add-IntAttribute($logical,$schema,$a){
  Write-Info "  Integer: $($a.Schema)"
  $body = @{ '@odata.type'='Microsoft.Dynamics.CRM.IntegerAttributeMetadata'; SchemaName=$a.Schema; RequiredLevel=@{ Value=$a.Required }; MinValue=$a.Min; MaxValue=$a.Max; Format='None'; DisplayName=@{ LocalizedLabels=@(@{ Label=$a.Name; LanguageCode=1033 }) }; Description=@{ LocalizedLabels=@(@{ Label=$a.Desc; LanguageCode=1033 }) } }
  Invoke-DVPost("/EntityDefinitions(LogicalName='$logical')/Attributes",$body) | Out-Null
}
function Add-MoneyAttribute($logical,$schema,$a){
  Write-Info "  Money: $($a.Schema)"
  $body = @{ '@odata.type'='Microsoft.Dynamics.CRM.MoneyAttributeMetadata'; SchemaName=$a.Schema; RequiredLevel=@{ Value='ApplicationRequired'}; MinValue=$a.Min; MaxValue=$a.Max; PrecisionSource=2; Precision=2; DisplayName=@{ LocalizedLabels=@(@{ Label=$a.Name; LanguageCode=1033 }) }; Description=@{ LocalizedLabels=@(@{ Label=$a.Desc; LanguageCode=1033 }) } }
  Invoke-DVPost("/EntityDefinitions(LogicalName='$logical')/Attributes",$body) | Out-Null
}
function Add-Lookup($from,$schemaName,$target,$display,$desc,$required='ApplicationRequired'){
  Write-Info "  Lookup: $schemaName -> $target"
  $body = @{ '@odata.type'='Microsoft.Dynamics.CRM.LookupAttributeMetadata'; SchemaName=$schemaName; DisplayName=@{ LocalizedLabels=@(@{ Label=$display; LanguageCode=1033 }) }; Description=@{ LocalizedLabels=@(@{ Label=$desc; LanguageCode=1033 }) }; Targets=@($target); RequiredLevel=@{ Value=$required } }
  Invoke-DVPost("/EntityDefinitions(LogicalName='$from')/Attributes",$body) | Out-Null
}

$entityIds = @{}
foreach($t in $tables){
  $id = Ensure-Table $t
  $entityIds[$t.Schema] = $id
  # Add attributes if they don't exist (naive attempt; ignores duplicates errors)
  if($t.ExtraStrings){ foreach($s in $t.ExtraStrings){ try { Add-StringAttribute $t.Schema $id $s } catch { Write-Warn "    Skip (exists?): $($s.Schema)" } } }
  if($t.Ints){ foreach($i in $t.Ints){ try { Add-IntAttribute $t.Schema $id $i } catch { Write-Warn "    Skip (exists?): $($i.Schema)" } } }
  if($t.Money){ foreach($m in $t.Money){ try { Add-MoneyAttribute $t.Schema $id $m } catch { Write-Warn "    Skip (exists?): $($m.Schema)" } } }
}

# Lookups & relationships
try { Add-Lookup 'es_space' 'es_marketid' 'es_market' 'Market' 'The market this space belongs to' } catch { Write-Warn 'Lookup es_marketid on es_space might already exist.' }
try { Add-Lookup 'es_reservation' 'es_spaceid' 'es_space' 'Space' 'The space being reserved' } catch { Write-Warn 'Lookup es_spaceid on es_reservation might already exist.' }
try { Add-Lookup 'es_reservation' 'es_marketid' 'es_market' 'Market' 'The market for this reservation' 'None' } catch { Write-Warn 'Lookup es_marketid on es_reservation might already exist.' }

# Add entities to solution (always attempt; safe if already present)
foreach($kv in $entityIds.GetEnumerator()){
  $logical = $kv.Key; $metaId = $kv.Value
  Write-Info "Adding $logical to solution $SolutionUniqueName"
  $body = @{ ComponentType = 1; ObjectId = $metaId; SolutionUniqueName = $SolutionUniqueName }
  try { Invoke-DVPost('/AddSolutionComponent', $body) | Out-Null; Write-Ok "Added $logical" } catch { Write-Warn "  Already added? $logical" }
}

# Publish customizations
Write-Info 'Publishing customizations'
try { Invoke-DVPost('/PublishXml', @{ ParameterXml = '<importexportxml><entities><entity>es_market</entity><entity>es_space</entity><entity>es_reservation</entity></entities></importexportxml>' }) | Out-Null; Write-Ok 'Publish submitted' } catch { Write-Warn 'Publish call failed (may need manual publish).' }

Write-Host "\nCompleted. Verify tables in Maker portal, then you can export solution and replace local metadata." -ForegroundColor Green
