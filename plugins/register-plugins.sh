#!/bin/bash

# Automated Plugin Registration using PAC CLI
# Run this after the main solution is deployed

echo "========================================"
echo "Automated Plugin Registration"
echo "========================================"

cd "$(dirname "$0")"

echo "🔌 Registering ReservationManager Plugin..."
pac plugin push \
  --path ReservationManager/bin/Release/net462/EasySpaces.ReservationManager.dll \
  --environment https://org7cfbe420.crm.dynamics.com

echo "🔌 Registering CustomerServices Plugin..."  
pac plugin push \
  --path CustomerServices/bin/Release/net462/EasySpaces.CustomerServices.dll \
  --environment https://org7cfbe420.crm.dynamics.com

echo "🔌 Registering MarketServices Plugin..."
pac plugin push \
  --path MarketServices/bin/Release/net462/EasySpaces.MarketServices.dll \
  --environment https://org7cfbe420.crm.dynamics.com

echo ""
echo "✅ Plugin registration complete!"
echo ""
echo "🔍 To verify registration:"
echo "pac plugin list --environment https://org7cfbe420.crm.dynamics.com"
echo ""
echo "🎯 To register plugin steps manually:"
echo "1. Use Plugin Registration Tool"
echo "2. Or configure via Power Platform admin center"
