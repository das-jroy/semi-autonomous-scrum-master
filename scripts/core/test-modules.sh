#!/bin/bash

# Test script for Azure InfraWeave modules
# This script runs validation tests without requiring Azure authentication

set -e

MODULE_PATH=${1:-"modules"}
VALIDATION_ONLY=${VALIDATION_ONLY:-true}

echo "🧪 Testing modules in: $MODULE_PATH"
echo "📋 Validation only mode: $VALIDATION_ONLY"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test a single example
test_example() {
    local example_dir=$1
    local module_name=$(basename $(dirname $(dirname $example_dir)))
    local example_name=$(basename $example_dir)
    
    echo -e "\n${YELLOW}🧪 Testing example: $example_dir${NC}"
    
    cd "$example_dir"
    
    # Initialize Terraform
    echo "Initializing Terraform..."
    if terraform init -no-color > init.log 2>&1; then
        echo -e "${GREEN}✅ Terraform init successful${NC}"
    else
        echo -e "${RED}❌ Terraform init failed${NC}"
        cat init.log
        cd - > /dev/null
        return 1
    fi
    
    # Validate configuration
    echo "Validating Terraform configuration..."
    if terraform validate -no-color > validate.log 2>&1; then
        echo -e "${GREEN}✅ Terraform validate successful${NC}"
    else
        echo -e "${RED}❌ Terraform validate failed${NC}"
        cat validate.log
        cd - > /dev/null
        return 1
    fi
    
    # Format check
    echo "Checking Terraform formatting..."
    if terraform fmt -check -no-color > format.log 2>&1; then
        echo -e "${GREEN}✅ Terraform format check passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Terraform format issues found${NC}"
        terraform fmt -no-color
        echo -e "${GREEN}✅ Fixed formatting${NC}"
    fi
    
    # Only run plan if we have Azure credentials and VALIDATION_ONLY is false
    if [[ "$VALIDATION_ONLY" != "true" ]]; then
        echo "Running Terraform plan..."
        if az account show > /dev/null 2>&1; then
            if terraform plan -no-color > plan.log 2>&1; then
                echo -e "${GREEN}✅ Terraform plan successful${NC}"
            else
                echo -e "${RED}❌ Terraform plan failed${NC}"
                cat plan.log
                cd - > /dev/null
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  Skipping plan - no Azure authentication${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️  Skipping plan - validation only mode${NC}"
    fi
    
    # Clean up
    rm -f *.log
    
    cd - > /dev/null
    echo -e "${GREEN}✅ Example $example_name passed all tests${NC}"
}

# Function to test a module
test_module() {
    local module_dir=$1
    local module_name=$(basename $module_dir)
    
    echo -e "\n${YELLOW}📦 Testing module: $module_name${NC}"
    
    # Test the module itself
    cd "$module_dir"
    
    # Initialize Terraform for the module
    echo "Initializing module Terraform..."
    if terraform init -no-color > init.log 2>&1; then
        echo -e "${GREEN}✅ Module init successful${NC}"
    else
        echo -e "${RED}❌ Module init failed${NC}"
        cat init.log
        cd - > /dev/null
        return 1
    fi
    
    echo "Validating module Terraform configuration..."
    if terraform validate -no-color > validate.log 2>&1; then
        echo -e "${GREEN}✅ Module validation successful${NC}"
    else
        echo -e "${RED}❌ Module validation failed${NC}"
        cat validate.log
        cd - > /dev/null
        return 1
    fi
    
    # Format check for the module
    echo "Checking module Terraform formatting..."
    if terraform fmt -check -no-color > format.log 2>&1; then
        echo -e "${GREEN}✅ Module format check passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Module format issues found${NC}"
        terraform fmt -no-color
        echo -e "${GREEN}✅ Fixed module formatting${NC}"
    fi
    
    # Clean up
    rm -f *.log
    cd - > /dev/null
    
    # Test examples if they exist
    if [[ -d "$module_dir/examples" ]]; then
        for example in "$module_dir/examples"/*; do
            if [[ -d "$example" && -f "$example/main.tf" ]]; then
                test_example "$example"
            fi
        done
    else
        echo -e "${YELLOW}ℹ️  No examples directory found for $module_name${NC}"
    fi
}

# Main execution
failed_tests=0
total_tests=0

if [[ -f "$MODULE_PATH/main.tf" ]]; then
    # Single module test
    total_tests=1
    if test_module "$MODULE_PATH"; then
        echo -e "\n${GREEN}🎉 All tests passed for module: $(basename $MODULE_PATH)${NC}"
    else
        failed_tests=1
        echo -e "\n${RED}💥 Tests failed for module: $(basename $MODULE_PATH)${NC}"
    fi
else
    # Multiple modules test
    for category_dir in "$MODULE_PATH"/*; do
        if [[ -d "$category_dir" ]]; then
            for module_dir in "$category_dir"/*; do
                if [[ -d "$module_dir" && -f "$module_dir/main.tf" ]]; then
                    total_tests=$((total_tests + 1))
                    if ! test_module "$module_dir"; then
                        failed_tests=$((failed_tests + 1))
                    fi
                fi
            done
        fi
    done
fi

# Summary
echo -e "\n${YELLOW}📊 Test Summary:${NC}"
echo -e "Total modules tested: $total_tests"
echo -e "Failed tests: $failed_tests"
echo -e "Passed tests: $((total_tests - failed_tests))"

if [[ $failed_tests -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 $failed_tests test(s) failed!${NC}"
    exit 1
fi
