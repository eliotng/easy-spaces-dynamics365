#!/bin/bash

# Sync EasySpacesSolution with GitHub using PAC CLI
# This is an alternative to the web UI GitHub integration

set -e

echo "🔄 Setting up CLI-based GitHub sync for EasySpacesSolution"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOLUTION_NAME="EasySpacesSolution"
REPO_PATH="/Users/eliot/projects/easy-spaces-dynamics365"
SOLUTION_DIR="${REPO_PATH}/solution/src"

echo -e "${BLUE}[INFO]${NC} Solution: $SOLUTION_NAME"
echo -e "${BLUE}[INFO]${NC} Repository: $REPO_PATH"
echo -e "${BLUE}[INFO]${NC} Solution Directory: $SOLUTION_DIR"

# Export solution from Dynamics 365
echo -e "\n${BLUE}🔽 Exporting solution from Dynamics 365...${NC}"
cd "$REPO_PATH"

pac solution export \
  --name "$SOLUTION_NAME" \
  --path "${REPO_PATH}/temp-export.zip" \
  --managed false

echo -e "${GREEN}✅ Solution exported${NC}"

# Extract and organize files
echo -e "\n${BLUE}📦 Extracting solution files...${NC}"
rm -rf temp-extract
mkdir temp-extract
cd temp-extract
unzip -q ../temp-export.zip

# Copy files to solution directory
echo -e "${BLUE}📁 Organizing solution structure...${NC}"
mkdir -p "$SOLUTION_DIR"
cp customizations.xml "$SOLUTION_DIR/"
cp solution.xml "$SOLUTION_DIR/"
cp "[Content_Types].xml" "$SOLUTION_DIR/"

# Copy any additional files
if [ -d "WebResources" ]; then
    cp -r WebResources "$SOLUTION_DIR/"
fi

if [ -d "Entities" ]; then
    cp -r Entities "$SOLUTION_DIR/"
fi

cd "$REPO_PATH"
rm -rf temp-extract temp-export.zip

echo -e "${GREEN}✅ Solution files organized${NC}"

# Commit changes to Git
echo -e "\n${BLUE}💾 Committing changes to Git...${NC}"
git add solution/
git status

if ! git diff --cached --quiet; then
    git commit -m "Sync EasySpacesSolution from Dynamics 365

- Updated customizations.xml with latest entity definitions
- Synced solution.xml with current metadata
- Auto-sync via PAC CLI

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    echo -e "${GREEN}✅ Changes committed${NC}"
    
    # Push to GitHub
    echo -e "\n${BLUE}🚀 Pushing to GitHub...${NC}"
    git push origin main
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
else
    echo -e "${BLUE}ℹ️  No changes to commit${NC}"
fi

echo -e "\n${GREEN}🎉 GitHub sync complete!${NC}"
echo -e "${BLUE}Repository URL:${NC} https://github.com/eliotng/easy-spaces-dynamics365"
echo -e "${BLUE}Solution Directory:${NC} solution/src/"