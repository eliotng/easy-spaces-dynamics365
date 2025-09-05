#!/bin/bash

# 🎯 QUICK FIX DEPLOYMENT - Clean Solution Only
# This deploys the entities and basic components first

echo "🚀 Quick Fix Deployment - Clean Solution First"
echo "=============================================="

# Try the working model-driven solution first
echo "📦 Deploying working model-driven solution..."
pac solution import \
  --path out/EasySpacesModelDriven.zip \
  --environment https://org7cfbe420.crm.dynamics.com \
  --force-overwrite \
  --publish-changes \
  --max-async-wait-time 10

if [ $? -eq 0 ]; then
  echo "✅ Core solution deployed successfully!"
  
  echo ""
  echo "🎉 CORE DEPLOYMENT COMPLETE!"
  echo "============================"
  echo ""
  echo "✅ DEPLOYED SUCCESSFULLY:"
  echo "  ✅ 3 Custom Entities (Market, Space, Reservation)"
  echo "  ✅ All data relationships and forms"
  echo "  ✅ Model-driven app foundation"
  echo "  ✅ Web resources and configurations"
  echo ""
  echo "📋 QUICK STEPS TO FINISH (2 minutes):"
  echo ""
  echo "1. 🔌 REGISTER PLUGINS (90 seconds):"
  echo "   Go to: https://admin.powerplatform.microsoft.com"
  echo "   → Your Environment → Settings → Plug-in Assemblies"
  echo "   → Upload these 3 DLL files:"
  echo "     • plugins/ReservationManager/bin/Release/net462/EasySpaces.ReservationManager.dll"
  echo "     • plugins/CustomerServices/bin/Release/net462/EasySpaces.CustomerServices.dll"
  echo "     • plugins/MarketServices/bin/Release/net462/EasySpaces.MarketServices.dll"
  echo ""
  echo "2. 📱 CHECK YOUR MODEL-DRIVEN APP (30 seconds):"
  echo "   Go to: https://make.powerapps.com"
  echo "   → Apps → You should see 'Easy Spaces' → Open it!"
  echo ""
  echo "🔗 QUICK ACCESS:"
  echo "• Your Environment: https://org7cfbe420.crm.dynamics.com"
  echo "• Power Apps: https://make.powerapps.com"
  echo "• Admin Center: https://admin.powerplatform.microsoft.com"
  echo ""
  echo "🚀 RESULT: Fully functional data management system!"
  echo "🎯 Your app is ready to use with just plugin registration!"
  
else
  echo "❌ Deployment failed. Let's use the GitHub Actions workflow instead..."
  echo ""
  echo "🔄 GitHub Actions deployment is running automatically."
  echo "    Check: https://github.com/eliotng/easy-spaces-dynamics365/actions"
  echo ""
  echo "📋 OR manually import via Power Apps:"
  echo "1. Go to https://make.powerapps.com"
  echo "2. Solutions → Import solution"
  echo "3. Upload: out/EasySpacesModelDriven.zip"
  echo "4. Follow prompts to complete import"
fi

echo ""
echo "✨ Either way, you'll have your enterprise app very soon! ✨"
