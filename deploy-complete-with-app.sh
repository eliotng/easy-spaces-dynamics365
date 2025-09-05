#!/bin/bash

echo "🚀 Creating Complete Solution with Model-Driven App"
echo "=================================================="

# Create temporary solution directory
mkdir -p temp_complete_solution

# Copy base solution files
cp out/solution.xml temp_complete_solution/
cp out/customizations.xml temp_complete_solution/
cp out/[Content_Types].xml temp_complete_solution/

# Create App directory and copy model-driven app metadata
mkdir -p temp_complete_solution/Apps
mkdir -p temp_complete_solution/SiteMap

echo "📱 Processing model-driven app metadata..."

# Create app definition XML from JSON metadata
cat > temp_complete_solution/Apps/EasySpacesManagement.xml << 'EOF'
<App AppId="es_easyspacesmanagement" UniqueName="es_easyspacesmanagement" Name="Easy Spaces Management" IntroducedVersion="1.0.0.0">
  <Description>Model-driven app for managing spaces, reservations, and markets</Description>
  <AppComponents>
    <AppComponent type="Entity" schemaName="es_market" />
    <AppComponent type="Entity" schemaName="es_space" />
    <AppComponent type="Entity" schemaName="es_reservation" />
    <AppComponent type="SiteMap" schemaName="es_easyspaces_sitemap" />
  </AppComponents>
  <AppDesigner>
    <CanvasAppType>ModelDriven</CanvasAppType>
  </AppDesigner>
</App>
EOF

# Copy sitemap 
cp model-driven-app/sitemap.xml temp_complete_solution/SiteMap/es_easyspaces_sitemap.xml

# Update customizations.xml to include the app
cat > temp_complete_solution/customizations_with_app.xml << 'EOF'
<ImportExportXml version="9.2.25074.250" SolutionPackageVersion="9.2" languagecode="1033">
  <!-- Include original customizations content -->
EOF

# Extract content from original customizations (skip first and last lines)
sed '1d;$d' out/customizations.xml >> temp_complete_solution/customizations_with_app.xml

# Add Apps section before closing tag
cat >> temp_complete_solution/customizations_with_app.xml << 'EOF'
  <Apps>
    <App UniqueName="es_easyspacesmanagement" Name="Easy Spaces Management">
      <LocalizedNames>
        <LocalizedName description="Easy Spaces Management" languagecode="1033" />
      </LocalizedNames>
      <Descriptions>
        <Description description="Model-driven app for managing spaces, reservations, and markets" languagecode="1033" />
      </Descriptions>
      <AppComponents>
        <AppComponent type="Entity" schemaName="es_market" />
        <AppComponent type="Entity" schemaName="es_space" />
        <AppComponent type="Entity" schemaName="es_reservation" />
      </AppComponents>
      <SiteMap>
        <Area Id="EasySpacesArea" Title="Easy Spaces" ShowGroups="true">
          <Group Id="SpacesGroup" Title="Space Management">
            <SubArea Id="Markets" Entity="es_market" Title="Markets" />
            <SubArea Id="Spaces" Entity="es_space" Title="Spaces" />
            <SubArea Id="Reservations" Entity="es_reservation" Title="Reservations" />
          </Group>
        </Area>
      </SiteMap>
    </App>
  </Apps>
  <Languages>
    <Language>1033</Language>
  </Languages>
</ImportExportXml>
EOF

# Replace the original customizations file
mv temp_complete_solution/customizations_with_app.xml temp_complete_solution/customizations.xml

echo "📦 Creating solution zip with model-driven app..."
cd temp_complete_solution
zip -r ../out/EasySpacesComplete_WithApp_$(date +"%Y%m%d_%H%M%S").zip .
cd ..

echo "✅ Complete solution with model-driven app created!"
ls -la out/EasySpacesComplete_WithApp_*.zip

echo ""
echo "🚀 Deploying complete solution with model-driven app..."
SOLUTION_FILE=$(ls -t out/EasySpacesComplete_WithApp_*.zip | head -n1)

pac solution import \
  --path "$SOLUTION_FILE" \
  --environment https://org7cfbe420.crm.dynamics.com \
  --force-overwrite \
  --publish-changes \
  --max-async-wait-time 15

if [ $? -eq 0 ]; then
  echo ""
  echo "🎉 SUCCESS! Complete solution with model-driven app deployed!"
  echo "========================================================="
  echo ""
  echo "✅ DEPLOYED:"
  echo "  ✅ 3 Custom Entities (Market, Space, Reservation)"
  echo "  ✅ Model-Driven App: 'Easy Spaces Management'"
  echo "  ✅ Complete navigation and sitemap"
  echo "  ✅ All forms and views"
  echo ""
  echo "📱 ACCESS YOUR APP:"
  echo "1. Go to: https://make.powerapps.com"
  echo "2. Click 'Apps' → Find 'Easy Spaces Management'"
  echo "3. Click 'Play' → Your complete app opens!"
  echo ""
  echo "🔗 Your Environment: https://org7cfbe420.crm.dynamics.com"
  echo ""
  echo "🎯 You now have a fully functional model-driven app!"
else
  echo "❌ Deployment failed - check error details above"
fi
