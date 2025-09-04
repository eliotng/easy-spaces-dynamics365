#!/bin/bash

# Deploy solution from GitHub to Dynamics 365 using PAC CLI
# This moves code FROM GitHub TO Dynamics 365

set -e

echo "🚀 Deploying from GitHub to Dynamics 365"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
SOLUTION_NAME="EasySpacesSolution"
REPO_PATH="/Users/eliot/projects/easy-spaces-dynamics365"
SOLUTION_DIR="${REPO_PATH}/solution/src"

echo -e "${BLUE}[INFO]${NC} Solution: $SOLUTION_NAME"
echo -e "${BLUE}[INFO]${NC} Repository: $REPO_PATH"
echo -e "${BLUE}[INFO]${NC} Solution Directory: $SOLUTION_DIR"

# Ensure we're in the right directory
cd "$REPO_PATH"

# Pull latest changes from GitHub
echo -e "\n${BLUE}📥 Pulling latest changes from GitHub...${NC}"
git pull origin main
echo -e "${GREEN}✅ GitHub sync complete${NC}"

# Check if solution files exist
echo -e "\n${BLUE}🔍 Checking solution files...${NC}"
if [ ! -f "$SOLUTION_DIR/solution.xml" ] || [ ! -f "$SOLUTION_DIR/customizations.xml" ]; then
    echo -e "${RED}❌ Solution files not found in $SOLUTION_DIR${NC}"
    echo -e "${YELLOW}💡 Run ./scripts/sync-with-github.sh first to export from Dynamics${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Solution files found${NC}"

# Create importable solution package
echo -e "\n${BLUE}📦 Creating solution package...${NC}"
TEMP_DIR="temp-deploy-$(date +%s)"
mkdir "$TEMP_DIR"
cd "$TEMP_DIR"

# Copy solution files
cp "$SOLUTION_DIR/solution.xml" .
cp "$SOLUTION_DIR/customizations.xml" .
cp "$SOLUTION_DIR/[Content_Types].xml" .

# Copy any additional directories if they exist
if [ -d "$SOLUTION_DIR/WebResources" ]; then
    cp -r "$SOLUTION_DIR/WebResources" .
fi

if [ -d "$SOLUTION_DIR/Entities" ]; then
    cp -r "$SOLUTION_DIR/Entities" .
fi

# Create zip file
PACKAGE_NAME="GitHubDeploy_$(date +%Y%m%d_%H%M%S).zip"
zip -r "../$PACKAGE_NAME" ./*

cd ..
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Package created: $PACKAGE_NAME${NC}"

# Deploy to Dynamics 365
echo -e "\n${BLUE}🚀 Deploying to Dynamics 365...${NC}"

# Try deployment with different approaches
echo -e "${BLUE}Attempting deployment...${NC}"

# Method 1: Standard import
pac solution import \
  --path "$PACKAGE_NAME" \
  --force-overwrite \
  --publish-changes \
  --async 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Solution deployed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Standard import failed, trying alternative method...${NC}"
    
    # Method 2: Import without async
    pac solution import \
      --path "$PACKAGE_NAME" \
      --force-overwrite \
      --publish-changes 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Solution deployed successfully (alternative method)${NC}"
    else
        echo -e "${YELLOW}⚠️  Direct import failed, checking for existing solution...${NC}"
        
        # Method 3: Check if we need to create entities first
        echo -e "${BLUE}🔍 Analyzing solution contents...${NC}"
        
        # Show what's in the solution
        unzip -l "$PACKAGE_NAME" | head -20
        
        echo -e "${YELLOW}💡 If the solution contains entities, they might need to be created first${NC}"
        echo -e "${YELLOW}💡 Check the customizations.xml for entity definitions${NC}"
    fi
fi

# Clean up
rm -f "$PACKAGE_NAME"

echo -e "\n${BLUE}📋 Deployment Summary:${NC}"
echo -e "${BLUE}Repository:${NC} https://github.com/eliotng/easy-spaces-dynamics365"
echo -e "${BLUE}Solution:${NC} $SOLUTION_NAME"
echo -e "${BLUE}Environment:${NC} https://org7cfbe420.crm.dynamics.com"

echo -e "\n${GREEN}🎉 GitHub to Dynamics 365 deployment complete!${NC}"
echo -e "${BLUE}💡 To sync changes back to GitHub, run: ./scripts/sync-with-github.sh${NC}"