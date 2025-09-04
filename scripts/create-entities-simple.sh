#!/bin/bash

# Simple CLI approach to create Easy Spaces entities
ENV_URL="https://org7cfbe420.crm.dynamics.com"

echo "🚀 Creating Easy Spaces Entities via CLI"
echo "Environment: $ENV_URL"

# Check PAC CLI connection
echo ""
echo "🔐 Checking authentication..."
pac org who || exit 1

echo ""
echo "🏢 Creating Market entity..."

# First, let me create the entities in the Default solution, then move them
# Use PowerShell with Dataverse API to create tables

pwsh -Command "
Write-Host 'Creating Market table...'
try {
    # Get access token from PAC CLI
    \$orgInfo = pac org who --json | ConvertFrom-Json -ErrorAction Stop
    \$accessToken = \$orgInfo.AccessToken
    
    if (!\$accessToken) {
        Write-Host 'No access token available' -ForegroundColor Red
        exit 1
    }
    
    \$headers = @{
        'Authorization' = \"Bearer \$accessToken\"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version' = '4.0'
    }
    
    # Create Market Entity
    \$marketEntity = @{
        'SchemaName' = 'es_market'
        'DisplayName' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Market'
                'LanguageCode' = 1033
            })
        }
        'DisplayCollectionName' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Markets'
                'LanguageCode' = 1033
            })
        }
        'Description' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Represents a geographical market for Easy Spaces'
                'LanguageCode' = 1033
            })
        }
        'OwnershipType' = 'UserOwned'
        'IsActivity' = \$false
        'HasNotes' = \$true
        'HasActivities' = \$true
    } | ConvertTo-Json -Depth 10
    
    \$response = Invoke-RestMethod -Uri '${ENV_URL}/api/data/v9.2/EntityDefinitions' -Method POST -Headers \$headers -Body \$marketEntity
    Write-Host '✅ Market entity created successfully' -ForegroundColor Green
    
} catch {
    Write-Host \"❌ Failed to create Market entity: \$(\$_.Exception.Message)\" -ForegroundColor Red
    if (\$_.Exception.Response.StatusCode -eq 'Conflict') {
        Write-Host '   Entity may already exist' -ForegroundColor Yellow
    }
}
"

echo ""
echo "🏗️ Creating Space entity..."

pwsh -Command "
Write-Host 'Creating Space table...'
try {
    \$orgInfo = pac org who --json | ConvertFrom-Json -ErrorAction Stop
    \$accessToken = \$orgInfo.AccessToken
    
    \$headers = @{
        'Authorization' = \"Bearer \$accessToken\"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version' = '4.0'
    }
    
    # Create Space Entity
    \$spaceEntity = @{
        'SchemaName' = 'es_space'
        'DisplayName' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Space'
                'LanguageCode' = 1033
            })
        }
        'DisplayCollectionName' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Spaces'
                'LanguageCode' = 1033
            })
        }
        'Description' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Event spaces available for booking'
                'LanguageCode' = 1033
            })
        }
        'OwnershipType' = 'UserOwned'
        'IsActivity' = \$false
        'HasNotes' = \$true
        'HasActivities' = \$true
    } | ConvertTo-Json -Depth 10
    
    \$response = Invoke-RestMethod -Uri '${ENV_URL}/api/data/v9.2/EntityDefinitions' -Method POST -Headers \$headers -Body \$spaceEntity
    Write-Host '✅ Space entity created successfully' -ForegroundColor Green
    
} catch {
    Write-Host \"❌ Failed to create Space entity: \$(\$_.Exception.Message)\" -ForegroundColor Red
    if (\$_.Exception.Response.StatusCode -eq 'Conflict') {
        Write-Host '   Entity may already exist' -ForegroundColor Yellow
    }
}
"

echo ""
echo "📅 Creating Reservation entity..."

pwsh -Command "
Write-Host 'Creating Reservation table...'
try {
    \$orgInfo = pac org who --json | ConvertFrom-Json -ErrorAction Stop
    \$accessToken = \$orgInfo.AccessToken
    
    \$headers = @{
        'Authorization' = \"Bearer \$accessToken\"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version' = '4.0'
    }
    
    # Create Reservation Entity
    \$reservationEntity = @{
        'SchemaName' = 'es_reservation'
        'DisplayName' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Reservation'
                'LanguageCode' = 1033
            })
        }
        'DisplayCollectionName' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Reservations'
                'LanguageCode' = 1033
            })
        }
        'Description' = @{
            'LocalizedLabels' = @(@{
                'Label' = 'Space reservations and bookings'
                'LanguageCode' = 1033
            })
        }
        'OwnershipType' = 'UserOwned'
        'IsActivity' = \$false
        'HasNotes' = \$true
        'HasActivities' = \$true
        'IsValidForQueue' = \$true
    } | ConvertTo-Json -Depth 10
    
    \$response = Invoke-RestMethod -Uri '${ENV_URL}/api/data/v9.2/EntityDefinitions' -Method POST -Headers \$headers -Body \$reservationEntity
    Write-Host '✅ Reservation entity created successfully' -ForegroundColor Green
    
} catch {
    Write-Host \"❌ Failed to create Reservation entity: \$(\$_.Exception.Message)\" -ForegroundColor Red
    if (\$_.Exception.Response.StatusCode -eq 'Conflict') {
        Write-Host '   Entity may already exist' -ForegroundColor Yellow
    }
}
"

echo ""
echo "🎉 Entity creation process complete!"
echo ""
echo "🔍 Checking created entities..."

# Wait a bit for entities to be processed
sleep 5

# Check if entities exist
echo "   Checking for es_market..."
pwsh -Command "
try {
    \$orgInfo = pac org who --json | ConvertFrom-Json -ErrorAction Stop
    \$accessToken = \$orgInfo.AccessToken
    
    \$headers = @{
        'Authorization' = \"Bearer \$accessToken\"
        'Accept' = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version' = '4.0'
    }
    
    \$response = Invoke-RestMethod -Uri '${ENV_URL}/api/data/v9.2/EntityDefinitions?\\$filter=SchemaName%20eq%20%27es_market%27&\\$select=SchemaName,DisplayName' -Headers \$headers
    if (\$response.value.Count -gt 0) {
        Write-Host '   ✅ es_market found' -ForegroundColor Green
    } else {
        Write-Host '   ❌ es_market not found' -ForegroundColor Red
    }
} catch {
    Write-Host '   ❓ Could not verify es_market' -ForegroundColor Yellow
}
"

echo ""
echo "📋 Next Steps:"
echo "1. Go to https://make.powerapps.com"
echo "2. Check 'Tables' section for es_market, es_space, es_reservation"
echo "3. Add entities to your EasySpacesSolution if needed"
echo ""
echo "🌐 Your environment: $ENV_URL"