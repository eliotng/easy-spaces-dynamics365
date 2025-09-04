# Easy Spaces for Microsoft Dynamics 365

A complete conversion of the Salesforce Easy Spaces LWC sample application to Microsoft Dynamics 365 and Power Platform.

## Overview

Easy Spaces is a fictional event management company that creates and manages custom pop-up spaces for companies and individuals. This application helps customers create temporary spaces like cafés, game rooms, or themed rooms for special occasions in their offices and homes.

This repository contains the Microsoft Dynamics 365 version of the application, maintaining the same functionality and user experience as the original Salesforce LWC app.

## Features

### Core Functionality
- **Space Management**: Browse and manage various types of event spaces
- **Reservation System**: Create and manage space reservations
- **Customer Management**: Track leads, contacts, and accounts
- **Market Analytics**: View market-wise space availability and pricing
- **Predictive Analytics**: AI-powered demand forecasting and booking rate predictions

### Technical Components
- **Model-Driven App**: Administrative interface for managing spaces and reservations
- **Canvas App**: Customer-facing interface with modern UI matching the original LWC design
- **Power Automate Flows**: Automated business processes for reservation approval and predictive analytics
- **Custom Entities**: Market, Space, and Reservation entities in Dataverse
- **Security Roles**: Configurable access control for different user types

## Project Structure

```
easy-spaces-dynamics365/
├── solution/               # Solution configuration files
│   ├── solution.xml       # Main solution manifest
│   └── entities/          # Entity definitions
│       ├── Market.xml
│       ├── Space.xml
│       └── Reservation.xml
├── model-driven-app/      # Model-driven app components
│   ├── sitemap.xml       # Navigation structure
│   └── forms/            # Form configurations
├── canvas-app/           # Canvas app configuration
│   └── EasySpacesCanvas.json
├── power-automate/       # Business automation flows
│   ├── ReservationApprovalFlow.json
│   └── PredictiveDemandFlow.json
├── data/                 # Sample data
│   └── sample-data.csv
├── scripts/              # Deployment scripts
│   └── Deploy-EasySpaces.ps1
├── documentation/        # Additional documentation
├── DEPLOYMENT_GUIDE.md   # Step-by-step deployment instructions
└── README.md            # This file
```

## Quick Start

### Prerequisites
1. Microsoft Dynamics 365 trial account (free)
2. Power Platform access (included with trial)
3. GitHub account with repository access

### 🚀 **Automated Deployment Status**

✅ **Successfully Deployed Components:**
- **Custom Entities**: Market, Space, Reservation with relationships
- **Sample Data**: 3 Markets, 4 Spaces pre-loaded
- **GitHub Actions CI/CD**: Automatic deployment on push
- **Service Principal**: OAuth authentication configured

📝 **Components Ready for Manual Creation:**
- **Canvas App**: Definition available, create in Power Apps Studio
- **Power Automate Flows**: 3 flow templates ready

### Deployment Options:

**Option 1: Automated GitHub Actions** ✅ **(Recommended)**
```yaml
# Automatically deploys on push to main branch
# Check status at: https://github.com/eliotng/easy-spaces-dynamics365/actions
```

**Option 2: Manual Import**
```bash
# Import the exported solution
pac solution import --path out/EasySpacesSolution.zip
```

**Option 3: Web Interface**
1. Go to https://make.powerapps.com/
2. Navigate to Solutions
3. Import `out/EasySpacesSolution.zip`

### Current Environment
- **URL**: https://org7cfbe420.crm.dynamics.com
- **Solution**: EasySpacesSolutionProper

## Technology Stack

### Microsoft Power Platform
- **Dataverse**: Data storage and management
- **Power Apps**: Model-driven and Canvas applications
- **Power Automate**: Business process automation
- **AI Builder**: Predictive analytics (optional)

### Comparable Technologies
| Salesforce | Microsoft Dynamics 365 |
|------------|----------------------|
| Lightning Web Components | Canvas Apps |
| Apex | Power Automate |
| Custom Objects | Dataverse Entities |
| Process Builder | Power Automate Flows |
| Lightning Console | Model-Driven Apps |

## Key Differences from Original

While maintaining functional parity, some implementation differences exist:

1. **UI Framework**: Canvas Apps instead of Lightning Web Components
2. **Business Logic**: Power Automate flows instead of Apex code
3. **Data Model**: Dataverse entities instead of Salesforce objects
4. **Security**: Azure AD-based authentication instead of Salesforce auth

## Screenshots

The application maintains the visual design and workflow of the original Easy Spaces app:

- **Home Screen**: Gallery view of available spaces
- **Space Details**: Detailed information with reservation capability
- **Reservation Form**: Intuitive booking interface
- **Customer Management**: Unified view of leads and contacts
- **Analytics Dashboard**: Market trends and predictions

## Development & Customization

### Extending the Application
1. **Add New Entities**: Use Power Apps to create additional Dataverse entities
2. **Customize UI**: Edit Canvas app in Power Apps Studio
3. **Add Business Logic**: Create new Power Automate flows
4. **Enhance Analytics**: Integrate with Power BI for advanced reporting

### Best Practices
- Always work in a development environment first
- Use solutions for deployment between environments
- Follow Microsoft's ALM practices for Power Platform
- Maintain security role separation

## Support & Resources

### Documentation
- [Power Apps Documentation](https://docs.microsoft.com/powerapps/)
- [Dataverse Developer Guide](https://docs.microsoft.com/power-apps/developer/data-platform/)
- [Power Automate Reference](https://docs.microsoft.com/power-automate/)

### Community
- [Power Platform Community](https://powerusers.microsoft.com/)
- [Microsoft Learn](https://learn.microsoft.com/power-platform/)

## License

This conversion is provided as a learning resource and demonstration of platform migration capabilities. Please ensure you have appropriate licenses for production use:

- Dynamics 365 Sales/Service license
- Power Apps per user/per app license
- Power Automate license (for premium features)

## Acknowledgments

This project is based on the original [Easy Spaces LWC](https://github.com/trailheadapps/easy-spaces-lwc) sample application by Salesforce Trailhead.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the conversion.

## Contact

For questions or support regarding this conversion, please open an issue in this repository.