#!/bin/bash

# Easy Spaces Plugins Build Script
# This script builds all C# plugins for Dynamics 365

echo "========================================"
echo "Building Easy Spaces C# Plugins"
echo "========================================"

# Navigate to plugins directory
cd "$(dirname "$0")"

# Clean previous builds
echo "Cleaning previous builds..."
dotnet clean EasySpacesPlugins.sln

# Restore packages
echo "Restoring NuGet packages..."
dotnet restore EasySpacesPlugins.sln

# Build all plugins
echo "Building all plugins..."
dotnet build EasySpacesPlugins.sln --configuration Release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ Build completed successfully!"
    echo "========================================"
    echo ""
    echo "Generated assemblies:"
    echo "- ReservationManager/bin/Release/net462/EasySpaces.ReservationManager.dll"
    echo "- CustomerServices/bin/Release/net462/EasySpaces.CustomerServices.dll"  
    echo "- MarketServices/bin/Release/net462/EasySpaces.MarketServices.dll"
    echo ""
    echo "These DLL files can now be registered in Dynamics 365."
else
    echo ""
    echo "========================================"
    echo "❌ Build failed!"
    echo "========================================"
    exit 1
fi
