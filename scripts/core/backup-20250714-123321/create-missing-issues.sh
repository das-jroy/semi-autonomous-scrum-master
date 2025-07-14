#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Create GitHub Issues for Missing Modules
# This script creates issues for the 13 modules that were missed in the initial issue creation

set -e

echo "🚀 Creating Issues for Missing Modules"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
# REPO_OWNER loaded from config
# REPO_NAME loaded from config
PROJECT_NUMBER="3"

# Array of missing modules with their details
declare -A modules_missing=(
    ["compute/app-service"]="Compute|Medium|Medium|Required"
    ["compute/function-app"]="Compute|Medium|Medium|Required"
    ["containers/container-registry"]="Containers|High|Medium|Required"
    ["database/mysql"]="Database|High|Medium|Required"
    ["database/postgresql"]="Database|Medium|Medium|Required"
    ["database/sql-database"]="Database|High|High|Required"
    ["foundation/resource-group"]="Foundation|High|Low|Not Required"
    ["monitoring/application-insights"]="Monitoring|Medium|Low|Not Required"
    ["monitoring/log-analytics-workspace"]="Monitoring|Medium|Low|Not Required"
    ["networking/network-security-group"]="Networking|High|Medium|Required"
    ["networking/virtual-network"]="Networking|High|Medium|Not Required"
    ["security/key-vault"]="Security|High|Medium|Required"
    ["security/managed-identity"]="Security|High|Low|Required"
    ["storage/managed-disk"]="Storage|High|Low|Not Required"
    ["storage/storage-account"]="Storage|High|Medium|Not Required"
)

# Function to create issue for a module
create_module_issue() {
    local module_path="$1"
    local metadata="$2"
    
    IFS='|' read -r category priority complexity security <<< "$metadata"
    
    # Extract module name and service name
    local service_name=$(basename "$module_path")
    local category_path=$(dirname "$module_path")
    
    echo -e "${PURPLE}📝 Creating Issue for: $module_path${NC}"
    
    # Create issue title
    local title="Implement $(echo $service_name | sed 's/-/ /g' | sed 's/\b\w/\u&/g') Module ($module_path)"
    
    # Create issue body
    local body="## 📦 Module Implementation: $(echo $service_name | sed 's/-/ /g' | sed 's/\b\w/\u&/g')

Path: \`modules/$module_path\`
Description: Azure $(echo $service_name | sed 's/-/ /g') implementation

### 🎯 Objective

Implement the complete Azure $(echo $service_name | sed 's/-/ /g') module with Platform 2.0 security compliance and production-ready configuration.

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

• ✅ storage/managed-disk - Encryption, network controls, comprehensive validation
• ✅ database/mysql - HA configuration, backup features, security defaults

### 📚 Resources

• Azure Documentation https://docs.microsoft.com/en-us/azure/
• Terraform azurerm Provider https://registry.terraform.io/providers/hashicorp/azurerm/latest
• Platform 2.0 Security Guide /docs/SECURITY-GUIDE.md

### ✅ Definition of Done

- [ ] All TODOs resolved in module files
- [ ] Module passes \`terraform validate\`
- [ ] Security scan passes
- [ ] Documentation complete with examples
- [ ] Code review approved
- [ ] Integration tests pass

--------

This issue was auto-generated from TODO analysis"

    # Create the issue
    local issue_number=$(gh issue create \
        --repo "$REPO_OWNER/$REPO_NAME" \
        --title "$title" \
        --body "$body" \
        --label "module,implementation,$category" \
        --assignee "" \
        | grep -o '#[0-9]\+' | tr -d '#')
    
    if [[ -n "$issue_number" ]]; then
        echo -e "${GREEN}✅ Created issue #$issue_number: $title${NC}"
        
        # Add to project board
        gh api graphql -f query='
        mutation($projectId: ID!, $issueId: ID!) {
          addProjectV2ItemById(input: {
            projectId: $projectId
            contentId: $issueId
          }) {
            item {
              id
            }
          }
        }' -f projectId="PVT_kwDOC-2N484A9m2C" -f issueId="$(gh api repos/$REPO_OWNER/$REPO_NAME/issues/$issue_number --jq .node_id)" > /dev/null
        
        echo -e "${BLUE}✅ Added to project board${NC}"
        echo ""
    else
        echo -e "${RED}❌ Failed to create issue for $module_path${NC}"
    fi
}

# Main execution
echo -e "${CYAN}🔍 Creating 15 Missing Module Issues${NC}"
echo "=================================="
echo ""

for module_path in "${!modules_missing[@]}"; do
    create_module_issue "$module_path" "${modules_missing[$module_path]}"
    sleep 1  # Rate limiting
done

echo -e "${GREEN}🎉 All Missing Module Issues Created!${NC}"
echo "===================================="
echo ""
echo -e "${YELLOW}📊 Summary:${NC}"
echo "- Created 15 new GitHub issues for missing modules"
echo "- All issues added to project board"
echo "- Ready for metadata update"
echo ""
echo -e "${BLUE}🔗 Next Steps:${NC}"
echo "1. Run the metadata update script to add proper labels and custom fields"
echo "2. Check your project board: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
echo "3. Start implementing modules based on priority!"
echo ""
