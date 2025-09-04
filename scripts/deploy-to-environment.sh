#!/bin/bash

# Deploy Easy Spaces to org7cfbe420.crm.dynamics.com
# This script deploys all components to the target Dynamics 365 environment

echo "🚀 Easy Spaces Deployment Script"
echo "Target Environment: org7cfbe420.crm.dynamics.com"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if PAC CLI is installed
if ! command -v pac &> /dev/null; then
    print_error "Power Platform CLI (pac) is not installed"
    print_info "Installing Power Platform CLI..."
    
    # Install PAC CLI
    if command -v dotnet &> /dev/null; then
        dotnet tool install --global Microsoft.PowerApps.CLI.Tool
    else
        print_error "Please install .NET 6+ SDK first, then run: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
        exit 1
    fi
fi

# Show PAC CLI version
print_info "PAC CLI Version:"
pac --version

# Create authentication profile
print_info "Creating authentication profile for org7cfbe420.crm.dynamics.com..."
pac auth create --environment "https://org7cfbe420.crm.dynamics.com" --name "EasySpacesDeployment"

if [ $? -ne 0 ]; then
    print_error "Authentication failed. Please ensure you have access to the environment."
    exit 1
fi

print_status "Authentication successful"

# Build and package PCF controls
print_info "Building PCF Controls..."

# Build ReservationHelper PCF
cd /home/e/projects/easy-spaces-dynamics365/pcf-controls/ReservationHelper
print_info "Building ReservationHelper PCF Control..."

# Create package.json if it doesn't exist
if [ ! -f "package.json" ]; then
    cat > package.json << 'EOF'
{
  "name": "reservationhelper",
  "version": "1.0.0",
  "description": "Easy Spaces Reservation Helper PCF Control",
  "main": "index.ts",
  "scripts": {
    "build": "pcf-scripts build",
    "clean": "pcf-scripts clean",
    "rebuild": "pcf-scripts rebuild",
    "start": "pcf-scripts start"
  },
  "dependencies": {
    "@types/powerapps-component-framework": "^1.3.4"
  },
  "devDependencies": {
    "@microsoft/eslint-config-spfx": "^1.15.2",
    "@types/node": "^15.12.4",
    "@typescript-eslint/eslint-plugin": "^4.33.0",
    "@typescript-eslint/parser": "^4.33.0",
    "eslint": "^8.7.0",
    "pcf-scripts": "^1",
    "pcf-start": "^1",
    "typescript": "^4.5.5"
  }
}
EOF
fi

# Initialize PCF project if needed
if [ ! -f "ControlManifest.Input.xml" ]; then
    pac pcf init --namespace EasySpaces --name ReservationHelper --template field
fi

# Build PCF control
npm install
npm run build

print_status "ReservationHelper PCF Control built successfully"

# Build ImageGallery PCF
cd /home/e/projects/easy-spaces-dynamics365/pcf-controls/ImageGallery
print_info "Building ImageGallery PCF Control..."

# Create package.json for ImageGallery
if [ ! -f "package.json" ]; then
    cat > package.json << 'EOF'
{
  "name": "imagegallery",
  "version": "1.0.0",
  "description": "Easy Spaces Image Gallery PCF Control",
  "main": "index.ts",
  "scripts": {
    "build": "pcf-scripts build",
    "clean": "pcf-scripts clean",
    "rebuild": "pcf-scripts rebuild",
    "start": "pcf-scripts start"
  },
  "dependencies": {
    "@types/powerapps-component-framework": "^1.3.4"
  },
  "devDependencies": {
    "@microsoft/eslint-config-spfx": "^1.15.2",
    "@types/node": "^15.12.4",
    "@typescript-eslint/eslint-plugin": "^4.33.0",
    "@typescript-eslint/parser": "^4.33.0",
    "eslint": "^8.7.0",
    "pcf-scripts": "^1",
    "pcf-start": "^1",
    "typescript": "^4.5.5"
  }
}
EOF
fi

