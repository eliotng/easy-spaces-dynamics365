# Easy Spaces - Manual Web UI Deployment Guide Generator
# This script creates comprehensive step-by-step instructions for web-based deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl
)

function Create-DeploymentInstructions {
    param($envUrl)
    
    $instructionsPath = ".\STEP_BY_STEP_DEPLOYMENT.md"
    
    $instructions = @"
# Easy Spaces - Complete Web-Based Deployment Guide

## Target Environment: $envUrl

## IMPORTANT: Use Web Interface Only (No PowerShell Required)

This guide uses only the Power Apps web interface to avoid PowerShell API compatibility issues.

---

## Phase 1: Environment Preparation (5 minutes)

### Step 1: Access Power Apps
1. Open browser and go to: **https://make.powerapps.com/**
2. Sign in with your Dynamics 365 credentials
3. Select your environment from top-right dropdown
4. Verify you can see the main maker portal

### Step 2: Verify Environment
- Environment URL should be: $envUrl
- You should see: Apps, Tables, Flows, etc. in left menu
- If not visible, ensure you have proper permissions

---

## Phase 2: Create Custom Tables (15 minutes)

### Step 3: Create Market Table

1. **Navigate**: Click "Tables" in left menu → "New table"
2. **Configure Basic Info**:
   - Display name: `Market`
   - Plural name: `Markets`
   - Primary column name: `Market Name`
   - Primary column data type: `Text`
3. **Click "Create"**

4. **Add Columns** (Click "Add column" for each):

   **City Column**:
   - Display name: `City`
   - Data type: `Text`
   - Required: `Business required`
   - Maximum length: `100`
   - Click "Save"

   **State Column**:
   - Display name: `State`
   - Data type: `Text`
   - Required: `Optional`
   - Maximum length: `50`
   - Click "Save"

   **Country Column**:
   - Display name: `Country`
   - Data type: `Text`
   - Required: `Optional`
   - Maximum length: `100`
   - Click "Save"

   **Total Daily Booking Rate Column**:
   - Display name: `Total Daily Booking Rate`
   - Data type: `Currency`
   - Required: `Optional`
   - Click "Save"

   **Predicted Booking Rate Column**:
   - Display name: `Predicted Booking Rate`
   - Data type: `Number` → `Decimal number`
   - Required: `Optional`
   - Minimum value: `0`
   - Maximum value: `100`
   - Decimal places: `2`
   - Click "Save"

5. **Save and Publish**: Click "Save table" → "Publish"

### Step 4: Create Space Table

1. **Navigate**: Click "Tables" → "New table"
2. **Configure Basic Info**:
   - Display name: `Space`
   - Plural name: `Spaces`
   - Primary column name: `Space Name`
   - Primary column data type: `Text`
3. **Click "Create"**

4. **Add Columns**:

   **Type Column**:
   - Display name: `Type`
   - Data type: `Choice` → `Choice`
   - Required: `Business required`
   - Choices:
     - `Warehouse`
     - `Office`
     - `Café`
     - `Game Room`
     - `Gallery`
     - `Rooftop`
     - `Theater`
   - Click "Save"

   **Category Column**:
   - Display name: `Category`
   - Data type: `Choice`
   - Required: `Optional`
   - Choices:
     - `Indoor`
     - `Outdoor`
     - `Hybrid`
   - Click "Save"

   **Minimum Capacity Column**:
   - Display name: `Minimum Capacity`
   - Data type: `Number` → `Whole number`
   - Required: `Business required`
   - Minimum value: `1`
   - Maximum value: `10000`
   - Click "Save"

   **Maximum Capacity Column**:
   - Display name: `Maximum Capacity`
   - Data type: `Number` → `Whole number`
   - Required: `Business required`
   - Minimum value: `1`
   - Maximum value: `10000`
   - Click "Save"

   **Daily Booking Rate Column**:
   - Display name: `Daily Booking Rate`
   - Data type: `Currency`
   - Required: `Business required`
   - Click "Save"

   **Picture URL Column**:
   - Display name: `Picture URL`
   - Data type: `Text`
   - Required: `Optional`
   - Maximum length: `500`
   - Click "Save"

   **Market Column** (Lookup):
   - Display name: `Market`
   - Data type: `Lookup` → `Lookup`
   - Required: `Business required`
   - Related table: `Markets` (select from dropdown)
   - Click "Save"

   **Predicted Demand Column**:
   - Display name: `Predicted Demand`
   - Data type: `Choice`
   - Required: `Optional`
   - Choices:
     - `Low`
     - `Medium`
     - `High`
   - Click "Save"

   **Predicted Booking Rate Column**:
   - Display name: `Predicted Booking Rate`
   - Data type: `Number` → `Decimal number`
   - Required: `Optional`
   - Minimum value: `0`
   - Maximum value: `100`
   - Decimal places: `2`
   - Click "Save"

5. **Save and Publish**: Click "Save table" → "Publish"

### Step 5: Create Reservation Table

1. **Navigate**: Click "Tables" → "New table"
2. **Configure Basic Info**:
   - Display name: `Reservation`
   - Plural name: `Reservations`
   - Primary column name: `Reservation Name`
   - Primary column data type: `Text`
3. **Advanced options**: Check "Enable attachments"
4. **Click "Create"**

4. **Add Columns**:

   **Status Column**:
   - Display name: `Status`
   - Data type: `Choice`
   - Required: `Business required`
   - Default choice: `Draft`
   - Choices:
     - `Draft`
     - `Submitted`
     - `Confirmed`
     - `Cancelled`
     - `Completed`
   - Click "Save"

   **Start Date Column**:
   - Display name: `Start Date`
   - Data type: `Date and time` → `Date only`
   - Required: `Business required`
   - Click "Save"

   **End Date Column**:
   - Display name: `End Date`
   - Data type: `Date and time` → `Date only`
   - Required: `Business required`
   - Click "Save"

   **Start Time Column**:
   - Display name: `Start Time`
   - Data type: `Text`
   - Required: `Optional`
   - Maximum length: `10`
   - Click "Save"

   **End Time Column**:
   - Display name: `End Time`
   - Data type: `Text`
   - Required: `Optional`
   - Maximum length: `10`
   - Click "Save"

   **Total Number of Guests Column**:
   - Display name: `Total Number of Guests`
   - Data type: `Number` → `Whole number`
   - Required: `Business required`
   - Minimum value: `1`
   - Maximum value: `10000`
   - Click "Save"

   **Space Column** (Lookup):
   - Display name: `Space`
   - Data type: `Lookup`
   - Required: `Business required`
   - Related table: `Spaces` (select from dropdown)
   - Click "Save"

   **Market Column** (Lookup):
   - Display name: `Market`
   - Data type: `Lookup`
   - Required: `Optional`
   - Related table: `Markets`
   - Click "Save"

   **Contact Column** (Lookup):
   - Display name: `Contact`
   - Data type: `Lookup`
   - Required: `Optional`
   - Related table: `Contacts`
   - Click "Save"

   **Lead Column** (Lookup):
   - Display name: `Lead`
   - Data type: `Lookup`
   - Required: `Optional`
   - Related table: `Leads`
   - Click "Save"

   **Account Column** (Lookup):
   - Display name: `Account`
   - Data type: `Lookup`
   - Required: `Optional`
   - Related table: `Accounts`
   - Click "Save"

5. **Save and Publish**: Click "Save table" → "Publish"

---

## Phase 3: Import Sample Data (10 minutes)

### Step 6: Create Sample Markets

1. **Navigate**: Click "Tables" → "Markets" → "Data" tab
2. **Add Market Records** (Click "+ New" for each):

   **Market 1:**
   - Market Name: `San Francisco`
   - City: `San Francisco`
   - State: `CA`
   - Country: `USA`
   - Save

   **Market 2:**
   - Market Name: `New York`
   - City: `New York`
   - State: `NY`
   - Country: `USA`
   - Save

   **Market 3:**
   - Market Name: `Los Angeles`
   - City: `Los Angeles`
   - State: `CA`
   - Country: `USA`
   - Save

   **Market 4:**
   - Market Name: `Chicago`
   - City: `Chicago`
   - State: `IL`
   - Country: `USA`
   - Save

### Step 7: Create Sample Spaces

1. **Navigate**: Click "Tables" → "Spaces" → "Data" tab
2. **Add Space Records** (Click "+ New" for each):

   **Space 1:**
   - Space Name: `Starlight Gallery`
   - Type: `Gallery`
   - Category: `Indoor`
   - Minimum Capacity: `10`
   - Maximum Capacity: `100`
   - Daily Booking Rate: `1500`
   - Market: `San Francisco` (select from lookup)
   - Picture URL: `https://images.unsplash.com/photo-1565538420870-da08ff96a207`
   - Save

   **Space 2:**
   - Space Name: `Urban Rooftop`
   - Type: `Rooftop`
   - Category: `Outdoor`
   - Minimum Capacity: `20`
   - Maximum Capacity: `150`
   - Daily Booking Rate: `2000`
   - Market: `San Francisco`
   - Picture URL: `https://images.unsplash.com/photo-1514214460829-5f081763862a`
   - Save

   **Space 3:**
   - Space Name: `Tech Hub`
   - Type: `Office`
   - Category: `Indoor`
   - Minimum Capacity: `5`
   - Maximum Capacity: `50`
   - Daily Booking Rate: `800`
   - Market: `San Francisco`
   - Picture URL: `https://images.unsplash.com/photo-1497366216548-37526070297c`
   - Save

   **Space 4:**
   - Space Name: `Manhattan Loft`
   - Type: `Warehouse`
   - Category: `Indoor`
   - Minimum Capacity: `30`
   - Maximum Capacity: `200`
   - Daily Booking Rate: `2500`
   - Market: `New York`
   - Picture URL: `https://images.unsplash.com/photo-1416453072034-c8dbfec6`
   - Save

---

## Phase 4: Create Model-Driven App (10 minutes)

### Step 8: Create Model-Driven App

1. **Navigate**: Click "Apps" → "New app" → "Model-driven"
2. **Configure App**:
   - Name: `Easy Spaces Management`
   - Description: `Event space management application`
   - Use existing solution: `Default Solution`
   - Click "Create"

3. **Add Tables**: In app designer, click "+ Add page" → "Table based view and form":
   - Select `Markets`
   - Select `Spaces`
   - Select `Reservations`
   - Select `Contacts`
   - Select `Leads`
   - Select `Accounts`
   - Click "Add"

4. **Configure Navigation**: Click "Navigation" → Rename groups:
   - Group 1: "Space Management" (Markets, Spaces)
   - Group 2: "Reservations" (Reservations)
   - Group 3: "Customers" (Contacts, Leads, Accounts)

5. **Save and Publish**: Click "Save" → "Publish"

---

## Phase 5: Create Canvas App (15 minutes)

### Step 9: Create Canvas App

1. **Navigate**: Click "Apps" → "New app" → "Canvas"
2. **Choose**: "Tablet format"
3. **Name**: `Easy Spaces Canvas`

4. **Add Data Sources**: Click "Data" → "+ Add data":
   - Add `Markets`
   - Add `Spaces`
   - Add `Reservations`
   - Add `Contacts`

5. **Design Home Screen**:
   - Add a `Gallery` control
   - Set Items property to: `Spaces`
   - Configure gallery template with:
     - Image: `ThisItem.'Picture URL'`
     - Title: `ThisItem.'Space Name'`
     - Subtitle: `ThisItem.Type`

6. **Add Navigation**:
   - Add buttons for navigation between screens
   - Create detail screen for space information
   - Create reservation form screen

7. **Save and Publish**: Click "Save" → "Publish"

---

## Phase 6: Set Up Power Automate Flows (10 minutes)

### Step 10: Create Approval Flow

1. **Navigate**: Go to https://make.powerautomate.com/
2. **Create Flow**: Click "New flow" → "Automated cloud flow"
3. **Configure Trigger**:
   - Name: `Easy Spaces - Reservation Approval`
   - Trigger: "When a row is added, modified or deleted" (Microsoft Dataverse)
   - Table: `Reservations`
   - Change type: `Added or Modified`
   - Click "Create"

4. **Add Condition**: Add action → "Condition"
   - Left side: `Status` (from dynamic content)
   - Condition: `is equal to`
   - Right side: `Submitted`

5. **If Yes Branch**: Add actions:
   - "Get a row by ID" (Dataverse) → Table: `Spaces`
   - "Update a row" (Dataverse) → Set status to `Confirmed`
   - "Send an email" (Office 365 Outlook) → Notify contact

6. **Save and Test**: Click "Save" → Test with sample data

---

## Phase 7: Testing and Validation (10 minutes)

### Step 11: Test the Complete Solution

1. **Test Model-Driven App**:
   - Open the Easy Spaces Management app
   - Navigate through all tables
   - Create a test reservation
   - Verify all lookups work correctly

2. **Test Canvas App**:
   - Open the Easy Spaces Canvas app
   - Browse the space gallery
   - Test navigation between screens
   - Verify images display correctly

3. **Test Power Automate Flow**:
   - Create a reservation with "Submitted" status
   - Check that flow triggers
   - Verify status changes to "Confirmed"

4. **Verify Data Integrity**:
   - Check all relationships work
   - Confirm sample data displays correctly
   - Test filtering and searching

---

## Phase 8: Final Configuration (5 minutes)

### Step 12: Security and Permissions

1. **Share Apps**: Go to each app → "Share"
   - Add users who need access
   - Grant appropriate permissions

2. **Environment Settings**: In admin center:
   - Configure data loss prevention policies
   - Set up backup schedules
   - Review security settings

---

## Troubleshooting Common Issues

### Issue: "Access Denied" errors
- **Solution**: Check security roles and permissions
- **Action**: Admin Center → Security roles → Assign proper roles

### Issue: Lookup fields not showing data
- **Solution**: Verify relationships are properly created
- **Action**: Tables → Relationships → Check relationship configuration

### Issue: Canvas app shows no data
- **Solution**: Refresh data sources
- **Action**: App → Data → Refresh each data source

### Issue: Flow not triggering
- **Solution**: Check trigger conditions
- **Action**: Flow → Trigger settings → Verify table and conditions

---

## Success Criteria Checklist

- [ ] All three custom tables created and published
- [ ] Sample data imported successfully
- [ ] Model-driven app created and accessible
- [ ] Canvas app created and functional
- [ ] Power Automate flow created and tested
- [ ] All relationships working correctly
- [ ] Security permissions configured
- [ ] Users can access and use the applications

---

## Next Steps After Deployment

1. **Add More Sample Data**: Import additional spaces and markets
2. **Customize Forms**: Enhance the user interface in model-driven app
3. **Extend Canvas App**: Add more screens and functionality
4. **Create Reports**: Build Power BI reports for analytics
5. **Set Up Monitoring**: Configure application insights and monitoring

---

## Support and Documentation

- **Power Apps Documentation**: https://docs.microsoft.com/powerapps/
- **Power Automate Guide**: https://docs.microsoft.com/power-automate/
- **Community Support**: https://powerusers.microsoft.com/

---

**Estimated Total Time**: 90 minutes
**Difficulty Level**: Beginner to Intermediate
**Prerequisites**: Dynamics 365 trial account, Power Apps access

**IMPORTANT**: This guide uses only web interfaces to avoid PowerShell compatibility issues.
"@

    $instructions | Out-File -FilePath $instructionsPath -Encoding UTF8
    
    Write-Host "`n================================" -ForegroundColor Green
    Write-Host " DEPLOYMENT GUIDE CREATED!" -ForegroundColor Green  
    Write-Host "================================`n" -ForegroundColor Green
    
    Write-Host "Complete step-by-step guide created at:" -ForegroundColor Cyan
    Write-Host "  $instructionsPath" -ForegroundColor Yellow
    
    Write-Host "`nThis guide uses ONLY web interfaces - no PowerShell required!" -ForegroundColor Green
    Write-Host "Estimated deployment time: 90 minutes" -ForegroundColor Cyan
    Write-Host "No API compatibility issues!" -ForegroundColor Green
    
    # Open the file if on Windows
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Write-Host "`nOpening deployment guide..." -ForegroundColor Cyan
        try {
            Start-Process $instructionsPath
        } catch {
            Write-Host "Guide created successfully at: $instructionsPath" -ForegroundColor Green
        }
    }
}

# Main execution
try {
    Write-Host "`n================================" -ForegroundColor Magenta
    Write-Host " Easy Spaces - Web Deployment" -ForegroundColor Magenta
    Write-Host "================================" -ForegroundColor Magenta
    Write-Host "Creating comprehensive web-based deployment guide..." -ForegroundColor Cyan
    Write-Host "Target Environment: $EnvironmentUrl" -ForegroundColor Green
    
    Create-DeploymentInstructions -envUrl $EnvironmentUrl
    
    Write-Host "`nDEPLOYMENT RECOMMENDATION:" -ForegroundColor Yellow
    Write-Host "Use the web-based guide to avoid PowerShell API issues." -ForegroundColor White
    Write-Host "The web interface is 100% reliable and officially supported." -ForegroundColor Green
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}