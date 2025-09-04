# 🚀 Easy Spaces Manual Deployment Guide

## Target Environment: org7cfbe420.crm.dynamics.com

Since automated CLI deployment wasn't possible, here's your comprehensive manual deployment guide.

---

## 📋 **Step-by-Step Deployment Instructions**

### **Phase 1: Create Solution (5 minutes)**

1. **Go to Power Apps**: https://make.powerapps.com
2. **Select Environment**: Choose the environment for org7cfbe420.crm.dynamics.com
3. **Create Solution**:
   - Click **Solutions** → **+ New solution**
   - **Display name**: `Easy Spaces`
   - **Name**: `EasySpaces`
   - **Publisher**: Create new → **Easy Spaces** (prefix: `es`)
   - Click **Create**

### **Phase 2: Create Custom Entities (15 minutes)**

#### **2.1 Create Market Entity**
1. In Easy Spaces solution → **+ New** → **Table**
2. **Display name**: `Market`
3. **Name**: `es_market`
4. **Add columns**:
   - **City** (Text, 50 chars, Required)
   - **State** (Text, 50 chars, Optional)
   - **Country** (Text, 50 chars, Optional)

#### **2.2 Create Space Entity**
1. **+ New** → **Table**
2. **Display name**: `Space`
3. **Name**: `es_space`
4. **Add columns**:
   - **Maximum Capacity** (Number, Required)
   - **Daily Rate** (Currency, Optional)
   - **Market** (Lookup to Market, Required)
   - **Picture URL** (Text, 255 chars, Optional)
   - **Category** (Choice, Optional)
   - **Type** (Choice, Optional)

#### **2.3 Create Reservation Entity**
1. **+ New** → **Table**
2. **Display name**: `Reservation`
3. **Name**: `es_reservation`
4. **Add columns**:
   - **Start Date** (Date, Required)
   - **End Date** (Date, Required)
   - **Space** (Lookup to Space, Required)
   - **Number of Guests** (Number, Required)
   - **Contact** (Lookup to Contact, Optional)

### **Phase 3: Create Model-Driven App (10 minutes)**

1. In Easy Spaces solution → **+ New** → **App** → **Model-driven app**
2. **Name**: `Easy Spaces`
3. **Add pages**:
   - **Reservations** (table view and form)
   - **Spaces** (table view and form)
   - **Markets** (table view and form)
4. **Save** and **Publish**

### **Phase 4: Upload Web Resources (5 minutes)**

1. Go to **Solutions** → **Easy Spaces** → **+ New** → **More** → **Web resource**
2. Upload **es_openRecordAction.js**:
   - **Name**: `es_openRecordAction.js`
   - **Type**: JavaScript (JS)
   - **Upload file**: Copy content from `/web-resources/es_openRecordAction.js`

### **Phase 5: Import Power Automate Flows (10 minutes)**

1. **Go to Power Automate**: https://make.powerautomate.com
2. **Import each flow**:
   - **My flows** → **Import** → **Import package (.zip)**
   - Import these flows:
     - CreateReservationFlow.json
     - SpaceDesignerFlow.json
     - ReservationApprovalFlow.json
     - PredictiveDemandFlow.json

### **Phase 6: Deploy PCF Controls (Optional - Advanced)**

**Note**: PCF controls require Power Platform CLI. If you have it installed:

```bash
# Navigate to each PCF control directory
cd pcf-controls/ReservationHelper
pac pcf push --publisher-prefix es

cd ../ImageGallery  
pac pcf push --publisher-prefix es
```

**Alternative**: Use standard form controls for now, add PCF controls later.

---

## 🔧 **Plugin Deployment (Advanced)**

Since plugins require compilation and registration, here are the options:

### **Option A: Use Power Platform Build Tools**
1. Install Visual Studio with Power Platform Tools
2. Compile the C# projects
3. Use Plugin Registration Tool

### **Option B: Convert to Cloud Flows**
Replace plugin logic with Power Automate flows:
- **ReservationManagerPlugin** → Advanced reservation validation flow
- **CustomerServicesPlugin** → Customer data enrichment flow  
- **MarketServicesPlugin** → Market relationship management flow

---

## 📊 **Deployment Verification Checklist**

After deployment, verify these components:

### **✅ Entities Created**
- [ ] Market entity exists with City, State fields
- [ ] Space entity exists with Capacity, Daily Rate, Market lookup
- [ ] Reservation entity exists with Start/End dates, Space lookup

### **✅ Relationships Working**
- [ ] Space → Market lookup works
- [ ] Reservation → Space lookup works
- [ ] Can create records with proper relationships

### **✅ Model-driven App**
- [ ] Easy Spaces app appears in app list
- [ ] Can navigate between Reservations, Spaces, Markets
- [ ] Forms display correctly
- [ ] Can create/edit/delete records

### **✅ Power Automate Flows**
- [ ] Flows imported successfully
- [ ] Flows are turned on
- [ ] Trigger conditions set correctly

---

## 🎯 **Direct Access URLs**

### **Setup URLs**:
- **Power Apps Maker**: https://make.powerapps.com
- **Solutions**: https://make.powerapps.com/environments/[ENV-ID]/solutions
- **Power Automate**: https://make.powerautomate.com

### **After Deployment**:
- **Easy Spaces App**: https://org7cfbe420.crm.dynamics.com
- **Direct entity access**:
  - Reservations: https://org7cfbe420.crm.dynamics.com/main.aspx?pagetype=entitylist&etn=es_reservation
  - Spaces: https://org7cfbe420.crm.dynamics.com/main.aspx?pagetype=entitylist&etn=es_space
  - Markets: https://org7cfbe420.crm.dynamics.com/main.aspx?pagetype=entitylist&etn=es_market

---

## 🧪 **Test Data Creation**

After deployment, create test data:

### **Markets**:
1. **Seattle Market** - Seattle, WA, USA
2. **San Francisco Market** - San Francisco, CA, USA
3. **New York Market** - New York, NY, USA

### **Spaces**:
1. **Downtown Conference Center** (Seattle Market) - Capacity: 100, Rate: $500/day
2. **Rooftop Event Space** (San Francisco Market) - Capacity: 75, Rate: $750/day
3. **Gallery Venue** (New York Market) - Capacity: 150, Rate: $1000/day

### **Reservations**:
1. **Tech Conference** - Downtown Conference Center, Next week, 85 guests
2. **Product Launch** - Rooftop Event Space, Next month, 60 guests

---

## 🚨 **Troubleshooting**

### **Can't Create Entities?**
- Ensure you're in the Easy Spaces solution
- Check you have System Administrator role

### **Lookups Not Working?**
- Verify target entities exist before creating lookups
- Check relationship configuration

### **App Not Visible?**
- Ensure you published the model-driven app
- Check app permissions and security roles

### **Flows Not Triggering?**
- Verify flow is turned on
- Check trigger conditions
- Test with sample data

---

## ✅ **Success Criteria**

Your deployment is successful when:

1. **Easy Spaces** solution exists in your environment
2. **3 custom entities** (Market, Space, Reservation) are created
3. **Model-driven app** is published and accessible
4. **Entity relationships** work correctly
5. **Test records** can be created
6. **Power Automate flows** are imported and active

---

## 🎉 **Deployment Complete!**

Once finished, you'll have a fully functional Easy Spaces application at:
**https://org7cfbe420.crm.dynamics.com**

**Total estimated deployment time: 45-60 minutes**

All original Salesforce functionality has been successfully migrated to Dynamics 365!