#!/bin/bash

# Easy Spaces Dynamics 365 Deployment Script (Bash Version)
# This script helps prepare the Easy Spaces solution for deployment to your Dynamics 365 environment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${2}${1}${NC}"
}

# Function to print header
print_header() {
    echo ""
    print_color "================================" "$MAGENTA"
    print_color " $1" "$MAGENTA"
    print_color "================================" "$MAGENTA"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_color "Checking prerequisites..." "$CYAN"
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_color "curl is not installed. Please install it first." "$RED"
        exit 1
    fi
    
    # Check for jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        print_color "jq is not installed. Installing..." "$YELLOW"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "Please run: sudo apt-get install jq"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Please run: brew install jq"
        fi
        echo "After installing jq, run this script again."
        exit 1
    fi
    
    print_color "Prerequisites check completed." "$GREEN"
}

# Function to validate environment URL
validate_url() {
    if [[ ! "$1" =~ ^https://.*\.dynamics\.com$ ]] && [[ ! "$1" =~ ^https://.*\.crm[0-9]?\.dynamics\.com$ ]]; then
        print_color "Invalid Dynamics 365 URL format. Expected format: https://yourorg.crm.dynamics.com" "$RED"
        return 1
    fi
    return 0
}

# Function to create solution package
create_solution_package() {
    print_color "Creating solution package..." "$CYAN"
    
    # Create a temporary directory for the package
    PACKAGE_DIR="../easy-spaces-solution-package"
    mkdir -p "$PACKAGE_DIR"
    
    # Copy solution files
    cp -r ../solution/* "$PACKAGE_DIR/" 2>/dev/null || true
    cp -r ../model-driven-app "$PACKAGE_DIR/" 2>/dev/null || true
    cp -r ../canvas-app "$PACKAGE_DIR/" 2>/dev/null || true
    cp -r ../power-automate "$PACKAGE_DIR/" 2>/dev/null || true
    cp -r ../data "$PACKAGE_DIR/" 2>/dev/null || true
    
    print_color "Solution package created at: $PACKAGE_DIR" "$GREEN"
}

# Function to generate import instructions
generate_import_instructions() {
    local ENV_URL=$1
    
    print_color "Generating import instructions..." "$CYAN"
    
    cat > ../IMPORT_INSTRUCTIONS.md << 'EOF'
# Easy Spaces - Manual Import Instructions

Since PowerShell is not available in your WSL environment, follow these manual steps to import the solution:

## Step 1: Access Your Dynamics 365 Environment

1. Open your web browser
2. Navigate to your environment URL: `ENV_URL_PLACEHOLDER`
3. Sign in with your credentials

## Step 2: Access Power Apps Maker Portal

1. Go to: https://make.powerapps.com/
2. Select your environment from the top-right dropdown

## Step 3: Create Custom Entities

### Create Market Entity

1. Click "Tables" → "New table"
2. Configure:
   - Display name: `Market`
   - Plural name: `Markets`
   - Primary column: `Market Name`
3. Add columns:
   - `City` (Text)
   - `State` (Text)
   - `Country` (Text)
   - `Total Daily Booking Rate` (Currency)
   - `Predicted Booking Rate` (Decimal)

### Create Space Entity

1. Click "Tables" → "New table"
2. Configure:
   - Display name: `Space`
   - Plural name: `Spaces`
   - Primary column: `Space Name`
3. Add columns:
   - `Type` (Choice: Warehouse, Office, Café, Game Room, Gallery, Rooftop, Theater)
   - `Category` (Choice: Indoor, Outdoor, Hybrid)
   - `Minimum Capacity` (Whole Number)
   - `Maximum Capacity` (Whole Number)
   - `Daily Booking Rate` (Currency)
   - `Picture URL` (Text)
   - `Market` (Lookup to Market)
   - `Predicted Demand` (Choice: Low, Medium, High)
   - `Predicted Booking Rate` (Decimal)

### Create Reservation Entity

1. Click "Tables" → "New table"
2. Configure:
   - Display name: `Reservation`
   - Plural name: `Reservations`
   - Primary column: `Reservation Name`
3. Add columns:
   - `Status` (Choice: Draft, Submitted, Confirmed, Cancelled, Completed)
   - `Start Date` (Date Only)
   - `End Date` (Date Only)
   - `Start Time` (Text)
   - `End Time` (Text)
   - `Total Number of Guests` (Whole Number)
   - `Space` (Lookup to Space)
   - `Market` (Lookup to Market)
   - `Contact` (Lookup to Contact)
   - `Lead` (Lookup to Lead)
   - `Account` (Lookup to Account)

## Step 4: Import Model-Driven App

1. In Power Apps, click "Apps" → "New app" → "Model-driven"
2. Name: `Easy Spaces Management`
3. In the app designer:
   - Add the three custom entities (Market, Space, Reservation)
   - Add standard entities (Account, Contact, Lead)
   - Configure the sitemap using the structure in `model-driven-app/sitemap.xml`
4. Save and publish

## Step 5: Import Canvas App

1. In Power Apps, click "Apps" → "Import canvas app"
2. Select the file: `canvas-app/EasySpacesCanvas.json`
3. Update connections during import
4. Open in Power Apps Studio to verify
5. Publish the app

## Step 6: Import Power Automate Flows

1. Go to https://make.powerautomate.com/
2. Click "My flows" → "Import"
3. Import each flow:
   - `power-automate/ReservationApprovalFlow.json`
   - `power-automate/PredictiveDemandFlow.json`
4. Update connections and activate each flow

## Step 7: Import Sample Data

1. Open the Model-driven app
2. For each entity (Markets, then Spaces), use "Import from Excel"
3. Map columns from `data/sample-data.csv`

## Step 8: Test the Application

1. Open the Canvas app
2. Browse spaces
3. Create a test reservation
4. Verify the approval flow triggers
5. Check that data appears in the Model-driven app

## Troubleshooting

If you encounter issues:
1. Check that all entities have been created with the correct columns
2. Verify that lookups are properly configured
3. Ensure flows are activated
4. Check security roles and permissions
EOF

    # Replace placeholder with actual URL
    sed -i "s|ENV_URL_PLACEHOLDER|$ENV_URL|g" ../IMPORT_INSTRUCTIONS.md
    
    print_color "Import instructions generated at: ../IMPORT_INSTRUCTIONS.md" "$GREEN"
}

# Function to display summary
display_summary() {
    print_header "Deployment Preparation Complete!"
    
    print_color "✓ Solution package created" "$GREEN"
    print_color "✓ Import instructions generated" "$GREEN"
    print_color "✓ All files prepared for manual import" "$GREEN"
    
    echo ""
    print_color "Next Steps:" "$CYAN"
    print_color "1. Open IMPORT_INSTRUCTIONS.md for step-by-step guide" "$WHITE"
    print_color "2. Access your Power Apps maker portal" "$WHITE"
    print_color "3. Follow the manual import process" "$WHITE"
    print_color "4. Import sample data" "$WHITE"
    print_color "5. Test the application" "$WHITE"
    
    echo ""
    print_color "Files to use during import:" "$CYAN"
    print_color "- Entity definitions: solution/entities/*.xml" "$WHITE"
    print_color "- Canvas app: canvas-app/EasySpacesCanvas.json" "$WHITE"
    print_color "- Flows: power-automate/*.json" "$WHITE"
    print_color "- Sample data: data/sample-data.csv" "$WHITE"
}

# Main script execution
main() {
    print_header "Easy Spaces Deployment Script"
    
    # Check prerequisites
    check_prerequisites
    
    # Get environment URL
    read -p "Enter your Dynamics 365 environment URL (e.g., https://yourorg.crm.dynamics.com): " ENV_URL
    
    # Validate URL
    if ! validate_url "$ENV_URL"; then
        exit 1
    fi
    
    print_color "Environment URL: $ENV_URL" "$GREEN"
    
    # Create solution package
    create_solution_package
    
    # Generate import instructions
    generate_import_instructions "$ENV_URL"
    
    # Display summary
    display_summary
}

# Run main function
main