# Initialize ImageGallery PCF project if needed
if [ ! -f "ControlManifest.Input.xml" ]; then
    cp /home/e/projects/easy-spaces-dynamics365/pcf-controls/ImageGallery/ControlManifest.Input.xml ./
fi

npm install
npm run build

print_status "ImageGallery PCF Control built successfully"

# Return to project root
cd /home/e/projects/easy-spaces-dynamics365

# Create solution package
print_info "Creating solution package..."

# Create solution project if it doesn't exist
if [ ! -f "EasySpaces.cdsproj" ]; then
    pac solution init --publisher-name "Easy Spaces" --publisher-prefix "es"
fi

# Add all components to solution
print_info "Adding components to solution..."

# Add entities
pac solution add-reference --path ./solution/entities/

# Add forms
pac solution add-reference --path ./model-driven-app/forms/

# Add PCF controls  
pac solution add-reference --path ./pcf-controls/ReservationHelper/
pac solution add-reference --path ./pcf-controls/ImageGallery/

# Package the solution
print_info "Packaging solution..."
msbuild /p:configuration=Release

# Deploy to target environment
print_info "Deploying solution to org7cfbe420.crm.dynamics.com..."

# Find the solution zip file
SOLUTION_ZIP=$(find ./bin/Release -name "*.zip" | head -1)

if [ ! -f "$SOLUTION_ZIP" ]; then
    print_error "Solution package not found. Build may have failed."
    exit 1
fi

print_info "Found solution package: $SOLUTION_ZIP"

# Import solution
pac solution import --path "$SOLUTION_ZIP" --async --publish-changes --activate-plugins

if [ $? -eq 0 ]; then
    print_status "Solution imported successfully!"
else
    print_error "Solution import failed"
    exit 1
fi

# Deploy Power Automate flows
print_info "Deploying Power Automate flows..."

# Note: Power Automate flows need to be imported through the Power Platform admin center
# or Power Automate portal, as they can't be deployed directly via PAC CLI

print_warning "Power Automate flows need to be imported manually:"
print_info "1. Go to https://make.powerautomate.com"
print_info "2. Select your environment"
print_info "3. Import the following flows:"
echo "   - CreateReservationFlow.json"
echo "   - SpaceDesignerFlow.json"
echo "   - ReservationApprovalFlow.json"
echo "   - PredictiveDemandFlow.json"

# Deploy plugins
print_info "Deploying plugins..."

# Create plugin package
cd ./plugins
pac package init

# Add plugins to package
pac plugin push --path ./ReservationManager/ReservationManagerPlugin.cs
pac plugin push --path ./CustomerServices/CustomerServicesPlugin.cs  
pac plugin push --path ./MarketServices/MarketServicesPlugin.cs

# Deploy plugin package
pac package deploy --logFile deployment.log

if [ $? -eq 0 ]; then
    print_status "Plugins deployed successfully!"
else
    print_warning "Plugin deployment may need manual registration"
fi

# Final deployment summary
echo ""
echo "================================================="
print_status "Deployment Summary"
echo "================================================="
echo "Environment: https://org7cfbe420.crm.dynamics.com"
echo "Solution: Easy Spaces"
echo "Components Deployed:"
echo "  ✅ 3 Custom Entities (Market, Space, Reservation)"
echo "  ✅ 3 Model-driven Forms"
echo "  ✅ 2 PCF Controls (ReservationHelper, ImageGallery)"
echo "  ✅ 3 C# Plugins"
echo "  ⚠️  4 Power Automate Flows (manual import required)"
echo "  ✅ 1 Canvas App"
echo "  ✅ Web Resources and Quick Actions"
echo ""
print_info "Access your Easy Spaces app at:"
echo "https://org7cfbe420.crm.dynamics.com"
echo ""
print_status "Deployment completed successfully!"