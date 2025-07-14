#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Comprehensive Module Health Check Script
# This script performs all the checks that the CI/CD pipeline runs

set -e

echo "🏥 COMPREHENSIVE MODULE HEALTH CHECK"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "modules" ]; then
    echo -e "${RED}❌ Please run this script from the root of the $REPO_NAME repository${NC}"
    exit 1
fi

echo -e "${BLUE}📂 STEP 1: Module Discovery${NC}"
echo "----------------------------"

MODULE_DIRS=$(find modules -name "module.yaml" -type f | xargs dirname | sort)

if [ -z "$MODULE_DIRS" ]; then
    echo -e "${RED}❌ No modules found in the catalog${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found modules:${NC}"
for dir in $MODULE_DIRS; do
    echo "  • $dir"
done
echo ""

echo -e "${BLUE}📋 STEP 2: Required Files Check${NC}"
echo "--------------------------------"

for MODULE_DIR in $MODULE_DIRS; do
    echo -e "${YELLOW}Checking $MODULE_DIR:${NC}"
    
    REQUIRED_FILES=("module.yaml" "main.tf" "variables.tf" "outputs.tf" "versions.tf" "README.md")
    ALL_FILES_PRESENT=true
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$MODULE_DIR/$file" ]; then
            echo -e "  ✅ $file"
        else
            echo -e "  ${RED}❌ MISSING: $file${NC}"
            ALL_FILES_PRESENT=false
        fi
    done
    
    if [ "$ALL_FILES_PRESENT" = true ]; then
        echo -e "  ${GREEN}✅ All required files present${NC}"
    else
        echo -e "  ${RED}❌ Missing required files${NC}"
    fi
    echo ""
done

echo -e "${BLUE}🔍 STEP 3: InfraWeave Manifest Validation${NC}"
echo "-------------------------------------------"

for MODULE_DIR in $MODULE_DIRS; do
    echo -e "${YELLOW}Checking $MODULE_DIR/module.yaml:${NC}"
    yaml_file="$MODULE_DIR/module.yaml"
    
    # Check required fields
    if grep -q "apiVersion: infraweave.io/v1" "$yaml_file"; then
        echo -e "  ✅ apiVersion: infraweave.io/v1"
    else
        echo -e "  ${RED}❌ Missing or incorrect apiVersion (should be 'infraweave.io/v1')${NC}"
        echo -e "     Current: $(grep "apiVersion:" "$yaml_file" || echo "not found")"
    fi
    
    if grep -q "kind: Module" "$yaml_file"; then
        echo -e "  ✅ kind: Module"
    else
        echo -e "  ${RED}❌ Missing or incorrect kind (should be 'Module')${NC}"
        echo -e "     Current: $(grep "kind:" "$yaml_file" || echo "not found")"
    fi
    
    if grep -q "moduleName:" "$yaml_file"; then
        module_name=$(grep "moduleName:" "$yaml_file" | sed 's/.*moduleName: *//')
        echo -e "  ✅ moduleName: $module_name"
    else
        echo -e "  ${RED}❌ Missing moduleName field${NC}"
    fi
    
    if grep -q "version:" "$yaml_file"; then
        version=$(grep "version:" "$yaml_file" | head -1 | sed 's/.*version: *//')
        echo -e "  ✅ version: $version"
    else
        echo -e "  ${RED}❌ Missing version field${NC}"
    fi
    echo ""
done

echo -e "${BLUE}🔧 STEP 4: Terraform Validation${NC}"
echo "--------------------------------"

for MODULE_DIR in $MODULE_DIRS; do
    echo -e "${YELLOW}Validating $MODULE_DIR:${NC}"
    
    cd "$MODULE_DIR"
    
    # Clean any existing state
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate* 2>/dev/null || true
    
    # Terraform init
    echo "  🔧 Running terraform init..."
    if terraform init -backend=false -get=false > init.log 2>&1; then
        echo -e "  ✅ Terraform init successful"
    else
        echo -e "  ${RED}❌ Terraform init failed${NC}"
        echo -e "  ${RED}Error details:${NC}"
        cat init.log | head -20
        cd - > /dev/null
        continue
    fi
    
    # Terraform validate
    echo "  🔍 Running terraform validate..."
    if terraform validate > validate.log 2>&1; then
        echo -e "  ✅ Terraform validate successful"
    else
        echo -e "  ${RED}❌ Terraform validate failed${NC}"
        echo -e "  ${RED}Error details:${NC}"
        cat validate.log | head -20
        cd - > /dev/null
        continue
    fi
    
    # Terraform format check
    echo "  🎨 Running terraform fmt check..."
    if terraform fmt -check > format.log 2>&1; then
        echo -e "  ✅ Terraform format check passed"
    else
        echo -e "  ${YELLOW}⚠️  Terraform format issues found (can be auto-fixed)${NC}"
        echo "  Run 'terraform fmt' in the module directory to fix"
    fi
    
    # Clean up
    rm -f init.log validate.log format.log 2>/dev/null || true
    
    cd - > /dev/null
    echo ""
done

echo -e "${BLUE}📊 STEP 5: Summary${NC}"
echo "------------------"
echo ""
echo -e "${GREEN}🎉 Health check completed!${NC}"
echo ""
echo "If all steps show ✅ marks, your modules should pass CI/CD validation."
echo "If you see ❌ marks, fix those issues and re-run this script."
echo ""
echo "Common fixes:"
echo "• Add missing files (create empty outputs.tf if no outputs needed)"
echo "• Fix module.yaml format (ensure apiVersion, kind, moduleName, version are correct)"
echo "• Run 'terraform fmt' to fix formatting issues"
echo "• Run 'terraform init && terraform validate' in each module directory"
echo ""
