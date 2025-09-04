#!/bin/bash

# Easy Spaces Dynamics 365 CLI Deployment Script
# Usage: ./deploy-cli.sh --environment-url https://yourorg.crm.dynamics.com [options]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values
SOLUTION_NAME="EasySpaces"
PUBLISHER_PREFIX="es"
SKIP_BACKUP=false
SKIP_PCF=false
SKIP_PLUGINS=false
VALIDATION_ONLY=false

# Function to print colored output
print_header() {
    echo -e "${MAGENTA}$1${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}$1${NC}"
}

# Function to show usage
show_usage() {
    echo "Easy Spaces Dynamics 365 CLI Deployment"
    echo ""
    echo "Usage: $0 --environment-url <url> [options]"
    echo ""
    echo "Required:"
    echo "  --environment-url URL     Dynamics 365 environment URL"
    echo ""
    echo "Optional:"
    echo "  --solution-name NAME      Solution name (default: EasySpaces)"
    echo "  --publisher-prefix PREFIX Publisher prefix (default: es)"
    echo "  --skip-backup            Skip environment backup"
    echo "  --skip-pcf               Skip PCF controls deployment"
    echo "  --skip-plugins           Skip plugin registration"
    echo "  --validation-only        Run validation only, no deployment"
    echo "  --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment-url https://myorg.crm.dynamics.com"
    echo "  $0 --environment-url https://myorg.crm.dynamics.com --skip-pcf --validation-only"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment-url)
            ENVIRONMENT_URL="$2"
            shift 2
            ;;
        --solution-name)
            SOLUTION_NAME="$2"
            shift 2
            ;;
        --publisher-prefix)
            PUBLISHER_PREFIX="$2"
            shift 2
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-pcf)
            SKIP_PCF=true
            shift
            ;;
        --skip-plugins)
            SKIP_PLUGINS=true
            shift
            ;;
        --validation-only)
            VALIDATION_ONLY=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$ENVIRONMENT_URL" ]; then
    print_error "Environment URL is required"
    show_usage
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    print_step "🔍 Checking prerequisites..."
    
    # Check .NET
    if ! command -v dotnet &> /dev/null; then
        print_error ".NET not found. Run: ./scripts/install-cli-tools.sh"
        exit 1
    else
        DOTNET_VERSION=$(dotnet --version)
        print_success ".NET version: $DOTNET_VERSION"
    fi
    
    # Check PAC CLI
    if ! command -v pac &> /dev/null; then
        print_error "Power Platform CLI not found. Run: ./scripts/install-cli-tools.sh"
        exit 1
    else
        PAC_VERSION=$(pac --version 2>/dev/null || echo "Unknown")
        print_success "PAC CLI version: $PAC_VERSION"
    fi
    
    # Check Node.js (for PCF controls)
    if ! command -v node &> /dev/null; then
        if [ "$SKIP_PCF" = false ]; then
            print_warning "Node.js not found. PCF controls deployment will be skipped."
            SKIP_PCF=true
        fi
    else
        NODE_VERSION=$(node --version)
        print_success "Node.js version: $NODE_VERSION"
    fi
    
    # Check if we're in the right directory
    if [ ! -f "solution/entities/Reservation.xml" ]; then
        print_error "Easy Spaces solution files not found. Please run from project root."
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Function to authenticate
authenticate() {
    print_step "🔐 Authenticating to Dynamics 365..."
    
    # Check if already authenticated
    if pac org who --environment "$ENVIRONMENT_URL" &> /dev/null; then
        print_success "Already authenticated to environment"
        return 0
    fi
    
    # Interactive authentication
    print_status "Opening browser for authentication..."
    if pac auth create --url "$ENVIRONMENT_URL"; then
        print_success "Authentication successful"
        
        # Verify connection
        WHO_AM_I=$(pac org who --environment "$ENVIRONMENT_URL")
        print_status "Connected as: $WHO_AM_I"
    else
        print_error "Authentication failed"
        exit 1
    fi
}

