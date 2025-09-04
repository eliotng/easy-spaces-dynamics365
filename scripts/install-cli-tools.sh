#!/bin/bash

# Easy Spaces - CLI Tools Installation Script
# This script installs .NET, Power Platform CLI, and Node.js for deployment

echo "🚀 Installing CLI tools for Easy Spaces deployment..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on WSL/Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Detected Linux environment"
    
    # Update package list
    print_status "Updating package list..."
    sudo apt update
    
    # Install .NET 8
    print_status "Installing .NET 8..."
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt update
    sudo apt install -y dotnet-sdk-8.0
    
    # Verify .NET installation
    if command -v dotnet &> /dev/null; then
        DOTNET_VERSION=$(dotnet --version)
        print_success ".NET installed: v$DOTNET_VERSION"
    else
        print_error ".NET installation failed"
        exit 1
    fi
    
    # Install Node.js (for PCF controls)
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Verify Node.js installation
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        print_success "Node.js installed: $NODE_VERSION"
        print_success "npm installed: v$NPM_VERSION"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
    
else
    print_warning "This script is designed for Linux/WSL. For Windows, please install manually:"
    echo "1. Install .NET 8 SDK from: https://dotnet.microsoft.com/download"
    echo "2. Install Node.js from: https://nodejs.org/"
    echo "3. Then run: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
    exit 1
fi

# Install Power Platform CLI
print_status "Installing Power Platform CLI..."
dotnet tool install --global Microsoft.PowerApps.CLI.Tool

# Verify PAC CLI installation
if command -v pac &> /dev/null; then
    PAC_VERSION=$(pac --version)
    print_success "Power Platform CLI installed: $PAC_VERSION"
else
    print_error "Power Platform CLI installation failed"
    exit 1
fi

# Add dotnet tools to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.dotnet/tools:"* ]]; then
    echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.bashrc
    export PATH="$PATH:$HOME/.dotnet/tools"
    print_success "Added .NET tools to PATH"
fi

echo ""
print_success "All tools installed successfully!"
echo ""
print_status "Tool versions:"
echo "  .NET: $(dotnet --version)"
echo "  Node.js: $(node --version)"
echo "  npm: $(npm --version)"
echo "  PAC CLI: $(pac --version)"
echo ""
print_status "You can now run the deployment with:"
echo "  ./scripts/deploy-cli.sh --environment-url https://yourorg.crm.dynamics.com"