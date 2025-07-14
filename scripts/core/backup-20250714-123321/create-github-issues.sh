#!/bin/bash

# GitHub Issue Generator for Project Documentation
# This script converts documentation TODOs into structured GitHub issues

set -e

echo "🎫 Generic GitHub Issue Generator"
echo "================================="

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Parse command line arguments
CUSTOM_# REPO_OWNER loaded from config
CUSTOM_# REPO_NAME loaded from config
PROJECT_TYPE="${3:-web-application}"

# Load project configuration
load_config

# Override with command line arguments if provided
if [[ -n "$CUSTOM_REPO_OWNER" ]]; then
    # REPO_OWNER loaded from config
fi

if [[ -n "$CUSTOM_REPO_NAME" ]]; then
    # REPO_NAME loaded from config
fi

echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Project Type: $PROJECT_TYPE"
echo ""

# Function to check if GitHub CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed. Please install it first.${NC}"
        echo "Install with: brew install gh"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Please authenticate with GitHub CLI first${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI is ready${NC}"
}

# Function to load project type configuration
load_project_type_config() {
    local project_type="$1"
    local config_file="configs/project-types/${project_type}.json"
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${YELLOW}⚠️  Project type config not found: $config_file${NC}"
        echo "Using default configuration..."
        return 1
    fi
    
    echo -e "${BLUE}📋 Loading project type: $project_type${NC}"
    return 0
}

# Function to create module implementation issues
create_module_issues() {
    echo -e "${BLUE}📦 Creating Module Implementation Issues...${NC}"
    echo ""
    
    # Load project type configuration if available
    local project_config="configs/project-types/${PROJECT_TYPE}.json"
    if [[ -f "$project_config" ]]; then
        local categories=($(jq -r '.categories[]' "$project_config"))
    else
        # Default categories for generic projects
        local categories=("frontend" "backend" "database" "testing" "documentation")
    fi
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
    create_priority_issues "Priority 1 (High Impact)" priority1_modules[@] "🚀 high-priority" "P1"
    create_priority_issues "Priority 2 (Enterprise)" priority2_modules[@] "🔧 medium-priority" "P2"  
    create_priority_issues "Priority 3 (Specialized)" priority3_modules[@] "📋 low-priority" "P3"
}

# Function to create issues for a priority group
create_priority_issues() {
    local priority_name="$1"
    local modules_ref="$2"
    local labels="$3"
    local priority_label="$4"
    
    eval "local modules=(\"\${$modules_ref}\")"
    
    echo -e "${PURPLE}Creating $priority_name issues...${NC}"
    
    for module_info in "${modules[@]}"; do
        IFS=':' read -r module_path display_name description <<< "$module_info"
        
        # Generate issue content
        local issue_title="Implement $display_name Module ($module_path)"
        local issue_body=$(generate_module_issue_body "$module_path" "$display_name" "$description")
        
        # Create the issue
        echo "  📝 Creating issue: $display_name"
        if command -v gh &> /dev/null; then
            gh issue create \
                --title "$issue_title" \
                --body "$issue_body" \
                --label "module-implementation,$labels,$priority_label,Platform-2.0" \
                --assignee "@me" || echo "    ⚠️  Failed to create issue for $display_name"
        else
            echo "    📄 Would create issue: $issue_title"
        fi
    done
    echo ""
}

# Function to generate issue body for module implementation
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

# Function to create infrastructure/workflow issues
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
    if command -v gh &> /dev/null; then
        gh issue create \
            --title "$workflow_title" \
            --body "$workflow_body" \
            --label "infrastructure,workflow,ci-cd,medium-priority" \
            --assignee "@me" || echo "    ⚠️  Failed to create workflow issue"
    fi
}

# Function to create project setup issue
create_project_setup_issue() {
    echo -e "${BLUE}📋 Creating Project Setup Issue...${NC}"
    
    local project_title="Set up GitHub Project for $PROJECT_NAME Module Implementation"
    local project_body=$(cat << 'EOF'
## 🎯 GitHub Project Configuration

**Objective:** Configure the GitHub project board for tracking $PROJECT_NAME module implementation progress.

### 📋 Recommended Project Setup

#### Project Details
- **Name:** "$PROJECT_NAME"
- **Description:** "Track implementation progress of all 30 $PROJECT_NAME modules for Platform 2.0 compliance"
- **Visibility:** Private (organization internal)

#### Custom Fields
1. **Module Category** (Select)
   - Foundation
   - Networking  
   - Compute
   - Storage
   - Database
   - Containers
   - Security
   - Monitoring

2. **Priority Level** (Select)
   - P1 - High Impact (Core Infrastructure)
   - P2 - Enterprise (Networking & Security)
   - P3 - Specialized (Advanced Use Cases)

3. **Implementation Status** (Status)
   - 📋 Backlog
   - 🚧 In Progress
   - 👁️ Review
   - ✅ Complete
   - 🚫 Blocked

4. **Complexity** (Select)
   - Low (1-2 days)
   - Medium (3-5 days)
   - High (1-2 weeks)

#### Views to Create
1. **By Priority** - Group by Priority Level
2. **By Category** - Group by Module Category  
3. **Sprint Board** - Filter by current iteration
4. **Completion Progress** - Track overall progress

#### Automation Rules
- Auto-move to "In Progress" when assigned
- Auto-move to "Review" when PR opened
- Auto-move to "Complete" when PR merged

### 📊 Success Metrics
- Track completion rate by module category
- Monitor velocity (modules completed per sprint)
- Identify blockers and dependencies

---
*This setup will provide excellent visibility into implementation progress*
EOF
    )
    
    echo "  📝 Creating project setup issue..."
    if command -v gh &> /dev/null; then
        gh issue create \
            --title "$project_title" \
            --body "$project_body" \
            --label "project-management,setup,documentation" \
            --assignee "@me" || echo "    ⚠️  Failed to create project setup issue"
    fi
}

# Function to show summary
show_summary() {
    echo -e "${GREEN}📊 Issue Creation Summary${NC}"
    echo "================================"
    echo ""
    echo "Created issues for:"
    echo "  🚀 4 Priority 1 modules (high impact)"
    echo "  🔧 4 Priority 2 modules (enterprise)"
    echo "  📋 9 Priority 3 modules (specialized)"
    echo "  ⚙️ 1 Infrastructure/workflow issue"
    echo "  📋 1 Project setup issue"
    echo ""
    echo "Total: 19 issues created"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Configure your GitHub project with the recommended fields"
    echo "2. Assign issues to team members or sprints"
    echo "3. Start with Priority 1 modules for maximum impact"
    echo "4. Use the project board to track progress"
    echo ""
    echo -e "${GREEN}🎯 Ready to start implementing! View issues at:${NC}"
    echo "https://github.com/$REPO_OWNER/$REPO_NAME/issues"
}

# Main execution
check_gh_cli

echo -e "${YELLOW}This will create GitHub issues for all remaining TODOs.${NC}"
echo -e "${YELLOW}Continue? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    create_module_issues
    create_infrastructure_issues  
    create_project_setup_issue
    show_summary
else
    echo "Cancelled."
    exit 0
fi
