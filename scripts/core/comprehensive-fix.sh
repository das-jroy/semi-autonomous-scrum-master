#!/bin/bash

# Comprehensive Fix Script - Remove ALL hardcoded values from scripts
# This script systematically fixes ALL hardcoded repository and project references

set -e

echo "🔧 Comprehensive Fix for ALL Hardcoded Values"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPTS_DIR="scripts/core"
BACKUP_DIR="scripts/core/backup-comprehensive-$(date +%Y%m%d-%H%M%S)"

# Create backup directory
echo -e "${BLUE}📦 Creating comprehensive backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$SCRIPTS_DIR"/*.sh "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup created in: $BACKUP_DIR${NC}"

# Function to comprehensively fix a script
comprehensive_fix() {
    local script_file="$1"
    local script_name=$(basename "$script_file")
    
    echo -e "${BLUE}🔧 Comprehensively fixing: $script_name${NC}"
    
    # Skip our own scripts to avoid recursive issues
    if [[ "$script_name" == "batch-fix-hardcoded.sh" ]] || \
       [[ "$script_name" == "comprehensive-fix.sh" ]] || \
       [[ "$script_name" == "config-helper.sh" ]] || \
       [[ "$script_name" == "setup-wizard.sh" ]] || \
       [[ "$script_name" == "validate-genericization.sh" ]]; then
        echo -e "${YELLOW}  ⏭️  Skipping utility script${NC}"
        return
    fi
    
    # Create a temporary file for modifications
    local temp_file=$(mktemp)
    
    # Add configuration loading if not present
    if ! grep -q "config-helper.sh" "$script_file"; then
        # Insert configuration loading after shebang
        awk '
        FNR==1 {print; print ""; print "# Load configuration"; print "SCRIPT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\""; print "source \"$SCRIPT_DIR/config-helper.sh\""; print ""; next}
        {print}
        ' "$script_file" > "$temp_file"
    else
        cp "$script_file" "$temp_file"
    fi
    
    # Comprehensive replacement of hardcoded values
    sed -i.bak \
        -e 's/dasdigitalplatform/$REPO_OWNER/g' \
        -e 's/vanguard-az-infraweave-catalog/$REPO_NAME/g' \
        -e 's/vanguard-az-infraweave/$REPO_NAME/g' \
        -e 's/"Azure InfraWeave[^"]*"/"$PROJECT_NAME"/g' \
        -e 's/Azure InfraWeave[^"[:space:]]*/$PROJECT_NAME/g' \
        -e 's/Azure InfraWeave/$PROJECT_NAME/g' \
        -e 's/REPO_OWNER="[^"]*"/# REPO_OWNER loaded from config/g' \
        -e 's/REPO_NAME="[^"]*"/# REPO_NAME loaded from config/g' \
        -e 's/PROJECT_ID="[0-9]*"/# PROJECT_ID loaded from config/g' \
        -e 's/OWNER="[^"]*"/# OWNER loaded from config/g' \
        -e 's/REPO="[^"]*"/# REPO loaded from config/g' \
        "$temp_file"
    
    # Handle specific patterns that need load_config call
    if ! grep -q "load_config" "$temp_file"; then
        # Add load_config after source config-helper.sh
        sed -i.bak '/source.*config-helper\.sh/a\
\
# Load project configuration\
load_config
' "$temp_file"
    fi
    
    # Clean up .bak files and move result
    rm -f "$temp_file.bak"
    mv "$temp_file" "$script_file"
    
    echo -e "${GREEN}  ✅ Fixed $script_name${NC}"
}

# Get all shell scripts
scripts=($(find "$SCRIPTS_DIR" -name "*.sh" -type f))

echo -e "${YELLOW}📝 Fixing ${#scripts[@]} scripts comprehensively...${NC}"

for script in "${scripts[@]}"; do
    comprehensive_fix "$script"
done

# Fix the sample documentation as well
echo -e "${BLUE}📝 Fixing sample documentation...${NC}"
SAMPLE_DOC="examples/sample-docs/sample-project.md"
if [[ -f "$SAMPLE_DOC" ]]; then
    sed -i.bak \
        -e 's/Azure[[:space:]]*InfraWeave/Sample Project/g' \
        -e 's/dasdigitalplatform/your-org/g' \
        -e 's/vanguard-az-infraweave/your-project/g' \
        "$SAMPLE_DOC"
    rm -f "$SAMPLE_DOC.bak"
    echo -e "${GREEN}✅ Fixed sample documentation${NC}"
fi

# Fix automation inventory
echo -e "${BLUE}📝 Fixing documentation...${NC}"
DOCS_TO_FIX=(
    "docs/automation-inventory.md"
    "docs/complete-script-inventory.md"
)

for doc in "${DOCS_TO_FIX[@]}"; do
    if [[ -f "$doc" ]]; then
        sed -i.bak \
            -e 's/Azure InfraWeave/Generic Project/g' \
            -e 's/dasdigitalplatform/your-organization/g' \
            -e 's/vanguard-az-infraweave/your-repository/g' \
            "$doc"
        rm -f "$doc.bak"
        echo -e "${GREEN}✅ Fixed $(basename "$doc")${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Comprehensive fix completed!${NC}"
echo ""
echo "Fixed:"
echo "- ${#scripts[@]} shell scripts"
echo "- Sample documentation"
echo "- Automation inventory"
echo ""
echo "Next steps:"
echo "1. Run validation: ./scripts/core/validate-genericization.sh"
echo "2. Test with your project configuration"
echo ""
echo "If you need to restore:"
echo "  cp $BACKUP_DIR/*.sh $SCRIPTS_DIR/"
