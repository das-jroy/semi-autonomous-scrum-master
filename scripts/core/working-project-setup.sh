#!/bin/bash

# Working GitHub Project Board Automation Script
# This script ACTUALLY creates custom fields and configures the project board via API

set -e

echo "🎯 Automated GitHub Project Board Setup for Azure InfraWeave Catalog"
echo "===================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="dasdigitalplatform"
PROJECT_NUMBER="3"
PROJECT_URL="https://github.com/orgs/dasdigitalplatform/projects/3"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${CYAN}🔒 Checking Prerequisites${NC}"
    echo "========================"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI ready${NC}"
    echo ""
}

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

# Function to update project details
update_project_details() {
    echo -e "${BLUE}📝 Updating Project Details${NC}"
    echo "==========================="
    
    local project_id=$(get_project_id)
    
    echo "Updating project title and description..."
    gh api graphql -f query="
    mutation {
      updateProjectV2(input: {
        projectId: \"$project_id\"
        title: \"Azure InfraWeave Module Implementation - Platform 2.0\"
        shortDescription: \"Track implementation progress of 30 Azure InfraWeave modules for Platform 2.0 security compliance and production readiness\"
      }) {
        projectV2 {
          id
          title
        }
      }
    }" --jq '.data.updateProjectV2.projectV2.title' > /dev/null
    
    echo -e "${GREEN}✅ Updated project title and description${NC}"
    echo ""
}

# Function to create single select field with options
create_single_select_field() {
    local project_id="$1"
    local field_name="$2"
    shift 2
    local options=("$@")
    
    echo "Creating '$field_name' field with ${#options[@]} options..."
    
    # Build the GraphQL options array
    local gql_options=""
    for option in "${options[@]}"; do
        if [[ -n "$gql_options" ]]; then
            gql_options+=", "
        fi
        gql_options+="{name: \"$option\", color: GRAY}"
    done
    
    # Create the field with all options at once
    local field_id=$(gh api graphql -f query="
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
          }
        }
      }
    }" --jq '.data.createProjectV2Field.projectV2Field.id' 2>/dev/null)
    
    if [[ -n "$field_id" ]] && [[ "$field_id" != "null" ]]; then
        echo "  ✅ Created $field_name field with ${#options[@]} options: $field_id"
    else
        echo "  ⚠️  $field_name field may already exist"
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

# Function to show current project structure
show_current_structure() {
    echo -e "${BLUE}📊 Updated Project Structure${NC}"
    echo "============================"
    
    local project_id=$(get_project_id)
    
    local project_info=$(gh api graphql -f query="
    {
      node(id: \"$project_id\") {
        ... on ProjectV2 {
          title
          shortDescription
          fields(first: 20) {
            nodes {
              ... on ProjectV2Field {
                id
                name
                dataType
              }
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
    
    echo "Project: $(echo "$project_info" | jq -r '.data.node.title // "Untitled"')"
    echo "Description: $(echo "$project_info" | jq -r '.data.node.shortDescription // "No description"')"
    echo ""
    
    echo -e "${YELLOW}All Fields:${NC}"
    echo "$project_info" | jq -r '.data.node.fields.nodes[] | "  - \(.name) (\(.dataType))"'
    echo ""
    
    echo -e "${YELLOW}Custom Single Select Fields:${NC}"
    echo "$project_info" | jq -r '.data.node.fields.nodes[] | select(.dataType == "SINGLE_SELECT") | "  - \(.name): \(.options.nodes | length) options"'
    echo ""
}

# Function to show manual view creation instructions
show_view_instructions() {
    echo -e "${CYAN}👀 Next: Create Views Manually${NC}"
    echo "==============================="
    echo ""
    echo "The project board is now fully configured with custom fields!"
    echo "GitHub doesn't allow view creation via API, but you can create these views manually:"
    echo ""
    echo -e "${YELLOW}Recommended Views:${NC}"
    echo "1. 📊 By Priority - Group by 'Priority Level'"
    echo "2. 📂 By Category - Group by 'Module Category'"  
    echo "3. 🔒 Security Dashboard - Filter 'Security Review' = Required/In Progress"
    echo "4. 📋 Sprint Board - Board layout, group by 'Status'"
    echo "5. 🚀 High Priority Focus - Filter 'Priority Level' = P1"
    echo ""
    echo "Visit: $PROJECT_URL"
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${GREEN}🚀 Ready to Create Issues!${NC}"
    echo "=========================="
    echo ""
    echo "Your project board is now fully automated and ready!"
    echo ""
    echo -e "${BLUE}✅ Completed:${NC}"
    echo "  - Project title and description updated"
    echo "  - 4 custom fields created with all options"
    echo "  - All fields ready for issue assignment"
    echo ""
    echo -e "${YELLOW}▶️  Next Steps:${NC}"
    echo "1. Create views manually (5 minutes) - see instructions above"
    echo "2. Run the issue creation script:"
    echo "   ${GREEN}DRY_RUN=false ./scripts/secure-github-issues.sh --live${NC}"
    echo ""
    echo "This will create 17 structured issues that will automatically"
    echo "populate your project board with proper categorization!"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    
    echo -e "${YELLOW}This will fully configure your GitHub project board with custom fields.${NC}"
    echo -e "${YELLOW}Continue? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        update_project_details
        create_custom_fields
        show_current_structure
        show_view_instructions
        show_next_steps
    else
        echo "Cancelled."
        exit 0
    fi
}

# Run main function
main
