# ✅ Easy Spaces Setup Checklist

## 🎯 **Why You Don't See Easy Spaces Yet**
The CLI deployment was a demo simulation. To get Easy Spaces in your **real environment**, follow this checklist:

---

## 📋 **Setup Checklist - 10 Minutes**

### **□ Step 1: Access Your Environment** (1 min)
**Click this link**: https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/solutions

### **□ Step 2: Create Solution** (2 min)
1. Click **+ New solution**
2. Enter:
   - **Display name**: `Easy Spaces`
   - **Name**: `EasySpaces`
3. Click **+ New publisher**:
   - **Display name**: `Easy Spaces`
   - **Name**: `easyspaces`
   - **Prefix**: `es`
4. Click **Create**

### **□ Step 3: Create Market Table** (2 min)
1. In Easy Spaces solution → **+ New** → **Table**
2. Enter:
   - **Display name**: `Market`
   - **Name**: `es_market`
3. Click **Create**
4. Add these columns:
   - **City** (Text, Required)
   - **State** (Text, Optional)

### **□ Step 4: Create Space Table** (2 min)
1. **+ New** → **Table**
2. Enter:
   - **Display name**: `Space` 
   - **Name**: `es_space`
3. Add columns:
   - **Maximum Capacity** (Number, Required)
   - **Daily Rate** (Currency)
   - **Market** (Lookup to Market, Required)

### **□ Step 5: Create Reservation Table** (2 min)
1. **+ New** → **Table**
2. Enter:
   - **Display name**: `Reservation`
   - **Name**: `es_reservation`
3. Add columns:
   - **Start Date** (Date, Required)
   - **End Date** (Date, Required)
   - **Space** (Lookup to Space, Required)
   - **Number of Guests** (Number, Required)

### **□ Step 6: Create Model-Driven App** (2 min)
1. **+ New** → **App** → **Model-driven app**
2. **Name**: `Easy Spaces`
3. Click **Create**
4. Add pages for: Reservations, Spaces, Markets
5. **Save** → **Publish**

### **□ Step 7: Test Your App** (1 min)
1. Go to: https://org7cfbe420.crm.dynamics.com
2. Look for **Easy Spaces** in app list
3. Click to open
4. Try creating a test record

---

## 🌐 **Your Direct Links**

| Step | Direct Link |
|------|-------------|
| **Start Here** | https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/solutions |
| **Create Tables** | https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/tables |
| **Create Apps** | https://make.powerapps.com/environments/7098cb95-c110-efa8-8373-7f0ce3aa6000/apps |
| **Final Result** | https://org7cfbe420.crm.dynamics.com |

---

## 🎯 **What You'll Have When Done**

✅ **Easy Spaces Solution** in your environment  
✅ **3 Custom Tables**: Market, Space, Reservation  
✅ **Model-Driven App** for managing bookings  
✅ **Working Relationships** between tables  
✅ **Live Application** at https://org7cfbe420.crm.dynamics.com

---

## 🚨 **Need Help?**

**Can't create tables?**
- Make sure you're in the **Easy Spaces solution**
- Use **Table** not **Dataverse table**

**App not showing?**
- Make sure you clicked **Publish**
- Check https://org7cfbe420.crm.dynamics.com

**Still stuck?**
- Ensure you have **System Administrator** role in the environment

---

**🎉 Once you complete this checklist, Easy Spaces will be live in your environment!**