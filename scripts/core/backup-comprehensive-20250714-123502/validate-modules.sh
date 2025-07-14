#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Remove the strict error handling that causes immediate exit
# set -e

# InfraWeave Module Validation Script
# This script validates all modules in the catalog. All modules are scaffolded and documented.

echo "🔍 Validating InfraWeave Catalog Modules..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_MODULES=0
PASSED_MODULES=0
FAILED_MODULES=0

# Find all module directories (containing module.yaml)
echo "📂 Discovering modules..."
MODULE_DIRS=$(find modules -name "module.yaml" -type f | xargs dirname | sort)

if [ -z "$MODULE_DIRS" ]; then
    echo -e "${RED}❌ No modules found in the catalog${NC}"
    exit 1
fi

echo "Found modules:"
for dir in $MODULE_DIRS; do
    echo "  - $dir"
    ((TOTAL_MODULES++))
done
echo ""

# Validate each module
for MODULE_DIR in $MODULE_DIRS; do
    echo -e "${YELLOW}🔍 Validating module: $MODULE_DIR${NC}"
    
    # Check required files
    REQUIRED_FILES=("module.yaml" "main.tf" "variables.tf" "outputs.tf" "versions.tf" "README.md")
    MODULE_VALID=true
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$MODULE_DIR/$file" ]; then
            echo -e "${RED}  ❌ Missing required file: $file${NC}"
            MODULE_VALID=false
        fi
    done
    
    # Validate Terraform syntax
    if [ "$MODULE_VALID" = true ]; then
        echo "  🔧 Attempting to enter directory: $MODULE_DIR"
        if cd "$MODULE_DIR" 2>/dev/null; then
            echo "  ✅ Successfully entered directory: $(pwd)"
        else
            echo -e "${RED}  ❌ Failed to enter directory: $MODULE_DIR${NC}"
            MODULE_VALID=false
            cd - > /dev/null 2>&1 || true
            continue
        fi
        
        # Clean any existing terraform state
        rm -rf .terraform .terraform.lock.hcl terraform.tfstate* 2>/dev/null || true
        
        # Terraform init (minimal) with better error reporting
        echo "  🔧 Running terraform init..."
        if terraform init -backend=false -get=false > init.log 2>&1; then
            echo -e "${GREEN}  ✅ Terraform init successful${NC}"
        else
            echo -e "${RED}  ❌ Terraform init failed${NC}"
            echo "  📝 Init error details:"
            cat init.log | head -10
            MODULE_VALID=false
        fi
        
        # Terraform validate with better error reporting
        if [ "$MODULE_VALID" = true ]; then
            echo "  🔍 Running terraform validate..."
            if terraform validate > validate.log 2>&1; then
                echo -e "${GREEN}  ✅ Terraform validation successful${NC}"
            else
                echo -e "${RED}  ❌ Terraform validation failed${NC}"
                echo "  📝 Validation error details:"
                cat validate.log | head -10
                MODULE_VALID=false
            fi
        fi
        
        # Terraform format check
        if terraform fmt -check > format.log 2>&1; then
            echo -e "${GREEN}  ✅ Terraform format check passed${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Terraform format check failed (non-blocking)${NC}"
        fi
        
        # Clean up log files
        rm -f init.log validate.log format.log 2>/dev/null || true
        
        # Return to original directory
        if cd - > /dev/null 2>&1; then
            echo "  ✅ Returned to original directory"
        else
            echo -e "${YELLOW}  ⚠️  Warning: Could not return to original directory${NC}"
        fi
    fi
    
    # Validate InfraWeave manifest
    if [ -f "$MODULE_DIR/module.yaml" ]; then
        # Check for required fields in module.yaml
        if grep -q "apiVersion: infraweave.io/v1" "$MODULE_DIR/module.yaml" && \
           grep -q "kind: Module" "$MODULE_DIR/module.yaml" && \
           grep -q "moduleName:" "$MODULE_DIR/module.yaml" && \
           grep -q "version:" "$MODULE_DIR/module.yaml"; then
            echo -e "${GREEN}  ✅ InfraWeave manifest validation passed${NC}"
        else
            echo -e "${RED}  ❌ InfraWeave manifest validation failed${NC}"
            MODULE_VALID=false
        fi
    fi
    
    # Check for examples directory
    if [ -d "$MODULE_DIR/examples" ]; then
        echo -e "${GREEN}  ✅ Examples directory found${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No examples directory found${NC}"
    fi
    
    # Update counters
    if [ "$MODULE_VALID" = true ]; then
        ((PASSED_MODULES++))
        echo -e "${GREEN}  ✅ Module validation passed${NC}"
    else
        ((FAILED_MODULES++))
        echo -e "${RED}  ❌ Module validation failed${NC}"
    fi
    
    echo ""
done

# Summary
echo "📊 Validation Summary:"
echo "  Total modules: $TOTAL_MODULES"
echo -e "  Passed: ${GREEN}$PASSED_MODULES${NC}"
echo -e "  Failed: ${RED}$FAILED_MODULES${NC}"

if [ $FAILED_MODULES -eq 0 ]; then
    echo -e "${GREEN}🎉 All modules passed validation!${NC}"
    exit 0
else
    echo -e "${RED}💥 $FAILED_MODULES module(s) failed validation${NC}"
    exit 1
fi
