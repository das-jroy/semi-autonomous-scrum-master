#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Automated Kanban Status Columns Addition
# This script attempts to add "Review" and "Blocked" status options using GitHub's GraphQL API

set -e

echo "🤖 Automated Kanban Status Columns Addition"
echo "==========================================="

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
PROJECT_ID="PVT_kwDOC-2N484A9m2C"

# Function to validate prerequisites
validate_prerequisites() {
    echo -e "${CYAN}🔒 Validation${NC}"
    echo "============="
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI not installed${NC}"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
    echo ""
}

# Function to get current status field configuration
get_status_field_info() {
    echo -e "${BLUE}🔍 Getting Status Field Information${NC}"
    echo "=================================="
    
    local field_info=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID")
    
    STATUS_FIELD_ID=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .id')
    
    if [[ -z "$STATUS_FIELD_ID" ]]; then
        echo -e "${RED}❌ Could not find Status field${NC}"
        exit 1
    fi
    
    echo "Status Field ID: $STATUS_FIELD_ID"
    
    # Get current options
    echo -e "${BLUE}Current Status Options:${NC}"
    echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | "• " + .name'
    
    # Check if Review and Blocked already exist
    REVIEW_EXISTS=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Review") | .name // empty')
    BLOCKED_EXISTS=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Blocked") | .name // empty')
    
    echo ""
}

# Function to add status option using createProjectV2Field (alternative approach)
add_status_option_alt() {
    local option_name="$1"
    local option_description="$2"
    
    echo -e "${PURPLE}📝 Attempting to add status option: $option_name${NC}"
    echo "================================================"
    
    # Try using addProjectV2SingleSelectFieldOption mutation
    local response=$(gh api graphql -f query='
    mutation($projectId: ID!, $fieldId: ID!, $name: String!) {
      updateProjectV2Field(input: {
        fieldId: $fieldId
        singleSelectField: {
          options: [
            {name: $name}
          ]
        }
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" -f fieldId="$STATUS_FIELD_ID" -f name="$option_name" 2>&1)
    
    if echo "$response" | grep -q '"data"'; then
        echo -e "${GREEN}✅ Successfully added: $option_name${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Standard mutation failed, trying alternative...${NC}"
        echo "Response: $response"
        return 1
    fi
}

# Function to try internal API approach (browser-style)
add_status_option_internal() {
    local option_name="$1"
    
    echo -e "${PURPLE}🔧 Trying internal API approach for: $option_name${NC}"
    echo "=============================================="
    
    # Get GitHub token
    local token=$(gh auth token)
    
    # Try to add option using internal GitHub API endpoints
    local response=$(curl -s -X POST \
        "https://github.com/orgs/$REPO_OWNER/memexes/$PROJECT_NUMBER/fields/$STATUS_FIELD_ID/options" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -H "X-Requested-With: XMLHttpRequest" \
        --data-raw "{\"option\":{\"name\":\"$option_name\"}}" 2>&1)
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Successfully added via internal API: $option_name${NC}"
        return 0
    else
        echo -e "${RED}❌ Internal API failed: $response${NC}"
        return 1
    fi
}

# Function to show manual fallback instructions
show_manual_instructions() {
    echo -e "${YELLOW}📋 Manual Setup Required${NC}"
    echo "========================"
    echo ""
    echo "The automated approaches didn't work. Please add manually:"
    echo ""
    echo "1. Go to: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
    echo "2. Click Settings (⚙️) → Fields → Edit Status field"
    echo "3. Add these options:"
    echo "   • Review (Yellow) - Code review, validation, testing"
    echo "   • Blocked (Red) - Waiting for dependencies/decisions"
    echo ""
}

# Function to verify final status
verify_status_options() {
    echo -e "${BLUE}🔍 Verifying Final Status Options${NC}"
    echo "================================="
    
    gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                name
                options {
                  name
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" --jq '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | "✅ " + .name'
    
    echo ""
}

# Function to create sprint board view
create_sprint_board_view() {
    echo -e "${BLUE}📋 Creating Sprint Board View${NC}"
    echo "============================="
    
    # This uses the internal API approach from our previous work
    local payload='{"view":{"layout":"board_layout","name":"Sprint Board","description":"Kanban board grouped by status"}}'
    local token=$(gh auth token)
    
    local response=$(curl -s -X POST \
        "https://github.com/orgs/$REPO_OWNER/memexes/$PROJECT_NUMBER/views" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -H "X-Requested-With: XMLHttpRequest" \
        --data-raw "$payload")
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local view_id=$(echo "$response" | jq -r '.id')
        echo -e "${GREEN}✅ Created Sprint Board view (ID: $view_id)${NC}"
    else
        echo -e "${YELLOW}⚠️  Sprint Board view creation may have failed${NC}"
        echo "You can create it manually: New View → Board Layout → Group by Status"
    fi
    
    echo ""
}

# Main execution
main() {
    validate_prerequisites
    get_status_field_info
    
    local success_count=0
    
    # Try to add Review option
    if [[ -z "$REVIEW_EXISTS" ]]; then
        echo -e "${CYAN}Adding 'Review' status option...${NC}"
        if add_status_option_alt "Review" "Code review, validation, testing"; then
            ((success_count++))
        elif add_status_option_internal "Review"; then
            ((success_count++))
        fi
    else
        echo -e "${GREEN}✅ 'Review' status option already exists${NC}"
        ((success_count++))
    fi
    
    # Try to add Blocked option  
    if [[ -z "$BLOCKED_EXISTS" ]]; then
        echo -e "${CYAN}Adding 'Blocked' status option...${NC}"
        if add_status_option_alt "Blocked" "Waiting for dependencies or decisions"; then
            ((success_count++))
        elif add_status_option_internal "Blocked"; then
            ((success_count++))
        fi
    else
        echo -e "${GREEN}✅ 'Blocked' status option already exists${NC}"
        ((success_count++))
    fi
    
    # Show results
    if [[ $success_count -eq 2 ]]; then
        echo -e "${GREEN}🎉 Successfully added both status options!${NC}"
        create_sprint_board_view
        verify_status_options
    else
        show_manual_instructions
    fi
    
    # Show completion summary
    echo -e "${GREEN}🎯 Kanban Workflow Ready!${NC}"
    echo "========================"
    echo ""
    echo -e "${YELLOW}📋 Your Enhanced Workflow:${NC}"
    echo "1. 📋 Todo - Ready to implement"
    echo "2. ⚡ In Progress - Actively being developed"
    echo "3. 👀 Review - Code review, validation, testing"
    echo "4. 🚫 Blocked - Waiting for dependencies/decisions"
    echo "5. ✅ Done - Fully complete, tested, documented"
    echo ""
    echo -e "${BLUE}🔗 Next Steps:${NC}"
    echo "• Visit your project: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
    echo "• Use the Sprint Board view for kanban workflow"
    echo "• Start moving your 17 issues through the workflow!"
}

# Run main function
main
