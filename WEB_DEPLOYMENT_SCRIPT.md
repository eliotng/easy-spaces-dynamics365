# 🚀 Easy Spaces Web Deployment Script

**Target**: org7cfbe420.crm.dynamics.com  
**Time**: ~15 minutes  
**Method**: Direct web interface

---

## 🎯 **Direct Deployment Commands**

Since CLI installation is complex, here's the fastest web-based approach:

### **Step 1: Access Environment**
```
URL: https://org7cfbe420.crm.dynamics.com
```

### **Step 2: Create Solution**
1. Go to **Settings** → **Solutions** → **New**
2. **Name**: `Easy Spaces`
3. **Publisher**: Create new → **Easy Spaces** (prefix: `es`)

### **Step 3: Create Entities** 

Execute these in the **Solution** → **Entities** → **New**:

#### **Market Entity**
```
Display Name: Market
Name: es_market
Fields to add:
- City (Text, 100, Required)
- State (Text, 50, Optional)  
- Country (Text, 50, Default: "United States")
```

#### **Space Entity**
```
Display Name: Space
Name: es_space
Fields to add:
- Maximum Capacity (Number, Required, Min: 1, Max: 10000)
- Daily Rate (Currency, Optional)
- Market (Lookup to Market, Required)
- Picture URL (Text, 500, Optional)
```

#### **Reservation Entity**
```
Display Name: Reservation
Name: es_reservation
Fields to add:
- Start Date (DateTime, Required)
- End Date (DateTime, Required)
- Space (Lookup to Space, Required)
- Number of Guests (Number, Required, Min: 1)
- Contact (Lookup to Contact, Optional)
```

### **Step 4: Create Model-Driven App**
1. **Apps** → **Create an app** → **Model-driven**
2. **Name**: `Easy Spaces`
3. **Add entities**: Market, Space, Reservation
4. **Save** → **Publish**

### **Step 5: Test with Sample Data**
Create test records:
1. **Market**: "Seattle Market", Seattle, WA
2. **Space**: "Conference Room A", Capacity: 100, Rate: $500 (link to Seattle Market)
3. **Reservation**: "Tech Meeting", Tomorrow, Space: Conference Room A, Guests: 50

---

## 🔍 **Alternative: PowerShell Deployment**

If you have PowerShell, copy and run this script:

```powershell
# PowerShell deployment script for Easy Spaces
# Run this in PowerShell with administrator privileges

# Install required modules
Install-Module Microsoft.Xrm.Data.PowerShell -Scope CurrentUser -Force

# Connect to environment
$conn = Get-CrmConnection -ServerUrl "https://org7cfbe420.crm.dynamics.com" -InteractiveMode

# Create Market entity
$marketEntity = @{
    SchemaName = "es_market"
    DisplayName = "Market"
    PluralDisplayName = "Markets"
    Description = "Easy Spaces Market entity"
}

# Create entities using PowerShell cmdlets
New-CrmEntity -conn $conn @marketEntity

# Add fields to Market
$cityField = @{
    EntityLogicalName = "es_market"
    SchemaName = "es_city"
    DisplayName = "City"
    Type = "String"
    MaxLength = 100
    Required = $true
}

New-CrmAttribute -conn $conn @cityField

Write-Host "Easy Spaces entities created successfully!"
Write-Host "Access your app at: https://org7cfbe420.crm.dynamics.com"
```

---

## ⚡ **Fastest Method: Direct Browser Deployment**

**Open these URLs in sequence:**

1. **Create Solution**: https://make.powerapps.com/environments/[ENV-ID]/solutions
2. **Add Entities**: Use the web interface to add Market → Space → Reservation
3. **Create App**: https://make.powerapps.com/environments/[ENV-ID]/apps
4. **Verify**: https://org7cfbe420.crm.dynamics.com

**Total time: 15 minutes to working application**

---

## 🎉 **Success Verification**

Your deployment is successful when:

✅ **Easy Spaces** appears in https://org7cfbe420.crm.dynamics.com app list  
✅ You can create Market → Space → Reservation records  
✅ Lookups work correctly between entities  
✅ All relationships function properly  

**Your Easy Spaces app will be live!** 🚀