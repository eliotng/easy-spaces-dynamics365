#!/bin/bash

# Deploy the Entity-rich solution from our GitHub out/ directory to Dynamics 365
# Uses the pre-built solution with entities already defined

set -e

echo "🚀 Deploying Easy Spaces Entities from GitHub"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
REPO_PATH="/Users/eliot/projects/easy-spaces-dynamics365"

echo -e "${BLUE}[INFO]${NC} Repository: $REPO_PATH"

# Ensure we're in the right directory
cd "$REPO_PATH"

# Pull latest changes from GitHub
echo -e "\n${BLUE}📥 Pulling latest changes from GitHub...${NC}"
git pull origin main
echo -e "${GREEN}✅ GitHub sync complete${NC}"

# Use the working solution package with entities
SOLUTION_PACKAGE="out/EasySpaces_Working_Update.zip"

echo -e "\n${BLUE}🔍 Checking for entity solution package...${NC}"
if [ ! -f "$SOLUTION_PACKAGE" ]; then
    echo -e "${RED}❌ Entity solution package not found: $SOLUTION_PACKAGE${NC}"
    echo -e "${YELLOW}💡 Available solutions:${NC}"
    ls -la out/*.zip 2>/dev/null || echo "No zip files found in out/"
    exit 1
fi

echo -e "${GREEN}✅ Found entity solution: $SOLUTION_PACKAGE${NC}"

# Show what entities are in the solution
echo -e "\n${BLUE}📋 Solution contains:${NC}"
echo -e "  • Market entity (es_market)"
echo -e "  • Space entity (es_space)" 
echo -e "  • Reservation entity (es_reservation)"
echo -e "  • Entity relationships"

# Deploy to Dynamics 365
echo -e "\n${BLUE}🚀 Deploying entities to Dynamics 365...${NC}"
echo -e "${YELLOW}⏳ This may take a few minutes...${NC}"

# Try async deployment first
echo -e "${BLUE}Attempting async deployment...${NC}"
if pac solution import --path "$SOLUTION_PACKAGE" --force-overwrite --publish-changes --async; then
    echo -e "${GREEN}✅ Entities deployed successfully${NC}"
    DEPLOYMENT_SUCCESS=true
else
    echo -e "${YELLOW}⚠️  Async deployment failed, trying synchronous...${NC}"
    
    if pac solution import --path "$SOLUTION_PACKAGE" --force-overwrite --publish-changes; then
        echo -e "${GREEN}✅ Entities deployed successfully (synchronous mode)${NC}"
        DEPLOYMENT_SUCCESS=true
    else
        echo -e "${RED}❌ Both deployment methods failed${NC}"
        echo -e "${YELLOW}💡 This might be due to:${NC}"
        echo -e "  • Solution import limitations in trial environment"
        echo -e "  • Entity naming conflicts" 
        echo -e "  • Missing permissions"
        DEPLOYMENT_SUCCESS=false
    fi
fi

if [ "$DEPLOYMENT_SUCCESS" = true ]; then
    echo -e "\n${GREEN}🎉 Entity deployment complete!${NC}"
    echo -e "\n${BLUE}✨ What was deployed:${NC}"
    echo -e "  📊 Market entity for geographical markets"
    echo -e "  🏢 Space entity for event spaces"  
    echo -e "  📅 Reservation entity for bookings"
    echo -e "  🔗 Relationships between entities"
    
    echo -e "\n${BLUE}🔍 Next steps:${NC}"
    echo -e "  1. Check Power Apps maker portal: https://make.powerapps.com"
    echo -e "  2. Go to Tables section to see new entities"
    echo -e "  3. Create forms and views for the entities"
    echo -e "  4. Build the canvas or model-driven app"
    
    echo -e "\n${BLUE}🔄 To sync any changes back to GitHub:${NC}"
    echo -e "  ./scripts/sync-with-github.sh"
else
    echo -e "\n${RED}❌ Deployment failed${NC}"
    echo -e "${YELLOW}💡 Alternative: Try manual import via Power Apps web UI${NC}"
    echo -e "  1. Go to https://make.powerapps.com"
    echo -e "  2. Solutions → Import solution"  
    echo -e "  3. Upload: $SOLUTION_PACKAGE"
fi

echo -e "\n${BLUE}📋 Environment Details:${NC}"
echo -e "${BLUE}Repository:${NC} https://github.com/eliotng/easy-spaces-dynamics365"
echo -e "${BLUE}Environment:${NC} https://org7cfbe420.crm.dynamics.com"