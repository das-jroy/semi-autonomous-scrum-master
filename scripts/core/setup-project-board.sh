#!/bin/bash

# GitHub Project Board Setup Script for Azure InfraWeave Catalog
# This script configures the project board with custom fields and views

set -e

echo "🎯 GitHub Project Board Setup for Azure InfraWeave Catalog"
echo "=========================================================="

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
    
    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
        exit 1
    fi
    
    # Check authentication
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        exit 1
    fi
    
    # Check project access
    if gh api graphql -f query="
    {
      organization(login: \"$REPO_OWNER\") {
        projectV2(number: $PROJECT_NUMBER) {
          id
          title
        }
      }
    }" &> /dev/null; then
        echo -e "${GREEN}✅ Project access confirmed${NC}"
    else
        echo -e "${RED}❌ Cannot access project${NC}"
        exit 1
    fi
    
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

# Function to show current project structure
show_current_structure() {
    echo -e "${BLUE}📊 Current Project Structure${NC}"
    echo "============================"
    
    local project_id=$(get_project_id)
    
    # Get current project details
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
                  id
                  name
                }
              }
              ... on ProjectV2IterationField {
                id
                name
                dataType
              }
            }
          }
          views(first: 20) {
            nodes {
              id
              name
              layout
            }
          }
        }
      }
    }")
    
    echo "Project: $(echo "$project_info" | jq -r '.data.node.title // "Untitled"')"
    echo "Description: $(echo "$project_info" | jq -r '.data.node.shortDescription // "No description"')"
    echo ""
    
    echo -e "${YELLOW}Current Fields:${NC}"
    echo "$project_info" | jq -r '.data.node.fields.nodes[] | "  - \(.name) (\(.dataType))"'
    echo ""
    
    echo -e "${YELLOW}Current Views:${NC}"
    echo "$project_info" | jq -r '.data.node.views.nodes[] | "  - \(.name) (\(.layout))"'
    echo ""
}

