#!/bin/bash

# Batch Fix Script - Remove hardcoded values from all scripts
# This script systematically fixes hardcoded repository and project references

set -e

echo "🔧 Batch Fixing Hardcoded Values in Scripts"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPTS_DIR="scripts/core"
BACKUP_DIR="scripts/core/backup-$(date +%Y%m%d-%H%M%S)"

# Create backup directory
echo -e "${BLUE}📦 Creating backup of original scripts...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$SCRIPTS_DIR"/*.sh "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup created in: $BACKUP_DIR${NC}"

# Function to fix a script
fix_script() {
    local script_file="$1"
    local script_name=$(basename "$script_file")
    
    echo -e "${BLUE}🔧 Fixing: $script_name${NC}"
    
    # Add configuration loading to scripts that don't have it
    if ! grep -q "config-helper.sh" "$script_file"; then
        # Add configuration loading after shebang and before main logic
        sed -i.bak '2i\
\
# Load configuration\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
source "$SCRIPT_DIR/config-helper.sh"
' "$script_file"
    fi
    
    # Replace hardcoded repository values
    sed -i.bak \
        -e 's/dasdigitalplatform/$REPO_OWNER/g' \
        -e 's/vanguard-az-infraweave-catalog/$REPO_NAME/g' \
        -e 's/Azure InfraWeave[^"]*/$PROJECT_NAME/g' \
        -e 's/REPO_OWNER="[^"]*"/# REPO_OWNER loaded from config/g' \
        -e 's/REPO_NAME="[^"]*"/# REPO_NAME loaded from config/g' \
        -e 's/PROJECT_ID="[^"]*"/# PROJECT_ID loaded from config/g' \
        -e 's/OWNER="[^"]*"/# OWNER loaded from config/g' \
        "$script_file"
    
    # Remove .bak files
    rm -f "$script_file.bak"
    
    echo -e "${GREEN}  ✅ Fixed $script_name${NC}"
}

# List of scripts that need configuration loading
SCRIPTS_TO_FIX=(
    "set-issue-types.sh"
    "set-native-issue-types.sh"
    "verify-kanban-status.sh"
    "add-kanban-columns.sh"
    "planning-stage-summary.sh"
    "complete-final-status.sh"
    "implementation-checklist.sh"
    "enhance-roadmap-workflow.sh"
    "field-value-analysis.sh"
    "secure-github-issues.sh"
    "todo-management.sh"
    "final-status-report.sh"
    "status-lane-optimization.sh"
)

echo -e "${YELLOW}📝 Fixing ${#SCRIPTS_TO_FIX[@]} scripts...${NC}"

for script in "${SCRIPTS_TO_FIX[@]}"; do
    script_path="$SCRIPTS_DIR/$script"
    if [[ -f "$script_path" ]]; then
        fix_script "$script_path"
    else
        echo -e "${YELLOW}  ⚠️  Script not found: $script${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Batch fix completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the fixed scripts in $SCRIPTS_DIR"
echo "2. Update your project configuration in configs/project-config.json"
echo "3. Test the scripts with your project"
echo ""
echo "If you need to restore the original scripts:"
echo "  cp $BACKUP_DIR/*.sh $SCRIPTS_DIR/"