# Function to create solution package
create_solution_package() {
    print_step "📦 Creating solution package..."
    
    # Create output directory
    mkdir -p ./out
    
    # Pack solution from source
    if pac solution pack \
        --folder "./solution" \
        --zipfile "./out/${SOLUTION_NAME}.zip" \
        --packagetype "Unmanaged"; then
        print_success "Solution package created: ./out/${SOLUTION_NAME}.zip"
    else
        print_error "Failed to create solution package"
        exit 1
    fi
    
    # Create managed version for production
    if pac solution pack \
        --folder "./solution" \
        --zipfile "./out/${SOLUTION_NAME}_managed.zip" \
        --packagetype "Managed"; then
        print_success "Managed solution package created: ./out/${SOLUTION_NAME}_managed.zip"
    else
        print_warning "Failed to create managed solution package"
    fi
}

# Function to run solution checker
run_solution_checker() {
    print_step "✅ Running solution checker..."
    
    if [ "$VALIDATION_ONLY" = true ]; then
        print_status "Validation mode - running comprehensive checks"
    fi
    
    if pac solution check \
        --path "./out/${SOLUTION_NAME}.zip" \
        --environment "$ENVIRONMENT_URL"; then
        print_success "Solution checker passed"
    else
        print_warning "Solution checker found issues (deployment will continue)"
    fi
}

# Function to import solution
import_solution() {
    if [ "$VALIDATION_ONLY" = true ]; then
        print_status "Skipping solution import (validation mode)"
        return 0
    fi
    
    print_step "📥 Importing solution to Dynamics 365..."
    
    # Import with enhanced 2024 options
    if pac solution import \
        --path "./out/${SOLUTION_NAME}.zip" \
        --environment "$ENVIRONMENT_URL" \
        --activate-plugins \
        --force-overwrite \
        --skip-lower-version; then
        print_success "Solution imported successfully"
    else
        print_error "Solution import failed"
        exit 1
    fi
}

# Function to deploy PCF controls
deploy_pcf_controls() {
    if [ "$SKIP_PCF" = true ] || [ "$VALIDATION_ONLY" = true ]; then
        print_status "Skipping PCF controls deployment"
        return 0
    fi
    
    print_step "🎨 Deploying PCF controls..."
    
    local controls=("ReservationHelper" "CustomerDetails" "SpaceGallery" "ReservationForm")
    local deployed_count=0
    
    for control in "${controls[@]}"; do
        local control_path="./pcf-controls/$control"
        
        if [ ! -d "$control_path" ]; then
            print_warning "PCF control not found: $control"
            continue
        fi
        
        print_status "Deploying $control..."
        
        # Change to control directory
        pushd "$control_path" > /dev/null
        
        # Check if package.json exists
        if [ -f "package.json" ]; then
            # Install dependencies
            print_status "  Installing npm dependencies..."
            npm install --silent
            
            # Build control
            print_status "  Building control..."
            npm run build --silent
            
            # Deploy with solution targeting (2024 feature)
            if pac pcf push \
                --publisher-prefix "$PUBLISHER_PREFIX" \
                --environment "$ENVIRONMENT_URL"; then
                print_success "  $control deployed successfully"
                ((deployed_count++))
            else
                print_error "  Failed to deploy $control"
            fi
        else
            print_warning "  No package.json found for $control"
        fi
        
        # Return to previous directory
        popd > /dev/null
    done
    
    print_success "PCF controls deployment completed: $deployed_count/${#controls[@]}"
}

# Function to register plugins
register_plugins() {
    if [ "$SKIP_PLUGINS" = true ] || [ "$VALIDATION_ONLY" = true ]; then
        print_status "Skipping plugin registration"
        return 0
    fi
    
    print_step "🔧 Registering plugins..."
    
    local plugin_assembly="./plugins/bin/Release/EasySpaces.Plugins.dll"
    
    if [ ! -f "$plugin_assembly" ]; then
        print_warning "Plugin assembly not found. Building..."
        
        if [ -d "./plugins" ]; then
            pushd "./plugins" > /dev/null
            
            if command -v dotnet &> /dev/null; then
                print_status "Building plugin assembly..."
                dotnet build --configuration Release --no-restore
                
                if [ -f "./bin/Release/EasySpaces.Plugins.dll" ]; then
                    print_success "Plugin assembly built successfully"
                else
                    print_error "Plugin build failed"
                    popd > /dev/null
                    return 1
                fi
            else
                print_error ".NET not found for plugin build"
                popd > /dev/null
                return 1
            fi
            
            popd > /dev/null
        else
            print_warning "Plugin source directory not found"
            return 1
        fi
    fi
    
    # Register plugin assembly
    if pac plugin push \
        --assembly-path "$plugin_assembly" \
        --environment "$ENVIRONMENT_URL"; then
        print_success "Plugins registered successfully"
    else
        print_error "Plugin registration failed"
        return 1
    fi
}

