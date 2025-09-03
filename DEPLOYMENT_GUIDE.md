# Easy Spaces for Dynamics 365 - Deployment Guide

## Overview
This guide will help you deploy the Easy Spaces application to your Microsoft Dynamics 365 trial account. The application is a complete conversion of the Salesforce Lightning Web Components (LWC) Easy Spaces app, recreated using Microsoft's Power Platform technologies.

## Prerequisites

### 1. Microsoft Dynamics 365 Trial Account
- Sign up for a free trial at: https://dynamics.microsoft.com/en-us/dynamics-365-free-trial/
- Choose "Sales" or "Customer Service" trial (both include the required features)
- You'll receive admin access to a Dynamics 365 environment

### 2. Power Platform Admin Access
- Your trial account includes Power Platform access
- Navigate to: https://admin.powerplatform.microsoft.com/
- Ensure you can see your trial environment

### 3. Required Tools
- Windows PowerShell 5.1 or later (for deployment script)
- Modern web browser (Edge, Chrome, Firefox)
- Optional: Power Apps Studio (for Canvas app customization)

## Deployment Steps

### Step 1: Environment Preparation

1. **Access Power Platform Admin Center**
   ```
   https://admin.powerplatform.microsoft.com/
   ```

2. **Select Your Environment**
   - Click on "Environments" in the left navigation
   - Select your trial environment
   - Note the Environment URL (you'll need this later)

3. **Enable Required Features**
   - In your environment settings, ensure these are enabled:
     - Power Apps component framework for canvas apps
     - Dataverse search
     - AI Builder (optional - see note below)
   
   **Note about AI Builder:**
   - AI Builder may not be available in all trial environments
   - It requires additional capacity/credits (not always included in trials)
   - The app will work without AI Builder - predictive features will use Power Automate calculations instead
   - To check availability: Go to Power Apps → AI Builder → If you see "Get started", it's not activated

### Step 2: Run Automated Deployment Script

1. **Open PowerShell as Administrator**

2. **Navigate to the scripts folder**
   ```powershell
   cd path\to\easy-spaces-dynamics365\scripts
   ```

3. **Run the deployment script**
   ```powershell
   .\Deploy-EasySpaces.ps1 -EnvironmentUrl "https://yourorg.crm.dynamics.com" -UseInteractiveAuth -ImportSampleData
   ```
   
   The script will:
   - Install required PowerShell modules
   - Connect to your Dynamics 365 environment
   - Create the publisher and solution
   - Set up the basic structure

### Step 3: Manual Entity Creation (if needed)

If the script couldn't create entities automatically:

1. **Navigate to Power Apps**
   ```
   https://make.powerapps.com/
   ```

2. **Select your environment** from the top-right dropdown

3. **Create Custom Entities**
   
   a. **Market Entity (es_market)**
   - Click "Tables" → "New table"
   - Display name: Market
   - Plural name: Markets
   - Primary column: Market Name
   - Enable: Notes, Activities, Auditing
   
   b. **Space Entity (es_space)**
   - Display name: Space
   - Plural name: Spaces
   - Primary column: Space Name
   - Enable: Notes, Activities, Auditing, Business Process Flows
   
   c. **Reservation Entity (es_reservation)**
   - Display name: Reservation
   - Plural name: Reservations
   - Primary column: Reservation Name
   - Enable: Notes, Activities, Auditing, Queues, Business Process Flows

4. **Add Fields to Entities**
   
   Use the entity XML files in `solution/entities/` as reference for field names and types.

### Step 4: Import Model-Driven App

1. **In Power Apps, create new Model-driven app**
   - Click "Apps" → "New app" → "Model-driven"
   - Name: Easy Spaces Management
   - Description: Event space management application

2. **Import Site Map**
   - In app designer, click "Site Map"
   - Import the configuration from `model-driven-app/sitemap.xml`
   - This creates the navigation structure

3. **Configure Forms**
   - For each entity, customize the main form
   - Use the form configurations in `model-driven-app/forms/` as templates
   - Arrange fields according to the XML layouts

4. **Publish the Model-driven App**

### Step 5: Import Canvas App

1. **Import Canvas App Package**
   - In Power Apps, click "Apps" → "Import canvas app"
   - Browse to `canvas-app/EasySpacesCanvas.json`
   - Name: Easy Spaces Canvas
   - Click Import

2. **Configure Data Connections**
   - Open the app in Power Apps Studio
   - Go to "Data" panel
   - Add connections to:
     - Dataverse (for custom entities)
     - Office 365 Users (for user info)
     - Office 365 Outlook (for email notifications)

3. **Update Formulas**
   - Review and update any formulas that reference entity names
   - Ensure all gallery items bind correctly to Dataverse tables

4. **Publish Canvas App**

### Step 6: Import Power Automate Flows

**Important Note about Predictive Features:**
The predictive demand and booking rate features are implemented using Power Automate calculations based on historical data patterns. While the original Salesforce app uses Einstein Analytics, our Dynamics 365 version achieves similar functionality through:
- Power Automate flows that analyze reservation patterns
- Calculated fields that determine demand levels
- Trend analysis based on 30-day rolling windows
- No AI Builder required - works with standard Power Automate license

### Step 6a: Configure Power Automate Flows

1. **Navigate to Power Automate**
   ```
   https://make.powerautomate.com/
   ```

2. **Import Reservation Approval Flow**
   - Click "My flows" → "Import" → "Import package"
   - Select `power-automate/ReservationApprovalFlow.json`
   - Update connections during import
   - Review trigger conditions
   - Turn on the flow

3. **Import Predictive Demand Flow**
   - Import `power-automate/PredictiveDemandFlow.json`
   - Configure the recurrence schedule as needed
   - Turn on the flow

### Step 7: Import Sample Data

1. **Manual Data Import via UI**
   - Go to your Model-driven app
   - Navigate to each entity (Markets, Spaces)
   - Use "Import from Excel" option
   - Map columns from `data/sample-data.csv`

2. **Alternative: Use Dataverse Web API**
   ```powershell
   # Example for creating a market via API
   $headers = @{
       "Authorization" = "Bearer $token"
       "Content-Type" = "application/json"
       "Prefer" = "return=representation"
   }
   
   $body = @{
       "es_name" = "San Francisco"
       "es_city" = "San Francisco"
       "es_state" = "CA"
       "es_country" = "USA"
   } | ConvertTo-Json
   
   Invoke-RestMethod -Uri "$environmentUrl/api/data/v9.2/es_markets" -Method Post -Headers $headers -Body $body
   ```

### Step 8: Security Configuration

1. **Create Security Roles**
   - Go to Power Platform Admin Center
   - Select your environment → Settings → Security roles
   - Create new role: "Easy Spaces User"
   - Grant permissions:
     - Read/Write/Create on custom entities
     - Read on Contacts and Leads
     - Execute on Workflows

2. **Assign Security Roles**
   - Assign "Easy Spaces User" role to test users
   - Ensure app users have appropriate licenses

### Step 9: Testing

1. **Test Model-driven App**
   - Create a new market
   - Add spaces to the market
   - Create a reservation
   - Verify approval workflow triggers

2. **Test Canvas App**
   - Browse spaces gallery
   - View space details
   - Create new reservation
   - Check customer list functionality

3. **Test Power Automate Flows**
   - Submit a reservation (should trigger approval)
   - Wait for predictive demand flow to run (or run manually)
   - Verify demand predictions update
   - Note: Predictive features work with calculated metrics even without AI Builder

### Step 10: Final Configuration

1. **Configure App Settings**
   - Set default views for entities
   - Configure dashboards
   - Set up email templates for notifications

2. **Mobile Access**
   - Install Dynamics 365 mobile app
   - Sign in with your credentials
   - Verify app accessibility on mobile

## Troubleshooting

### Common Issues and Solutions

1. **Script fails to connect**
   - Ensure you're using the correct environment URL
   - Try using `-UseInteractiveAuth` flag
   - Check firewall/proxy settings

2. **Entities not visible in apps**
   - Refresh metadata in app designer
   - Check security role permissions
   - Ensure entities are added to the solution

3. **Canvas app data not loading**
   - Verify Dataverse connections
   - Check delegation warnings
   - Review filter expressions

4. **Flows not triggering**
   - Ensure flows are turned on
   - Check trigger conditions
   - Review flow run history for errors

5. **Permission errors**
   - Verify user has correct security roles
   - Check entity-level permissions
   - Ensure user has Power Apps/Automate licenses

## App Features Mapping

| Salesforce LWC Feature | Dynamics 365 Implementation |
|------------------------|----------------------------|
| Lightning Console | Model-driven app with sitemap |
| LWC Components | Canvas app screens |
| Apex Controllers | Power Automate flows |
| Custom Objects | Dataverse custom entities |
| Process Builder | Power Automate cloud flows |
| Einstein Analytics | Power Automate calculations (AI Builder optional) |
| Salesforce Flow | Power Automate + Business Process Flows |
| Lightning Page Templates | Model-driven forms + Canvas screens |

## Support Resources

- **Power Apps Documentation**: https://docs.microsoft.com/powerapps/
- **Dataverse Guide**: https://docs.microsoft.com/power-apps/developer/data-platform/
- **Power Automate Reference**: https://docs.microsoft.com/power-automate/
- **Community Forums**: https://powerusers.microsoft.com/

## Next Steps

After successful deployment:

1. **Customize Branding**
   - Update app themes and colors
   - Add company logo
   - Customize email templates

2. **Extend Functionality**
   - Add payment processing
   - Integrate with calendar systems
   - Implement advanced analytics

3. **Production Deployment**
   - Plan data migration strategy
   - Set up staging environment
   - Configure backup and recovery

## License Requirements

For production use, users will need:
- Dynamics 365 Sales/Service license OR
- Power Apps per user/per app license
- Power Automate license (if using premium connectors)

## Conclusion

You've successfully deployed Easy Spaces to Dynamics 365! The application maintains the core functionality and user experience of the original Salesforce LWC app while leveraging the Microsoft Power Platform's capabilities.

For questions or issues, refer to the troubleshooting section or consult Microsoft's official documentation.