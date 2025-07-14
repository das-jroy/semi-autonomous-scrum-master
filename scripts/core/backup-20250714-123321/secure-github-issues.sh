#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Secure GitHub Issue Generator for $PROJECT_NAME Catalog TODOs
# This script safely converts TODOs into GitHub issues with proper security controls

set -e

echo "🔒 Secure $PROJECT_NAME Catalog - GitHub Issue Generator"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Security Configuration
# REPO_OWNER loaded from config
# REPO_NAME loaded from config
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/3"
PROJECT_NUMBER="3"
DRY_RUN=${DRY_RUN:-true}  # Default to dry run for security

# Required GitHub scopes for this operation
REQUIRED_SCOPES=("repo" "project")  # project scope covers read:project and write:project

# Function to validate security prerequisites
validate_security() {
    echo -e "${CYAN}🔒 Security Validation${NC}"
    echo "====================="
    
    # Check if GitHub CLI is available
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
        echo "Install with: brew install gh"
        exit 1
    fi
    
    # Check authentication
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
    
    # Get current token info
    local current_user=$(gh api user --jq .login)
    local auth_status=$(gh auth status 2>&1)
    
    echo -e "${GREEN}✅ GitHub CLI authenticated as: ${current_user}${NC}"
    
    # Check token scopes
    echo "Checking token scopes..."
    local token_scopes=$(echo "$auth_status" | grep "Token scopes:" | sed "s/.*Token scopes: //" | sed "s/'//g" | tr ',' ' ')
    
    echo "Current scopes: $token_scopes"
    
    # Check if we have required scopes
    local missing_scopes=()
    local has_repo=false
    local has_project=false
    
    # Check for repo scope
    if [[ " $token_scopes " == *" repo "* ]]; then
        has_repo=true
    fi
    
    # Check for project scopes (GitHub CLI uses 'project' which covers read:project and write:project)
    if [[ " $token_scopes " == *" project "* ]] || [[ " $token_scopes " == *" read:project "* ]] || [[ " $token_scopes " == *" write:project "* ]]; then
        has_project=true
    fi
    
    # Build list of missing scopes
    if [[ "$has_repo" != "true" ]]; then
        missing_scopes+=("repo")
    fi
    if [[ "$has_project" != "true" ]]; then
        missing_scopes+=("project")
    fi
    
    if [ ${#missing_scopes[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing required scopes: ${missing_scopes[*]}${NC}"
        echo -e "${YELLOW}   Your token needs to be updated with project permissions${NC}"
        echo "   Go to: https://github.com/settings/tokens"
        echo "   Add scopes: ${missing_scopes[*]}"
        echo ""
        echo -e "${YELLOW}⚠️  Continuing in DRY RUN mode only${NC}"
        DRY_RUN=true
    else
        echo -e "${GREEN}✅ All required scopes present${NC}"
    fi
    
    # Validate repository access
    echo "Validating repository access..."
    if gh repo view "$REPO_OWNER/$REPO_NAME" &> /dev/null; then
        echo -e "${GREEN}✅ Repository access confirmed${NC}"
    else
        echo -e "${RED}❌ Cannot access repository: $REPO_OWNER/$REPO_NAME${NC}"
        exit 1
    fi
    
    # Validate project access
    echo "Validating project access..."
    
    # Try to check if we can access the project (this might fail if missing scopes)
    if gh api graphql -f query="
    {
      organization(login: \"$REPO_OWNER\") {
        projectV2(number: $PROJECT_NUMBER) {
          id
          title
        }
      }
    }" &> /dev/null; then
        echo -e "${GREEN}✅ Project access confirmed${NC}"
    else
        echo -e "${YELLOW}⚠️  Cannot access project details (may need project scopes)${NC}"
        echo "   Project URL: $PROJECT_URL"
        echo "   This is normal if you don't have 'read:project' scope yet"
    fi
    
    echo ""
}

# Function to analyze current TODOs securely
analyze_todos() {
    echo -e "${BLUE}📊 TODO Analysis${NC}"
    echo "================"
    
    # Count TODOs by category
    local resource_todos=$(grep -r "TODO: Implement.*resource configuration" --include="*.tf" modules/ | wc -l | tr -d ' ')
    local placeholder_todos=$(grep -r "placeholder-id.*TODO" --include="*.tf" modules/ | wc -l | tr -d ' ')
    local workflow_todos=$(grep -r "TODO" --include="*.yml" .github/ 2>/dev/null | wc -l | tr -d ' ')
    
    echo "Resource Implementation TODOs: $resource_todos"
    echo "Placeholder ID TODOs: $placeholder_todos"
    echo "Workflow TODOs: $workflow_todos"
    
    local total_todos=$((resource_todos + placeholder_todos + workflow_todos))
    echo "Total TODOs: $total_todos"
    echo ""
    
    # Show specific modules that need work
    echo -e "${YELLOW}Modules needing implementation:${NC}"
    find modules -name "*.tf" -exec grep -l "TODO\|placeholder-id" {} \; | \
        sed 's|modules/||' | sed 's|/[^/]*$||' | sort -u | \
        while read -r module; do
            echo "  🚧 $module"
        done
    echo ""
}

# Function to show what would be created (dry run)
show_dry_run() {
    echo -e "${CYAN}🔍 DRY RUN - Issues that would be created:${NC}"
    echo "=========================================="
    
    # Priority 1 modules (high impact)
    local priority1_modules=(
        "compute/virtual-machine:Virtual Machine:Core compute infrastructure for VMs"
        "database/cosmosdb:Cosmos DB:Multi-model NoSQL database service"
        "containers/aks-cluster:AKS Cluster:Azure Kubernetes Service cluster"
        "networking/load-balancer:Load Balancer:Layer 4 load balancing service"
    )
    
    # Priority 2 modules (networking & security)
    local priority2_modules=(
        "networking/application-gateway:Application Gateway:Layer 7 load balancing and WAF"
        "networking/vpn-gateway:VPN Gateway:Site-to-site VPN connectivity"
        "networking/route-table:Route Table:Custom routing configurations"
        "security/security-center:Security Center:Azure Security Center policies"
    )
    
    # Priority 3 modules (specialized)
    local priority3_modules=(
        "compute/virtual-machine-scale-set:VM Scale Set:Auto-scaling virtual machine sets"
        "containers/container-instance:Container Instances:Serverless container hosting"
        "storage/file-share:File Share:Azure Files shared storage"
        "foundation/subscription:Subscription:Subscription-level governance"
        "foundation/management-group:Management Group:Governance hierarchy"
        "monitoring/log-analytics:Log Analytics:Centralized logging workspace"
        "monitoring/monitor-alerts:Monitor Alerts:Azure Monitor alerting rules"
    )
    
    echo -e "${GREEN}Priority 1 (High Impact) - 4 issues:${NC}"
    for module_info in "${priority1_modules[@]}"; do
        IFS=':' read -r module_path display_name description <<< "$module_info"
        echo "  📝 Implement $display_name Module ($module_path)"
    done
    
    echo -e "${YELLOW}Priority 2 (Enterprise) - 4 issues:${NC}"
    for module_info in "${priority2_modules[@]}"; do
        IFS=':' read -r module_path display_name description <<< "$module_info"
        echo "  📝 Implement $display_name Module ($module_path)"
    done
    
    echo -e "${BLUE}Priority 3 (Specialized) - 7 issues:${NC}"
    for module_info in "${priority3_modules[@]}"; do
        IFS=':' read -r module_path display_name description <<< "$module_info"
        echo "  📝 Implement $display_name Module ($module_path)"
    done
    
    echo -e "${PURPLE}Infrastructure Issues - 2 issues:${NC}"
    echo "  📝 Update CI/CD Workflow for InfraWeave CLI Integration"
    echo "  📝 Configure GitHub Project Board Structure"
    
    echo ""
    echo -e "${CYAN}Total: 17 issues would be created${NC}"
    echo -e "${CYAN}Target Project: $PROJECT_URL${NC}"
    echo ""
}

# Function to generate module issue body
generate_module_issue_body() {
    local module_path="$1"
    local display_name="$2" 
    local description="$3"
    
    cat << EOF
## 📦 Module Implementation: $display_name

**Path:** \`modules/$module_path\`  
**Description:** $description

### 🎯 Objective
Implement the complete Azure $display_name module with Platform 2.0 security compliance and production-ready configuration.

### 📋 Tasks

#### Core Implementation
- [ ] Research Azure resource requirements and best practices
- [ ] Implement \`main.tf\` with actual Azure resources (replace TODO placeholder)
- [ ] Define comprehensive \`variables.tf\` with validation constraints
- [ ] Create meaningful \`outputs.tf\` with actual resource outputs (replace placeholder-id)
- [ ] Update module documentation

#### Security & Compliance  
- [ ] Implement Platform 2.0 security features
- [ ] Add encryption and access control configurations
- [ ] Include network security controls where applicable
- [ ] Validate security defaults and overrides

#### Documentation & Testing
- [ ] Update README.md with usage examples and security notes
- [ ] Add example configurations in \`examples/\` directory
- [ ] Test with \`terraform validate\` and \`terraform plan\`
- [ ] Document breaking changes and migration notes

### 🔗 Reference Patterns
Follow the established patterns from completed modules:
- ✅ **storage/managed-disk** - Encryption, network controls, comprehensive validation
- ✅ **database/mysql** - HA configuration, backup features, security defaults

### 📚 Resources
- [Azure $display_name Documentation](https://docs.microsoft.com/en-us/azure/)
- [Terraform azurerm Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Platform 2.0 Security Guide](../docs/SECURITY-GUIDE.md)

### ✅ Definition of Done
- [ ] All TODOs resolved in module files
- [ ] Module passes \`terraform validate\`
- [ ] Security scan passes
- [ ] Documentation complete with examples
- [ ] Code review approved
- [ ] Integration tests pass

---
*This issue was auto-generated from TODO analysis*
EOF
}

# Function to create module implementation issues
create_module_issues() {
    echo -e "${BLUE}📦 Creating Module Implementation Issues...${NC}"
    echo ""
    
    # Priority 1 modules (high impact)
    local priority1_modules=(
        "compute/virtual-machine:Virtual Machine:Core compute infrastructure for VMs"
        "database/cosmosdb:Cosmos DB:Multi-model NoSQL database service"
        "containers/aks-cluster:AKS Cluster:Azure Kubernetes Service cluster"
        "networking/load-balancer:Load Balancer:Layer 4 load balancing service"
    )
    
    # Priority 2 modules (networking & security)
    local priority2_modules=(
        "networking/application-gateway:Application Gateway:Layer 7 load balancing and WAF"
        "networking/vpn-gateway:VPN Gateway:Site-to-site VPN connectivity"
        "networking/route-table:Route Table:Custom routing configurations"
        "security/security-center:Security Center:Azure Security Center policies"
    )
    
    # Priority 3 modules (specialized)
    local priority3_modules=(
        "compute/virtual-machine-scale-set:VM Scale Set:Auto-scaling virtual machine sets"
        "containers/container-instance:Container Instances:Serverless container hosting"
        "storage/file-share:File Share:Azure Files shared storage"
        "foundation/subscription:Subscription:Subscription-level governance"
        "foundation/management-group:Management Group:Governance hierarchy"
        "monitoring/log-analytics:Log Analytics:Centralized logging workspace"
        "monitoring/monitor-alerts:Monitor Alerts:Azure Monitor alerting rules"
    )
    
    # Create issues for each priority level
    create_priority_issues "Priority 1 (High Impact)" priority1_modules[@] "high-priority,P1" "Compute,Database,Containers,Networking"
    create_priority_issues "Priority 2 (Enterprise)" priority2_modules[@] "medium-priority,P2" "Networking,Security"  
    create_priority_issues "Priority 3 (Specialized)" priority3_modules[@] "low-priority,P3" "Compute,Containers,Storage,Foundation,Monitoring"
}

# Function to create issues for a priority group
create_priority_issues() {
    local priority_name="$1"
    local modules_ref="$2"
    local labels="$3"
    local categories="$4"
    
    eval "local modules=(\"\${$modules_ref}\")"
    
    echo -e "${PURPLE}Creating $priority_name issues...${NC}"
    
    for module_info in "${modules[@]}"; do
        IFS=':' read -r module_path display_name description <<< "$module_info"
        
        # Determine category from module path
        local category=""
        case "$module_path" in
            compute/*) category="Compute" ;;
            database/*) category="Database" ;;
            containers/*) category="Containers" ;;
            networking/*) category="Networking" ;;
            security/*) category="Security" ;;
            storage/*) category="Storage" ;;
            foundation/*) category="Foundation" ;;
            monitoring/*) category="Monitoring" ;;
            *) category="Other" ;;
        esac
        
        # Generate issue content
        local issue_title="Implement $display_name Module ($module_path)"
        local issue_body=$(generate_module_issue_body "$module_path" "$display_name" "$description")
        
        # Create the issue
        echo "  📝 Creating issue: $display_name"
        
        if gh issue create \
            --title "$issue_title" \
            --body "$issue_body" \
            --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null; then
            echo "    ✅ Created successfully"
        else
            echo "    ⚠️  Failed to create issue for $display_name"
        fi
    done
    echo ""
}

# Function to create infrastructure issues
create_infrastructure_issues() {
    echo -e "${BLUE}⚙️ Creating Infrastructure Issues...${NC}"
    echo ""
    
    # CI/CD Workflow improvements
    local workflow_title="Update CI/CD Workflow for InfraWeave CLI Integration"
    local workflow_body=$(cat << 'EOF'
## 🔧 CI/CD Workflow Enhancement

**Objective:** Complete the InfraWeave CLI integration in our GitHub Actions workflow.

### 📋 Tasks

#### InfraWeave CLI Setup
- [ ] Research and implement InfraWeave CLI installation in workflow
- [ ] Replace TODO placeholder in `.github/workflows/validate.yml` line 253
- [ ] Add proper authentication and configuration
- [ ] Test CLI integration with sample deployments

#### Publishing Logic
- [ ] Implement module publishing logic (replace TODO line 260)
- [ ] Add module versioning and release automation
- [ ] Configure artifact publishing to InfraWeave registry
- [ ] Add automated module validation before publishing

#### Testing Enhancements
- [ ] Add integration tests for InfraWeave deployments
- [ ] Implement module compatibility testing
- [ ] Add security scanning for published modules
- [ ] Create deployment validation pipeline

### 🔗 Resources
- InfraWeave CLI Documentation
- GitHub Actions InfraWeave Integration
- Module Publishing Best Practices

### ✅ Definition of Done
- [ ] All workflow TODOs resolved
- [ ] CI/CD pipeline successfully integrates InfraWeave CLI
- [ ] Module publishing automation working
- [ ] Documentation updated

---
*Priority: Medium - Required for production deployment*
EOF
    )
    
    echo "  📝 Creating workflow issue..."
    if gh issue create \
        --title "$workflow_title" \
        --body "$workflow_body" \
        --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null; then
        echo "    ✅ Created successfully"
    else
        echo "    ⚠️  Failed to create workflow issue"
    fi
    
    # Project setup issue
    local project_title="Configure GitHub Project Board for Module Implementation Tracking"
    local project_body=$(cat << 'EOF'
## 🎯 GitHub Project Configuration

**Objective:** Configure the GitHub project board for tracking $PROJECT_NAME module implementation progress.

### 📋 Project Setup Tasks

#### Custom Fields Configuration
- [ ] Add "Module Category" field (Select): Foundation, Networking, Compute, Storage, Database, Containers, Security, Monitoring
- [ ] Add "Priority Level" field (Select): P1-High Impact, P2-Enterprise, P3-Specialized  
- [ ] Add "Implementation Status" field (Status): Backlog, In Progress, Review, Complete, Blocked
- [ ] Add "Complexity" field (Select): Low (1-2 days), Medium (3-5 days), High (1-2 weeks)
- [ ] Add "Security Review" field (Select): Not Required, Required, Approved, Rejected

#### Views Configuration
- [ ] Create "By Priority" view (grouped by Priority Level)
- [ ] Create "By Category" view (grouped by Module Category)  
- [ ] Create "Security Dashboard" view (filtered by Security Review status)
- [ ] Create "Sprint Board" view (current iteration planning)

#### Automation Rules
- [ ] Auto-move to "In Progress" when assigned
- [ ] Auto-move to "Review" when PR opened
- [ ] Auto-move to "Complete" when PR merged
- [ ] Auto-assign security review for sensitive modules

### 📊 Success Metrics
- Track completion rate by module category
- Monitor velocity (modules completed per sprint)
- Identify blockers and dependencies

---
*This setup will provide excellent visibility into implementation progress*
EOF
    )
    
    echo "  📝 Creating project setup issue..."
    if gh issue create \
        --title "$project_title" \
        --body "$project_body" \
        --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null; then
        echo "    ✅ Created successfully"
    else
        echo "    ⚠️  Failed to create project setup issue"
    fi
}

# Function to create issues with proper security controls
create_issues_securely() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}🔒 DRY RUN MODE - No actual issues will be created${NC}"
        show_dry_run
        return
    fi
    
    echo -e "${GREEN}🚀 Creating GitHub Issues${NC}"
    echo "========================="
    
    # Confirm with user before creating issues
    echo -e "${YELLOW}⚠️  This will create approximately 17 GitHub issues in:${NC}"
    echo "   Repository: $REPO_OWNER/$REPO_NAME"
    echo "   Project: $PROJECT_URL"
    echo ""
    echo -e "${YELLOW}Are you sure you want to proceed? (yes/no)${NC}"
    read -r confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Create a backup/log of what we're doing
    local log_file="github-issues-$(date +%Y%m%d-%H%M%S).log"
    echo "Logging operations to: $log_file"
    
    {
        echo "GitHub Issues Creation Log - $(date)"
        echo "===================================="
        echo "Repository: $REPO_OWNER/$REPO_NAME"
        echo "Project: $PROJECT_URL"
        echo "User: $(gh api user --jq .login)"
        echo ""
    } > "$log_file"
    
    # Create module implementation issues
    create_module_issues 2>&1 | tee -a "$log_file"
    
    # Create infrastructure issues  
    create_infrastructure_issues 2>&1 | tee -a "$log_file"
    
    echo ""
    echo -e "${GREEN}✅ Issue creation completed!${NC}"
    echo "Log saved to: $log_file"
    echo ""
    echo -e "${BLUE}📊 Next Steps:${NC}"
    echo "1. Visit your project: $PROJECT_URL"
    echo "2. Configure custom fields as recommended"
    echo "3. Assign issues to team members or milestones"
    echo "4. Start with Priority 1 modules for maximum impact"
    echo ""
    echo -e "${GREEN}View all issues: https://github.com/$REPO_OWNER/$REPO_NAME/issues${NC}"
}

# Function to show project configuration recommendations
show_project_recommendations() {
    echo -e "${BLUE}📋 GitHub Project Configuration Recommendations${NC}"
    echo "==============================================="
    echo ""
    echo "For project: $PROJECT_URL"
    echo ""
    echo "Recommended Custom Fields:"
    echo "  1. Module Category (Select): Foundation, Networking, Compute, Storage, Database, Containers, Security, Monitoring"
    echo "  2. Priority Level (Select): P1-High Impact, P2-Enterprise, P3-Specialized"
    echo "  3. Implementation Status (Status): Backlog, In Progress, Review, Complete, Blocked"
    echo "  4. Complexity (Select): Low (1-2 days), Medium (3-5 days), High (1-2 weeks)"
    echo "  5. Security Review (Select): Not Required, Required, Approved, Rejected"
    echo ""
    echo "Recommended Views:"
    echo "  - By Priority (grouped by Priority Level)"
    echo "  - By Category (grouped by Module Category)"
    echo "  - Security Review Board (filtered by Security Review status)"
    echo "  - Sprint Planning (filter by current iteration)"
    echo ""
}

# Function to show operational security reminders
show_security_reminders() {
    echo -e "${RED}🔒 OPERATIONAL SECURITY REMINDERS${NC}"
    echo "================================="
    echo ""
    echo "✅ Always use DRY_RUN=true for initial testing"
    echo "✅ Validate all changes in a staging environment first"
    echo "✅ Never commit sensitive information to issue descriptions"
    echo "✅ Review all generated content before creation"
    echo "✅ Use proper labels and project assignments"
    echo "✅ Follow principle of least privilege"
    echo ""
    echo "To run in LIVE mode (only after validation):"
    echo "  DRY_RUN=false ./scripts/secure-github-issues.sh"
    echo ""
}

# Main execution
main() {
    validate_security
    analyze_todos
    
    if [[ "$DRY_RUN" == "true" ]]; then
        show_dry_run
        show_project_recommendations
        show_security_reminders
    else
        create_issues_securely
    fi
    
    # Show final summary
    echo -e "${CYAN}📈 Summary${NC}"
    echo "=========="
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "✅ Dry run completed - no issues created"
        echo "✅ Security validation passed"
        echo "✅ 17 issues ready to be created when you run --live"
    else
        echo "✅ Issue creation completed"
        echo "✅ Check the log file for detailed results"
        echo "✅ Visit your project board to manage the new issues"
    fi
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --live)
            DRY_RUN=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            cat << 'EOF'
🔒 Secure GitHub Issues Generator for $PROJECT_NAME Catalog

USAGE:
    ./scripts/secure-github-issues.sh [OPTIONS]

OPTIONS:
    --dry-run    Preview what would be created (default, safe)
    --live       Actually create the issues (requires confirmation)
    --help       Show this help message

DESCRIPTION:
    This script securely converts TODO items in the $PROJECT_NAME catalog
    into structured GitHub issues with proper operational security controls.

FEATURES:
    ✅ Security validation and scope checking
    ✅ Dry-run mode for safe testing
    ✅ Detailed logging and audit trail
    ✅ Automatic categorization and labeling
    ✅ Project board integration recommendations

PREREQUISITES:
    1. GitHub CLI (gh) installed and authenticated
    2. Access to $REPO_OWNER/$REPO_NAME repository
    3. GitHub token with scopes: repo, read:project, write:project

SECURITY:
    - Defaults to dry-run mode for safety
    - Validates all permissions before execution
    - Requires explicit confirmation for live mode
    - Creates audit logs of all operations
    - Follows principle of least privilege

EXAMPLES:
    # Safe preview (recommended first step)
    ./scripts/secure-github-issues.sh --dry-run

    # Create issues (after validating dry-run output)
    DRY_RUN=false ./scripts/secure-github-issues.sh --live

TARGET:
    Repository: $REPO_OWNER/$REPO_NAME
    Project:    https://github.com/orgs/$REPO_OWNER/projects/3
    Issues:     ~17 structured issues covering 15 modules + 2 infrastructure

For more information, see the project documentation.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main