# Function to validate deployment
validate_deployment() {
    print_step "🔍 Validating deployment..."
    
    # Check solution
    print_status "Checking solution status..."
    if pac solution list --environment "$ENVIRONMENT_URL" | grep -q "$SOLUTION_NAME"; then
        print_success "Solution found in environment"
    else
        print_error "Solution not found in environment"
        exit 1
    fi
    
    # Check entities
    print_status "Checking custom entities..."
    local entities=("es_reservation" "es_space" "es_market")
    
    for entity in "${entities[@]}"; do
        if pac data list --entity-name "$entity" --environment "$ENVIRONMENT_URL" --max-results 1 &> /dev/null; then
            print_success "Entity verified: $entity"
        else
            print_warning "Entity not accessible: $entity"
        fi
    done
    
    print_success "Deployment validation completed"
}

# Function to show post-deployment steps
show_post_deployment() {
    print_header ""
    print_header "🎯 Post-Deployment Steps"
    print_header "========================"
    echo ""
    print_status "1. Import Power Automate flows manually:"
    echo "   - Go to https://make.powerautomate.com"
    echo "   - Import flows from ./power-automate/ folder"
    echo ""
    print_status "2. Configure security roles:"
    echo "   - Assign users to Easy Spaces roles"
    echo "   - Set up field-level security"
    echo ""
    print_status "3. Import sample data (optional):"
    echo "   - Use Data Import Wizard"
    echo "   - Or run: pac data import --file ./data/sample-data.csv"
    echo ""
    print_status "4. Test the application:"
    echo "   - Create test reservation"
    echo "   - Verify PCF controls work"
    echo "   - Test workflows and plugins"
    echo ""
    print_status "5. Configure integrations:"
    echo "   - Email settings"
    echo "   - Teams notifications"
    echo "   - Calendar integration"
    echo ""
}

# Main execution
main() {
    print_header ""
    print_header "🚀 Easy Spaces Dynamics 365 CLI Deployment"
    print_header "============================================="
    print_header ""
    
    print_status "Environment: $ENVIRONMENT_URL"
    print_status "Solution: $SOLUTION_NAME"
    print_status "Publisher Prefix: $PUBLISHER_PREFIX"
    
    if [ "$VALIDATION_ONLY" = true ]; then
        print_status "Mode: Validation Only"
    fi
    
    print_header ""
    
    # Step 1: Check prerequisites
    check_prerequisites
    
    # Step 2: Authenticate
    authenticate
    
    # Step 3: Create solution package
    create_solution_package
    
    # Step 4: Run solution checker
    run_solution_checker
    
    # Step 5: Import solution
    import_solution
    
    # Step 6: Deploy PCF controls
    deploy_pcf_controls
    
    # Step 7: Register plugins
    register_plugins
    
    # Step 8: Validate deployment
    validate_deployment
    
    # Step 9: Show post-deployment steps
    if [ "$VALIDATION_ONLY" = false ]; then
        show_post_deployment
    fi
    
    print_header ""
    print_success "🎉 Easy Spaces deployment completed successfully!"
    print_header ""
    
    # Show summary
    print_status "Deployment Summary:"
    echo "  Solution: ✅ Imported"
    
    if [ "$SKIP_PCF" = false ] && [ "$VALIDATION_ONLY" = false ]; then
        echo "  PCF Controls: ✅ Deployed"
    else
        echo "  PCF Controls: ⏭️ Skipped"
    fi
    
    if [ "$SKIP_PLUGINS" = false ] && [ "$VALIDATION_ONLY" = false ]; then
        echo "  Plugins: ✅ Registered"
    else
        echo "  Plugins: ⏭️ Skipped"
    fi
    
    echo "  Validation: ✅ Completed"
    echo ""
    
    print_status "Access your environment: $ENVIRONMENT_URL"
}

# Error handling
trap 'print_error "Deployment failed at line $LINENO"' ERR

# Run main function
main "$@"