# 🚀 Easy Spaces Setup for YOUR Environment

## 🌐 **Your Environment Details**
- **Environment ID**: 7098cb95-c110-efa8-8373-7f0ce3aa6000
- **Dynamics 365 URL**: https://org7cfbe420.crm.dynamics.com
- **Power Apps Maker**: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000

---

## ⚡ **Quick 10-Minute Setup**

### **Step 1: Create Solution (2 minutes)**
1. **Go to**: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/solutions
2. Click **+ New solution**
3. **Display name**: `Easy Spaces`
4. **Name**: `EasySpaces`
5. **Publisher**: Click **+ New publisher**
   - **Display name**: `Easy Spaces`
   - **Name**: `easyspaces` 
   - **Prefix**: `es`
   - **Choice value prefix**: `10000`
6. Click **Create**

### **Step 2: Create Market Entity (2 minutes)**
1. In Easy Spaces solution → **+ New** → **Table**
2. **Display name**: `Market`
3. **Plural name**: `Markets`
4. **Name**: `es_market`
5. Click **Create**
6. Add columns:
   - **City** (Text, 50 chars, Required)
   - **State** (Text, 50 chars, Optional)

### **Step 3: Create Space Entity (3 minutes)**
1. **+ New** → **Table**
2. **Display name**: `Space`
3. **Plural name**: `Spaces`
4. **Name**: `es_space`
5. Add columns:
   - **Maximum Capacity** (Number, Required, Min: 1, Max: 10000)
   - **Daily Rate** (Currency, Optional)
   - **Market** (Lookup to Market, Required)

### **Step 4: Create Reservation Entity (3 minutes)**  
1. **+ New** → **Table**
2. **Display name**: `Reservation`
3. **Plural name**: `Reservations`
4. **Name**: `es_reservation`
5. Add columns:
   - **Start Date** (Date, Required)
   - **End Date** (Date, Required)
   - **Space** (Lookup to Space, Required)
   - **Number of Guests** (Number, Required, Min: 1)

### **Step 5: Create App (2 minutes)**
1. **+ New** → **App** → **Model-driven app**
2. **Name**: `Easy Spaces`
3. Click **Create**
4. **Add pages**:
   - **Reservations** (table-based view and form)
   - **Spaces** (table-based view and form)
   - **Markets** (table-based view and form)
5. **Save** → **Publish**

---

## 🎯 **Direct Access Links for Your Environment**

### **Setup Links:**
- **Solutions**: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/solutions
- **Tables**: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/tables
- **Apps**: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/apps

### **After Setup:**
- **Easy Spaces App**: https://org7cfbe420.crm.dynamics.com (look for Easy Spaces in app list)
- **Reservations**: https://org7cfbe420.crm.dynamics.com/main.aspx?pagetype=entitylist&etn=es_reservation
- **Spaces**: https://org7cfbe420.crm.dynamics.com/main.aspx?pagetype=entitylist&etn=es_space
- **Markets**: https://org7cfbe420.crm.dynamics.com/main.aspx?pagetype=entitylist&etn=es_market

---

## 📊 **Test Data to Add**

After creating entities, add this test data:

### **Markets:**
1. **Seattle Market** - Seattle, WA
2. **San Francisco Market** - San Francisco, CA
3. **New York Market** - New York, NY

### **Spaces:**
1. **Downtown Conference Center** (Seattle Market) - Capacity: 100, Rate: $500/day
2. **Rooftop Event Space** (San Francisco Market) - Capacity: 75, Rate: $750/day
3. **Gallery Venue** (New York Market) - Capacity: 150, Rate: $1000/day

### **Reservations:**
1. **Tech Conference** - Downtown Conference Center, Next week, 85 guests
2. **Product Launch** - Rooftop Event Space, Next month, 60 guests

---

## ✅ **Verification Steps**

After setup, verify:
- [ ] Easy Spaces solution exists
- [ ] Three entities (Market, Space, Reservation) created
- [ ] Model-driven app published and visible
- [ ] Can create test records
- [ ] Lookups work (Space → Market, Reservation → Space)
- [ ] App appears in https://org7cfbe420.crm.dynamics.com

---

## 🚨 **If You Need Help**

### **Stuck on Entity Creation?**
- Make sure you're in the **Easy Spaces** solution when creating tables
- Use the **Table** option, not the **Dataverse table** option

### **App Not Showing?**
- Make sure you clicked **Publish** after creating the app
- Go directly to: https://org7cfbe420.crm.dynamics.com and look for "Easy Spaces" in the app switcher

### **Can't Create Records?**
- Check that you have **System Administrator** or **System Customizer** role
- Make sure all required fields are filled

---

## 🎉 **Success!**

When complete, you'll have:
- ✅ **Easy Spaces solution** in your environment
- ✅ **3 custom entities** with proper relationships
- ✅ **Model-driven app** for managing reservations
- ✅ **Working data model** ready for reservations

**Total setup time: 10-15 minutes**

**Your Easy Spaces app will be live at**: https://org7cfbe420.crm.dynamics.com