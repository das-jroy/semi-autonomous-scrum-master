#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# TODO Management Script for $PROJECT_NAME
# This script helps track and manage TODOs across the codebase

set -e

echo "🔍 $PROJECT_NAME"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to count TODOs
count_todos() {
    local count=$(grep -r "TODO" --include="*.tf" --include="*.yaml" --include="*.yml" --include="*.sh" --include="*.md" . | wc -l)
    echo "$count"
}

# Function to categorize TODOs
categorize_todos() {
    echo -e "${BLUE}📊 TODO Categories:${NC}"
    echo ""
    
    echo -e "${YELLOW}🔧 Resource Implementation TODOs:${NC}"
    grep -r "TODO: Implement.*resource configuration" --include="*.tf" . | wc -l | xargs echo "  Count:"
    
    echo -e "${YELLOW}📋 Placeholder ID TODOs:${NC}"
    grep -r "placeholder-id.*TODO" --include="*.tf" . | wc -l | xargs echo "  Count:"
    
    echo -e "${YELLOW}⚙️ Workflow TODOs:${NC}"
    grep -r "TODO" --include="*.yml" .github/ | wc -l | xargs echo "  Count:"
    
    echo ""
}

# Function to show module completion status
show_module_status() {
    echo -e "${BLUE}📦 Module Implementation Status:${NC}"
    echo ""
    
    # Find all modules
    local modules=$(find modules -name "module.yaml" | xargs dirname | sort)
    local total_modules=$(echo "$modules" | wc -l)
    local implemented_modules=0
    
    for module_dir in $modules; do
        local has_todos=$(grep -c "TODO\|placeholder-id" "$module_dir"/*.tf 2>/dev/null || echo 0)
        if [ "$has_todos" -eq 0 ]; then
            echo -e "  ✅ $module_dir - ${GREEN}Complete${NC}"
            ((implemented_modules++))
        else
            echo -e "  🚧 $module_dir - ${YELLOW}Has $has_todos TODOs${NC}"
        fi
    done
    
    echo ""
    echo -e "📊 Progress: ${GREEN}$implemented_modules${NC}/$total_modules modules fully implemented"
    echo ""
}

# Function to create implementation plan
create_implementation_plan() {
    echo -e "${BLUE}📋 Implementation Plan:${NC}"
    echo ""
    
    cat << 'EOF'
## Priority 1: Core Infrastructure Modules (High Usage)
These modules are commonly used and should be implemented first:

1. 🖥️  virtual-machine (compute/virtual-machine)
2. 💾  managed-disk (storage/managed-disk) ✅ COMPLETED
3. 🗄️  mysql (database/mysql) ✅ COMPLETED  
4. 🗄️  cosmosdb (database/cosmosdb)
5. 🐳  aks-cluster (containers/aks-cluster)
6. 🌐  load-balancer (networking/load-balancer)

## Priority 2: Networking & Security Modules
Essential for enterprise deployments:

7. 🌐  application-gateway (networking/application-gateway)
8. 🌐  vpn-gateway (networking/vpn-gateway)
9. 🌐  route-table (networking/route-table)
10. 🔒 security-center (security/security-center)

## Priority 3: Advanced & Specialized Modules
For specific use cases:

11. 🖥️  virtual-machine-scale-set (compute/virtual-machine-scale-set)
12. 🐳  container-instance (containers/container-instance)
13. 💾  file-share (storage/file-share)
14. 🏗️  subscription (foundation/subscription)
15. 🏗️  management-group (foundation/management-group)
16. 📊  log-analytics (monitoring/log-analytics)
17. 📊  monitor-alerts (monitoring/monitor-alerts)

## Implementation Steps for Each Module:
1. Research Azure resource requirements and best practices
2. Implement main.tf with actual Azure resources
3. Define comprehensive variables.tf with validation
4. Create meaningful outputs.tf with actual resource outputs
5. Update README.md with usage examples
6. Add example configurations in examples/ directory
7. Test with terraform validate and terraform plan
8. Document security considerations and Platform 2.0 compliance

## Workflow TODOs:
- Update CI/CD workflow for InfraWeave CLI installation
- Implement module publishing logic
EOF
}

# Function to show next steps
show_next_steps() {
    echo -e "${BLUE}🚀 Recommended Next Steps:${NC}"
    echo ""
    echo "1. Focus on Priority 1 modules (high usage, high impact)"
    echo "2. Implement 2-3 modules per sprint to maintain quality"
    echo "3. Follow the established patterns from completed modules:"
    echo "   - storage/managed-disk (completed)"
    echo "   - database/mysql (completed)"
    echo "4. Each implementation should include:"
    echo "   - Real Azure resource configuration"
    echo "   - Comprehensive variable validation"
    echo "   - Security best practices"
    echo "   - Platform 2.0 compliance"
    echo "   - Usage examples and documentation"
    echo ""
}

# Main execution
echo -e "${GREEN}Total TODOs found: $(count_todos)${NC}"
echo ""

categorize_todos
show_module_status
create_implementation_plan
show_next_steps

echo -e "${GREEN}✨ Use this information to plan your next development iterations!${NC}"
