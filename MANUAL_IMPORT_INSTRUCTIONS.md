# 🔧 Manual Import Instructions - Easy Spaces to Your Environment

## Why You Don't See Easy Spaces Yet

The previous deployment was a **simulation demo**. To actually get Easy Spaces in your environment, you need to **manually create the entities** since we can't directly import solutions through CLI without proper authentication and solution packages.

## 📋 **Step-by-Step Manual Creation**

### **Step 1: Access Your Environment**
1. Go to: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000
2. Click **Solutions** in the left navigation
3. Click **+ New solution**

### **Step 2: Create Solution**
1. **Display name**: Easy Spaces
2. **Name**: EasySpaces  
3. **Publisher**: Click **+ New publisher**
   - **Display name**: Easy Spaces
   - **Name**: easyspaces
   - **Prefix**: es
   - **Choice value prefix**: 10000
4. **Version**: 1.0.0.0
5. Click **Create**

### **Step 3: Create Market Entity**
1. In your Easy Spaces solution, click **+ New** → **Table**
2. **Table properties**:
   - **Display name**: Market
   - **Plural name**: Markets
   - **Name**: es_market
   - **Primary column**: Market Name (es_name)
3. Click **Save**
4. **Add columns**:
   - **City** (Single line of text, 50 characters) - Required
   - **State** (Single line of text, 50 characters) - Optional
   - **Country** (Single line of text, 50 characters) - Optional

### **Step 4: Create Space Entity**
1. Click **+ New** → **Table**
2. **Table properties**:
   - **Display name**: Space
   - **Plural name**: Spaces  
   - **Name**: es_space
   - **Primary column**: Space Name (es_name)
3. **Add columns**:
   - **Maximum Capacity** (Whole number) - Required, Min: 1, Max: 10000
   - **Daily Rate** (Currency) - Optional
   - **Market** (Lookup to Market table) - Required

### **Step 5: Create Reservation Entity**
1. Click **+ New** → **Table**
2. **Table properties**:
   - **Display name**: Reservation
   - **Plural name**: Reservations
   - **Name**: es_reservation  
   - **Primary column**: Reservation Name (es_name)
3. **Add columns**:
   - **Start Date** (Date and time, Date only format) - Required
   - **End Date** (Date and time, Date only format) - Required
   - **Space** (Lookup to Space table) - Required
   - **Total Number of Guests** (Whole number) - Required, Min: 1, Max: 10000
   - **Contact** (Lookup to Contact table) - Optional

### **Step 6: Create Model-Driven App**
1. In your Easy Spaces solution, click **+ New** → **App** → **Model-driven app**
2. **Name**: Easy Spaces
3. **Description**: Event management solution for creating and managing custom pop-up spaces
4. Click **Create**
5. In the app designer:
   - Click **+ Add page** → **Table-based view and form**
   - Select **Reservation** → **Done**
   - Repeat for **Space** and **Market**
6. Click **Save** → **Publish**

### **Step 7: Create Security Roles**
1. In your solution, click **+ New** → **Security** → **Security role**
2. Create **Easy Spaces User** role:
   - **Business Management**: Read, Write, Create for Reservations (User level)
   - **Business Management**: Read for Spaces and Markets (Organization level)
3. Create **Easy Spaces Manager** role:
   - **Business Management**: Full access to all Easy Spaces entities (Organization level)

---

## 🚀 **Alternative: Quick Entity Creation Method**

If you want to create the entities faster:

### **Method 1: Use Power Apps Portal**
1. Go to https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000
2. Click **Tables** in left nav
3. Click **+ New table** for each entity
4. Use the specifications above

### **Method 2: Import from Excel**
1. Create sample data in Excel with these columns:
   **Market**: Market Name, City, State
   **Space**: Space Name, Maximum Capacity, Daily Rate, Market
   **Reservation**: Reservation Name, Start Date, End Date, Space, Guests
2. Use **Get data from Excel** in Power Apps

---

## 📊 **Validate Your Setup**

After creating the entities:

### **✅ Check These Items:**
- [ ] Market entity exists with City/State fields
- [ ] Space entity exists with Capacity and Daily Rate  
- [ ] Reservation entity exists with Start/End dates
- [ ] Relationships work (Space → Market, Reservation → Space)
- [ ] Model-driven app shows all three entities
- [ ] You can create test records in each entity

### **🔍 Test the Application:**
1. Open your **Easy Spaces** app
2. Create a test **Market** (e.g., "Seattle Market")
3. Create a test **Space** (e.g., "Conference Room A") linked to the market
4. Create a test **Reservation** for that space
5. Verify all lookups work correctly

---

## 🎯 **Why This Method Works**

The manual creation ensures:
- ✅ **Proper entity relationships** are established
- ✅ **Security roles** are configured correctly  
- ✅ **Model-driven app** displays all components
- ✅ **You have full control** over the implementation
- ✅ **No import/export issues** with solution packages

---

## 🔧 **Next Steps After Manual Creation**

Once your entities are created:

### **1. Add PCF Controls (Optional)**
- Download Power Platform CLI
- Build the PCF controls from `./pcf-controls/` folder
- Upload to your component library

### **2. Add Business Logic (Optional)**  
- Create plugins using the code from `./plugins/` folder
- Register using Plugin Registration Tool

### **3. Add Automation**
- Import Power Automate flows from `./power-automate/` folder
- Configure connections and activate flows

---

## 🆘 **Troubleshooting**

### **Can't Create Entities?**
- Ensure you're a **System Administrator** in the environment
- Check that the environment has **Dataverse database** enabled

### **Relationships Not Working?**
- Verify lookup columns are created correctly
- Check that target entities exist before creating lookups

### **App Not Visible?**
- Make sure you **published** the model-driven app
- Check that entities are added to the app's site map

---

## ✅ **Success Indicators**

You'll know it worked when:
- ✅ **Easy Spaces** appears in your Apps list
- ✅ You can navigate between **Reservations**, **Spaces**, and **Markets**
- ✅ Creating records works with proper lookups
- ✅ The relationship data flows correctly

---

**🎉 Once you complete these steps, you'll have a fully functional Easy Spaces application in your Dynamics 365 environment!**