#!/bin/bash

# Deploy Easy Spaces with provided password
# WARNING: Only use this in secure, isolated environments

echo "🚀 Easy Spaces CLI Deployment Script"
echo "Target Environment: org7cfbe420.crm.dynamics.com"
echo "================================================="

# Check if password provided as argument
if [ -z "$1" ]; then
    echo "Usage: $0 <password>"
    echo "Please provide the sudo password as an argument"
    exit 1
fi

PASSWORD="$1"

# Install PAC CLI
echo "📦 Installing Power Platform CLI..."
curl -L "https://github.com/microsoft/powerplatform-build-tools/releases/latest/download/pac-linux" -o pac
chmod +x pac
echo "$PASSWORD" | sudo -S mv pac /usr/local/bin/pac

# Verify installation
if command -v pac &> /dev/null; then
    echo "✅ PAC CLI installed successfully"
    pac --version
else
    echo "❌ PAC CLI installation failed"
    exit 1
fi

# Authenticate to environment
echo "🔐 Authenticating to org7cfbe420.crm.dynamics.com..."
pac auth create --environment "https://org7cfbe420.crm.dynamics.com" --deviceCode

# Check authentication
if [ $? -ne 0 ]; then
    echo "❌ Authentication failed"
    exit 1
fi

echo "✅ Authentication successful"

# Create and deploy entities using dataverse commands
echo "📋 Creating custom entities..."

# Create Market entity
echo "Creating Market entity..."
pac data create --entity-name "es_market" --entity-display-name "Market" --description "Easy Spaces Market entity"

# Create Space entity  
echo "Creating Space entity..."
pac data create --entity-name "es_space" --entity-display-name "Space" --description "Easy Spaces Space entity"

# Create Reservation entity
echo "Creating Reservation entity..."
pac data create --entity-name "es_reservation" --entity-display-name "Reservation" --description "Easy Spaces Reservation entity"

# Deploy web resources
echo "📁 Deploying web resources..."
pac webresource push --path "/home/e/projects/easy-spaces-dynamics365/web-resources/"

# Final verification
echo "🔍 Verifying deployment..."
pac org who

echo "================================================="
echo "✅ Deployment completed!"
echo "🌐 Access your Easy Spaces app at:"
echo "   https://org7cfbe420.crm.dynamics.com"
echo "================================================="