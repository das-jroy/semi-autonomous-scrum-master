#!/bin/bash

# Repository Genericization Validation
# Validates that the repository is properly genericized

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Repository Genericization Validation${NC}"
echo "======================================="
echo ""

ISSUES_FOUND=0

# Function to report issue
report_issue() {
    local severity="$1"
    local message="$2"
    local file="$3"
    
    if [[ "$severity" == "ERROR" ]]; then
        echo -e "${RED}❌ ERROR: $message${NC}"
        [[ -n "$file" ]] && echo -e "   File: $file"
        ((ISSUES_FOUND++))
    elif [[ "$severity" == "WARNING" ]]; then
        echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
        [[ -n "$file" ]] && echo -e "   File: $file"
    else
        echo -e "${GREEN}✅ $message${NC}"
    fi
}

# Function to check for hardcoded values in files
check_hardcoded_values() {
    local file="$1"
    local issues=0
    
    # Skip our own utility scripts that may contain example references
    local filename=$(basename "$file")
    if [[ "$filename" == "batch-fix-hardcoded.sh" ]] || \
       [[ "$filename" == "comprehensive-fix.sh" ]] || \
       [[ "$filename" == "validate-genericization.sh" ]]; then
        return 0
    fi
    
    # Check for old repository references
    if grep -q "dasdigitalplatform" "$file" 2>/dev/null; then
        report_issue "ERROR" "Found hardcoded 'dasdigitalplatform' reference" "$file"
        ((issues++))
    fi
    
    if grep -q "vanguard-az-infraweave" "$file" 2>/dev/null; then
        report_issue "ERROR" "Found hardcoded 'vanguard-az-infraweave' reference" "$file"
        ((issues++))
    fi
    
    if grep -q "Azure InfraWeave" "$file" 2>/dev/null; then
        report_issue "ERROR" "Found hardcoded 'Azure InfraWeave' reference" "$file"
        ((issues++))
    fi
    
    # Check for hardcoded project IDs
    if grep -qE 'PROJECT_ID="[0-9]+"' "$file" 2>/dev/null; then
        report_issue "ERROR" "Found hardcoded PROJECT_ID" "$file"
        ((issues++))
    fi
    
    return $issues
}

echo -e "${BLUE}1. Checking core scripts for hardcoded values...${NC}"

# Check all shell scripts
total_files=0
clean_files=0

for script in scripts/core/*.sh; do
    if [[ -f "$script" ]]; then
        ((total_files++))
        if check_hardcoded_values "$script"; then
            ((clean_files++))
        fi
    fi
done

echo "   Checked $total_files scripts"
echo ""

echo -e "${BLUE}2. Checking configuration system...${NC}"

# Check if configuration files exist
if [[ -f "configs/project-config.json.template" ]]; then
    report_issue "OK" "Configuration template exists"
else
    report_issue "ERROR" "Missing configuration template"
fi

if [[ -d "configs/project-types" ]] && [[ $(ls -1 configs/project-types/*.json 2>/dev/null | wc -l) -gt 0 ]]; then
    report_issue "OK" "Project type templates exist"
else
    report_issue "ERROR" "Missing project type templates"
fi

if [[ -d "configs/team-profiles" ]] && [[ $(ls -1 configs/team-profiles/*.json 2>/dev/null | wc -l) -gt 0 ]]; then
    report_issue "OK" "Team profile templates exist"
else
    report_issue "ERROR" "Missing team profile templates"
fi

if [[ -d "configs/sprint-templates" ]] && [[ $(ls -1 configs/sprint-templates/*.json 2>/dev/null | wc -l) -gt 0 ]]; then
    report_issue "OK" "Sprint templates exist"
else
    report_issue "ERROR" "Missing sprint templates"
fi

echo ""

echo -e "${BLUE}3. Checking helper scripts...${NC}"

if [[ -f "scripts/core/config-helper.sh" ]]; then
    report_issue "OK" "Configuration helper script exists"
else
    report_issue "ERROR" "Missing configuration helper script"
fi

if [[ -f "scripts/core/setup-wizard.sh" ]]; then
    report_issue "OK" "Setup wizard exists"
else
    report_issue "WARNING" "Setup wizard missing (recommended)"
fi

echo ""

echo -e "${BLUE}4. Checking documentation...${NC}"

# Check if documentation mentions specific projects
if grep -q "Azure InfraWeave" README.md 2>/dev/null; then
    report_issue "ERROR" "README still contains project-specific references"
elif grep -q "dasdigitalplatform" README.md 2>/dev/null; then
    report_issue "ERROR" "README still contains hardcoded organization"
else
    report_issue "OK" "README appears generic"
fi

echo ""

echo -e "${BLUE}5. Checking example documentation...${NC}"

if [[ -f "examples/sample-docs/sample-project.md" ]]; then
    # Check for remaining hardcoded values (not the ones we intentionally use as generic examples)
    if grep -q "InfraWeave\|dasdigitalplatform" "examples/sample-docs/sample-project.md" 2>/dev/null; then
        report_issue "WARNING" "Sample documentation contains project-specific references"
    else
        report_issue "OK" "Sample documentation is generic"
    fi
else
    report_issue "WARNING" "No sample documentation found"
fi

echo ""

# Final summary
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "==================="

if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo -e "${GREEN}🎉 Repository is properly genericized!${NC}"
    echo ""
    echo "✅ No hardcoded values found"
    echo "✅ Configuration system in place"
    echo "✅ Templates available"
    echo "✅ Documentation updated"
    echo ""
    echo "Your repository is ready for use with any project!"
    exit 0
else
    echo -e "${RED}❌ Found $ISSUES_FOUND issues that need to be addressed${NC}"
    echo ""
    echo "Please fix the issues above and run the validation again:"
    echo "  ./scripts/core/validate-genericization.sh"
    exit 1
fi
