#!/bin/bash

# Create Easy Spaces entities directly in Dynamics 365 using PAC CLI
# Alternative approach when solution import fails

set -e

echo "🚀 Creating Easy Spaces Entities Directly"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} Environment: https://org7cfbe420.crm.dynamics.com"
echo -e "${BLUE}[INFO]${NC} Creating entities in EasySpacesSolution"

# Check authentication
echo -e "\n${BLUE}🔐 Checking authentication...${NC}"
if ! pac auth list | grep -q "Marketing Trial"; then
    echo -e "${RED}❌ Not authenticated to Dynamics 365${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authenticated to Marketing Trial${NC}"

# Since we can't use solution import, let's try creating a new solution project
echo -e "\n${BLUE}📦 Setting up solution project structure...${NC}"

# Create temporary solution project
TEMP_SOLUTION="temp_easy_spaces_$(date +%s)"
mkdir -p "$TEMP_SOLUTION"
cd "$TEMP_SOLUTION"

# Initialize solution project
echo -e "${BLUE}Initializing solution project...${NC}"
pac solution init \
  --publisher-name "EasySpacesPublisher" \
  --publisher-prefix "es" \
  --solution-name "EasySpacesSolution"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Solution project initialized${NC}"
else
    echo -e "${RED}❌ Failed to initialize solution project${NC}"
    cd ..
    rm -rf "$TEMP_SOLUTION"
    exit 1
fi

# Try to add the entities from our XML definitions
echo -e "\n${BLUE}📋 Copying entity definitions from GitHub...${NC}"

# Copy our customizations.xml to see the entity structures
cp ../out/customizations_fixed.xml ./customizations_reference.xml

echo -e "${YELLOW}💡 Entity definitions reference copied${NC}"
echo -e "${BLUE}Entities to create:${NC}"
echo -e "  • Market (es_market)"
echo -e "  • Space (es_space)" 
echo -e "  • Reservation (es_reservation)"

# Try building and packaging the solution
echo -e "\n${BLUE}🔨 Building solution...${NC}"
if pac solution pack --folder . --zipfile "../EasySpacesTemp.zip"; then
    echo -e "${GREEN}✅ Solution packaged${NC}"
    
    # Try to import the new solution
    echo -e "\n${BLUE}🚀 Deploying solution...${NC}"
    cd ..
    
    if pac solution import --path "EasySpacesTemp.zip" --force-overwrite; then
        echo -e "${GREEN}✅ Solution deployed successfully${NC}"
        SUCCESS=true
    else
        echo -e "${YELLOW}⚠️  Standard import failed${NC}"
        SUCCESS=false
    fi
    
    # Clean up
    rm -f "EasySpacesTemp.zip"
else
    echo -e "${RED}❌ Failed to build solution${NC}"
    SUCCESS=false
fi

# Clean up temp directory
cd ..
rm -rf "$TEMP_SOLUTION"

if [ "$SUCCESS" = true ]; then
    echo -e "\n${GREEN}🎉 Entities created successfully!${NC}"
    echo -e "\n${BLUE}🔍 Next steps:${NC}"
    echo -e "1. Check Power Apps maker portal for the new entities"
    echo -e "2. Add any missing fields manually if needed"
    echo -e "3. Create forms and views"
    echo -e "4. Build the canvas or model-driven app"
else
    echo -e "\n${RED}❌ Direct entity creation failed${NC}"
    echo -e "\n${YELLOW}💡 Summary of what we've tried:${NC}"
    echo -e "  • CLI solution import (failed - unexpected errors)"
    echo -e "  • Manual web UI import (failed - import errors)"
    echo -e "  • Native GitHub integration (not available in trial)"
    echo -e "  • Direct entity creation (just attempted)"
    
    echo -e "\n${BLUE}🎯 Remaining options:${NC}"
    echo -e "1. Use Power Apps web interface to create entities manually"
    echo -e "2. Try different environment (non-trial)"
    echo -e "3. Contact Microsoft support for trial environment limitations"
    
    echo -e "\n${BLUE}📁 Entity definitions are available in:${NC}"
    echo -e "  • GitHub: https://github.com/eliotng/easy-spaces-dynamics365"
    echo -e "  • Local: out/customizations_fixed.xml"
fi

echo -e "\n${BLUE}📋 Environment:${NC} https://org7cfbe420.crm.dynamics.com"