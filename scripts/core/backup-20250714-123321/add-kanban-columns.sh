#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Add Additional Status Columns to Project Board
# This script adds "Review" and "Blocked" status options to the existing kanban board

set -e

echo "📋 Adding Kanban Status Columns"
echo "==============================="

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

# Function to get the Status field ID
get_status_field_id() {
    echo -e "${BLUE}🔍 Getting Status Field ID${NC}"
    echo "=========================="
    
    STATUS_FIELD_ID=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" --jq '.data.node.fields.nodes[] | select(.name == "Status") | .id')
    
    if [[ -z "$STATUS_FIELD_ID" ]]; then
        echo -e "${RED}❌ Could not find Status field${NC}"
        exit 1
    fi
    
    echo "Status Field ID: $STATUS_FIELD_ID"
    echo ""
}

# Function to add a status option
add_status_option() {
    local option_name="$1"
    local option_color="$2"
    
    echo -e "${PURPLE}📝 Adding Status Option: $option_name${NC}"
    echo "================================="
    
    # Add the new option to the Status field
    local response=$(gh api graphql -f query='
    mutation($projectId: ID!, $fieldId: ID!, $name: String!, $color: String!) {
      updateProjectV2Field(input: {
        projectId: $projectId
        fieldId: $fieldId
        singleSelectField: {
          options: [
            {name: $name, color: $color}
          ]
        }
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
            options {
              id
              name
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" -f fieldId="$STATUS_FIELD_ID" -f name="$option_name" -f color="$option_color")
    
    # Check if successful
    if echo "$response" | jq -e '.data.updateProjectV2Field' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Added status option: $option_name${NC}"
    else
        echo -e "${YELLOW}⚠️  May have failed or option already exists${NC}"
        echo "Response: $response"
    fi
    
    echo ""
}

# Function to show current status options
show_current_status() {
    echo -e "${BLUE}📊 Current Status Options${NC}"
    echo "========================="
    
    gh api graphql -f query='
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
    }' -f projectId="$PROJECT_ID" --jq '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | "• " + .name'
    
    echo ""
}

# Function to show completion summary
show_completion_summary() {
    echo -e "${GREEN}🎉 Kanban Status Columns Updated!${NC}"
    echo "=================================="
    echo ""
    echo -e "${YELLOW}📋 Your Kanban Workflow:${NC}"
    echo "1. 📋 Todo - Ready to implement"
    echo "2. ⚡ In Progress - Actively being developed"
    echo "3. 👀 Review - Code review, validation, testing"
    echo "4. 🚫 Blocked - Waiting for dependencies/decisions"
    echo "5. ✅ Done - Fully complete, tested, documented"
    echo ""
    echo -e "${BLUE}🔗 Next Steps:${NC}"
    echo "1. Visit your project board: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
    echo "2. Create a 'Sprint Board' view grouped by Status"
    echo "3. Start moving issues through the workflow!"
    echo ""
    echo -e "${CYAN}💡 Workflow Tips:${NC}"
    echo "• Use 'Review' for issues that need validation or code review"
    echo "• Use 'Blocked' for issues waiting on dependencies or decisions"
    echo "• Move to 'Done' only when fully complete with documentation"
    echo ""
}

# Main execution
main() {
    validate_prerequisites
    get_status_field_id
    
    echo -e "${BLUE}📊 Current Status Before Changes:${NC}"
    show_current_status
    
    # Add the two new status options
    add_status_option "Review" "YELLOW"
    add_status_option "Blocked" "RED"
    
    echo -e "${BLUE}📊 Updated Status Options:${NC}"
    show_current_status
    
    show_completion_summary
}

# Run main function
main