# Function to create custom fields
create_custom_fields() {
    echo -e "${PURPLE}🛠️  Creating Custom Fields${NC}"
    echo "============================"
    
    local project_id=$(get_project_id)
    
    # 1. Module Category field
    echo "Creating 'Module Category' field..."
    local category_field=$(gh api graphql -f query="
    mutation {
      createProjectV2Field(input: {
        projectId: \"$project_id\"
        dataType: SINGLE_SELECT
        name: \"Module Category\"
        singleSelectOptions: [
          {name: \"Foundation\", color: \"BLUE\"}
          {name: \"Networking\", color: \"GREEN\"}
          {name: \"Compute\", color: \"YELLOW\"}
          {name: \"Storage\", color: \"ORANGE\"}
          {name: \"Database\", color: \"PURPLE\"}
          {name: \"Containers\", color: \"PINK\"}
          {name: \"Security\", color: \"RED\"}
          {name: \"Monitoring\", color: \"GRAY\"}
        ]
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
          }
        }
      }
    }" --jq '.data.createProjectV2Field.projectV2Field.id' 2>/dev/null)
    
    if [[ -n "$category_field" ]] && [[ "$category_field" != "null" ]]; then
        echo "  ✅ Created Module Category field: $category_field"
    else
        echo "  ⚠️  Module Category field may already exist or failed to create"
    fi
    
    # 2. Priority Level field
    echo "Creating 'Priority Level' field..."
    local priority_field=$(gh api graphql -f query="
    mutation {
      createProjectV2Field(input: {
        projectId: \"$project_id\"
        dataType: SINGLE_SELECT
        name: \"Priority Level\"
        singleSelectOptions: [
          {name: \"P1 - High Impact\", color: \"RED\"}
          {name: \"P2 - Enterprise\", color: \"YELLOW\"}
          {name: \"P3 - Specialized\", color: \"GREEN\"}
        ]
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
          }
        }
      }
    }" --jq '.data.createProjectV2Field.projectV2Field.id' 2>/dev/null)
    
    if [[ -n "$priority_field" ]] && [[ "$priority_field" != "null" ]]; then
        echo "  ✅ Created Priority Level field: $priority_field"
    else
        echo "  ⚠️  Priority Level field may already exist or failed to create"
    fi
    
    # 3. Complexity field
    echo "Creating 'Complexity' field..."
    local complexity_field=$(gh api graphql -f query="
    mutation {
      createProjectV2Field(input: {
        projectId: \"$project_id\"
        dataType: SINGLE_SELECT
        name: \"Complexity\"
        singleSelectOptions: [
          {name: \"Low (1-2 days)\", color: \"GREEN\"}
          {name: \"Medium (3-5 days)\", color: \"YELLOW\"}
          {name: \"High (1-2 weeks)\", color: \"RED\"}
        ]
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
          }
        }
      }
    }" --jq '.data.createProjectV2Field.projectV2Field.id' 2>/dev/null)
    
    if [[ -n "$complexity_field" ]] && [[ "$complexity_field" != "null" ]]; then
        echo "  ✅ Created Complexity field: $complexity_field"
    else
        echo "  ⚠️  Complexity field may already exist or failed to create"
    fi
    
    # 4. Security Review field
    echo "Creating 'Security Review' field..."
    local security_field=$(gh api graphql -f query="
    mutation {
      createProjectV2Field(input: {
        projectId: \"$project_id\"
        dataType: SINGLE_SELECT
        name: \"Security Review\"
        singleSelectOptions: [
          {name: \"Not Required\", color: \"GRAY\"}
          {name: \"Required\", color: \"YELLOW\"}
          {name: \"In Progress\", color: \"BLUE\"}
          {name: \"Approved\", color: \"GREEN\"}
          {name: \"Rejected\", color: \"RED\"}
        ]
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
          }
        }
      }
    }" --jq '.data.createProjectV2Field.projectV2Field.id' 2>/dev/null)
    
    if [[ -n "$security_field" ]] && [[ "$security_field" != "null" ]]; then
        echo "  ✅ Created Security Review field: $security_field"
    else
        echo "  ⚠️  Security Review field may already exist or failed to create"
    fi
    
    echo ""
}

# Function to update project details
update_project_details() {
    echo -e "${BLUE}📝 Updating Project Details${NC}"
    echo "==========================="
    
    local project_id=$(get_project_id)
    
    # Update project title and description
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
        }
      }
    }" > /dev/null 2>&1
    
    echo "  ✅ Updated project title and description"
    echo ""
}

# Function to show recommended views
show_recommended_views() {
    echo -e "${CYAN}👀 Recommended Views to Create Manually${NC}"
    echo "========================================"
    echo ""
    echo "GitHub Projects v2 doesn't support creating views via API yet."
    echo "Please create these views manually in the GitHub UI:"
    echo ""
    echo -e "${YELLOW}1. By Priority${NC}"
    echo "   - Layout: Table"
    echo "   - Group by: Priority Level"
    echo "   - Sort by: Title (ascending)"
    echo ""
    echo -e "${YELLOW}2. By Category${NC}"
    echo "   - Layout: Table"
    echo "   - Group by: Module Category"
    echo "   - Sort by: Priority Level (descending)"
    echo ""
    echo -e "${YELLOW}3. Security Dashboard${NC}"
    echo "   - Layout: Table"
    echo "   - Filter: Security Review = 'Required' OR 'In Progress'"
    echo "   - Group by: Security Review"
    echo ""
    echo -e "${YELLOW}4. Sprint Board${NC}"
    echo "   - Layout: Board"
    echo "   - Group by: Status"
    echo "   - Filter: Status != 'Complete'"
    echo ""
    echo -e "${YELLOW}5. High Priority Focus${NC}"
    echo "   - Layout: Board"
    echo "   - Filter: Priority Level = 'P1 - High Impact'"
    echo "   - Group by: Status"
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${GREEN}🚀 Next Steps${NC}"
    echo "============="
    echo ""
    echo "1. Visit your project: $PROJECT_URL"
    echo "2. Create the recommended views manually (see above)"
    echo "3. Configure any additional automation rules you need"
    echo "4. Run the issue creation script:"
    echo "   DRY_RUN=false ./scripts/secure-github-issues.sh --live"
    echo ""
    echo -e "${BLUE}📊 Project Board Features Ready:${NC}"
    echo "✅ Custom fields for categorization and tracking"
    echo "✅ Priority levels for work organization"
    echo "✅ Complexity estimates for planning"
    echo "✅ Security review workflow"
    echo "✅ Professional title and description"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    show_current_structure
    
    echo -e "${YELLOW}This will configure your GitHub project board with custom fields.${NC}"
    echo -e "${YELLOW}Continue? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        update_project_details
        create_custom_fields
        show_current_structure
        show_recommended_views
        show_next_steps
    else
        echo "Cancelled."
        exit 0
    fi
}

# Run main function
main
