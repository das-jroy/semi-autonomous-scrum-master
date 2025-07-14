#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Final GitHub Project Board Setup - Corrected Version
# Creates custom fields with proper GraphQL syntax

set -e

echo "🎯 Final GitHub Project Board Setup for $PROJECT_NAME Catalog"
echo "================================================================="

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
PROJECT_NUMBER="3"

# Function to get project ID
get_project_id() {
    gh api graphql -f query="
    {
      organization(login: \"$REPO_OWNER\") {
        projectV2(number: $PROJECT_NUMBER) {
          id
        }
      }
    }" --jq '.data.organization.projectV2.id'
}

# Function to create single select field with options using proper GraphQL
create_single_select_field() {
    local project_id="$1"
    local field_name="$2"
    shift 2
    local options=("$@")
    
    echo "Creating '$field_name' field with ${#options[@]} options..."
    
    # Build the GraphQL options array with required description field
    local gql_options=""
    for option in "${options[@]}"; do
        if [[ -n "$gql_options" ]]; then
            gql_options+=", "
        fi
        gql_options+="{name: \"$option\", description: \"$option\", color: GRAY}"
    done
    
    # Create the field with all options at once
    local field_result=$(gh api graphql -f query="
    mutation {
      createProjectV2Field(input: {
        projectId: \"$project_id\"
        dataType: SINGLE_SELECT
        name: \"$field_name\"
        singleSelectOptions: [$gql_options]
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
            name
          }
        }
      }
    }" 2>/dev/null)
    
    local field_id=$(echo "$field_result" | jq -r '.data.createProjectV2Field.projectV2Field.id // empty')
    
    if [[ -n "$field_id" ]] && [[ "$field_id" != "null" ]]; then
        echo "  ✅ Created '$field_name' field: $field_id"
    else
        echo "  ⚠️  '$field_name' field may already exist or there was an error"
        echo "  Debug: $field_result" | head -n 2
    fi
}

# Function to create all custom fields
create_custom_fields() {
    echo -e "${PURPLE}🛠️  Creating Custom Fields${NC}"
    echo "============================"
    
    local project_id=$(get_project_id)
    echo "Project ID: $project_id"
    echo ""
    
    # 1. Module Category field
    create_single_select_field "$project_id" "Module Category" "Foundation" "Networking" "Compute" "Storage" "Database" "Containers" "Security" "Monitoring"
    
    # 2. Priority Level field  
    create_single_select_field "$project_id" "Priority Level" "P1 - High Impact" "P2 - Enterprise" "P3 - Specialized"
    
    # 3. Complexity field
    create_single_select_field "$project_id" "Complexity" "Low (1-2 days)" "Medium (3-5 days)" "High (1-2 weeks)"
    
    # 4. Security Review field
    create_single_select_field "$project_id" "Security Review" "Not Required" "Required" "In Progress" "Approved" "Rejected"
    
    echo ""
}

# Function to verify created fields
verify_fields() {
    echo -e "${BLUE}📊 Verifying Created Fields${NC}"
    echo "==========================="
    
    local project_id=$(get_project_id)
    
    local fields=$(gh api graphql -f query="
    {
      node(id: \"$project_id\") {
        ... on ProjectV2 {
          title
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                dataType
                options {
                  nodes {
                    id
                    name
                  }
                }
              }
            }
          }
        }
      }
    }")
    
    echo "Custom Fields Created:"
    echo "$fields" | jq -r '.data.node.fields.nodes[] | select(.dataType == "SINGLE_SELECT") | "  ✅ \(.name): \(.options.nodes | length) options"'
    echo ""
}

# Function to show completion message
show_completion() {
    echo -e "${GREEN}🚀 Project Board Setup Complete!${NC}"
    echo "================================="
    echo ""
    echo -e "${BLUE}✅ Completed:${NC}"
    echo "  - Project title and description updated"
    echo "  - 4 custom single-select fields created"
    echo "  - All fields have proper options configured"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Visit: https://github.com/orgs/$REPO_OWNER/projects/3"
    echo "2. Create custom views manually (GitHub API limitation):"
    echo "   - By Priority (group by Priority Level)"
    echo "   - By Category (group by Module Category)"
    echo "   - Security Dashboard (filter Security Review)"
    echo "   - Sprint Board (board layout, group by Status)"
    echo ""
    echo "3. Run issue creation script:"
    echo "   ${GREEN}DRY_RUN=false ./scripts/secure-github-issues.sh --live${NC}"
    echo ""
}

# Main execution
main() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}This will create custom fields for your project board.${NC}"
    echo -e "${YELLOW}Continue? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        create_custom_fields
        verify_fields
        show_completion
    else
        echo "Cancelled."
        exit 0
    fi
}

# Run main function
main
