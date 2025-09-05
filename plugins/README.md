# Easy Spaces C# Plugins

This directory contains the C# plugins for the Easy Spaces Dynamics 365 solution.

## 📁 Plugin Structure

```
plugins/
├── EasySpacesPlugins.sln          # Visual Studio Solution file
├── build-plugins.sh               # Build script for all plugins
├── EasySpaces.snk                 # Strong name key file (for signing)
├── ReservationManager/
│   ├── EasySpaces.ReservationManager.csproj
│   ├── ReservationManagerPlugin.cs
│   └── EasySpaces.snk
├── CustomerServices/
│   ├── EasySpaces.CustomerServices.csproj
│   ├── CustomerServicesPlugin.cs
│   └── EasySpaces.snk
└── MarketServices/
    ├── EasySpaces.MarketServices.csproj
    ├── MarketServicesPlugin.cs
    └── EasySpaces.snk
```

## 🔧 Building the Plugins

### Prerequisites
- .NET Framework 4.6.2 or higher
- .NET Core SDK 9.0 or higher

### Quick Build
```bash
./build-plugins.sh
```

### Manual Build
```bash
# Restore packages
dotnet restore EasySpacesPlugins.sln

# Build all plugins
dotnet build EasySpacesPlugins.sln --configuration Release
```

### Build Individual Plugin
```bash
cd ReservationManager
dotnet build --configuration Release
```

## 📦 Output Files

After building, the compiled assemblies will be located at:

- `ReservationManager/bin/Release/net462/EasySpaces.ReservationManager.dll`
- `CustomerServices/bin/Release/net462/EasySpaces.CustomerServices.dll`
- `MarketServices/bin/Release/net462/EasySpaces.MarketServices.dll`

## 🚀 Deployment

These DLL files need to be registered in your Dynamics 365 environment:

1. **Upload to Dynamics 365:**
   - Go to Settings → Customizations → Plug-in Assemblies
   - Upload each .dll file
   
2. **Register Plugin Steps:**
   - Use the Plugin Registration Tool
   - Register the appropriate steps for each plugin

## 📝 Plugin Descriptions

### ReservationManager
- **Purpose:** Manages space reservations and availability
- **Replaces:** Salesforce Apex ReservationManager class
- **Triggers:** Create/Update on Reservation entity

### CustomerServices  
- **Purpose:** Handles customer service operations
- **Replaces:** Salesforce CustomerServices.cls
- **Triggers:** Create/Update on Customer-related entities

### MarketServices
- **Purpose:** Manages market and venue operations  
- **Replaces:** Salesforce MarketServices functionality
- **Triggers:** Create/Update on Market entity

## 🔐 Code Signing

The plugins are currently built without strong name signing for development. For production deployment:

1. Generate a proper strong name key:
   ```bash
   sn -k EasySpaces.snk
   ```

2. Uncomment the signing lines in each .csproj file:
   ```xml
   <SignAssembly>true</SignAssembly>
   <AssemblyOriginatorKeyFile>EasySpaces.snk</AssemblyOriginatorKeyFile>
   ```

## 🔍 Dependencies

Each plugin references the following NuGet packages:
- Microsoft.CrmSdk.CoreAssemblies (9.0.2.46)
- Microsoft.CrmSdk.Workflow (9.0.2.46)  
- Microsoft.CrmSdk.XrmTooling.CoreAssembly (9.1.1.1)
