# Easy Spaces - Component Setup Instructions

## Overview
The Easy Spaces solution includes entities, relationships, and sample data that are automatically deployed. However, Canvas Apps and Power Automate flows must be created manually through the Power Platform makers portal.

## ✅ Already Deployed Components
- **Entities**: Market, Space, Reservation
- **Relationships**: Market→Space, Space→Reservation
- **Sample Data**: 3 Markets, 4 Spaces

## 📱 Canvas App Setup

### Step 1: Create Canvas App
1. Go to https://make.powerapps.com/
2. Click **+ Create** → **Canvas app** → **Blank app**
3. Name it: "Easy Spaces Booking App"
4. Choose **Phone** format

### Step 2: Add Data Sources
1. Click **Data** in the left panel
2. Add these tables:
   - es_market (Markets)
   - es_space (Spaces)
   - es_reservation (Reservations)

### Step 3: Create Screens
Use the template in `components/CanvasApp.json` to create:

#### Home Screen (Browse Markets)
- Add Gallery control
- Set Items: `SortByColumns(es_markets, "es_name", Ascending)`
- Add labels for market name and city
- OnSelect: Navigate to Spaces screen

#### Spaces Screen (View Spaces)
- Add Gallery control
- Set Items: `Filter(es_spaces, es_marketid.es_marketid = SelectedMarket.es_marketid)`
- Add labels for space name and capacity
- Add "Book Space" button

#### Booking Screen (Create Reservation)
- Add DatePickers for start/end dates
- Add TextInput for reservation name
- Add "Create Reservation" button with:
```powerfx
Patch(es_reservations, Defaults(es_reservations), {
    es_name: ReservationNameInput.Text,
    es_spaceid: SelectedSpace,
    es_startdate: StartDatePicker.SelectedDate,
    es_enddate: EndDatePicker.SelectedDate
})
```

#### Confirmation Screen
- Add success icon and message
- Add "Return to Home" button

### Step 4: Publish App
1. Click **File** → **Save**
2. Click **Publish**
3. Share with users

## ⚡ Power Automate Flows Setup

### Flow 1: Send Reservation Confirmation
1. Go to https://make.powerautomate.com/
2. Click **+ Create** → **Automated cloud flow**
3. Name: "Send Reservation Confirmation"
4. Trigger: When a row is added (Dataverse) - es_reservations
5. Actions:
   - Get space details (es_spaces)
   - Get market details (es_markets)
   - Send email with reservation details

### Flow 2: Check Space Availability
1. Create **Instant cloud flow**
2. Trigger: When HTTP request is received
3. Actions:
   - List overlapping reservations
   - Check if any exist
   - Return JSON response with availability

### Flow 3: Daily Reservation Report
1. Create **Scheduled cloud flow**
2. Trigger: Daily at 9:00 AM
3. Actions:
   - List today's reservations
   - Create HTML table
   - Send email report

### Flow 4: Capacity Alert
1. Create **Scheduled cloud flow**
2. Trigger: Every 4 hours
3. Actions:
   - List all spaces
   - For each space, count active reservations
   - If >80% capacity, send alert

## 🎯 Model-Driven App Setup

### Step 1: Create Model-Driven App
1. In Power Apps, click **+ Create** → **Model-driven app**
2. Name: "Easy Spaces Management"
3. Add existing tables:
   - Markets
   - Spaces
   - Reservations

### Step 2: Configure Site Map
1. Add Groups:
   - **Locations**: Markets, Spaces
   - **Bookings**: Reservations
   - **Reports**: Dashboards

### Step 3: Create Forms
1. For each entity, create:
   - Main form for editing
   - Quick view form for lookups
   - Card form for mobile

### Step 4: Create Views
1. Markets: All Markets, Active Markets
2. Spaces: All Spaces, Available Spaces, By Market
3. Reservations: All Reservations, Today's Reservations, Upcoming

### Step 5: Create Dashboard
1. Add components:
   - Reservations by Market (chart)
   - Space Utilization (chart)
   - Recent Reservations (list)
   - Upcoming Reservations (calendar)

## 📦 Adding Components to Solution

### Export with Components
1. Go to Solutions
2. Open "EasySpacesSolutionProper"
3. Click **Add existing** → **App** → **Canvas app**
4. Select "Easy Spaces Booking App"
5. Click **Add existing** → **Automation** → **Cloud flow**
6. Select all 4 flows
7. Click **Export** → **As unmanaged**

## 🚀 Deployment via GitHub Actions
Once all components are added:
1. Export the complete solution
2. Replace `out/EasySpacesSolution.zip`
3. Commit and push to GitHub
4. GitHub Actions will deploy automatically

## 📝 Notes
- Canvas Apps and Power Automate flows cannot be created programmatically
- They must be built using the visual designers
- Once created, they can be added to the solution and exported
- The exported solution can then be version controlled and deployed via CI/CD

## 🆘 Support
For issues or questions, refer to:
- [Power Apps Documentation](https://docs.microsoft.com/powerapps/)
- [Power Automate Documentation](https://docs.microsoft.com/power-automate/)
- [GitHub Repository Issues](https://github.com/eliotng/easy-spaces-dynamics365/issues)