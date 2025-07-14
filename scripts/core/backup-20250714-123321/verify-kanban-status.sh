#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Kanban Status Verification Script
# Checks the current status of the GitHub project board kanban workflow

set -e

echo "🔍 Kanban Status Verification"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
# REPO_OWNER loaded from config
PROJECT_NUMBER="3"
PROJECT_ID="PVT_kwDOC-2N484A9m2C"
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"

# Function to check project status
check_project_status() {
    echo -e "${BLUE}📊 Project Status Analysis${NC}"
    echo "========================="
    
    local field_info=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          title
          url
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
          items(first: 100) {
            totalCount
            nodes {
              fieldValues(first: 20) {
                nodes {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                    field {
                      ... on ProjectV2SingleSelectField {
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID")
    
    # Get project title and basic info
    PROJECT_TITLE=$(echo "$field_info" | jq -r '.data.node.title')
    TOTAL_ITEMS=$(echo "$field_info" | jq -r '.data.node.items.totalCount')
    
    echo "Project: $PROJECT_TITLE"
    echo "URL: $PROJECT_URL"
    echo "Total Items: $TOTAL_ITEMS"
    echo ""
    
    # Get status field options
    echo -e "${CYAN}🏷️  Available Status Options:${NC}"
    local status_options=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | .name')
    
    # Count status options and check for enhanced workflow
    local option_count=0
    local has_review=false
    local has_blocked=false
    
    while IFS= read -r option; do
        case "$option" in
            "Todo")
                echo -e "   📋 ${BLUE}Todo${NC} - Ready to implement"
                ((option_count++))
                ;;
            "In Progress")
                echo -e "   ⚡ ${YELLOW}In Progress${NC} - Actively being developed"
                ((option_count++))
                ;;
            "Review")
                echo -e "   👀 ${PURPLE}Review${NC} - Code review, validation, testing"
                has_review=true
                ((option_count++))
                ;;
            "Blocked")
                echo -e "   🚫 ${RED}Blocked${NC} - Waiting for dependencies or decisions"
                has_blocked=true
                ((option_count++))
                ;;
            "Done")
                echo -e "   ✅ ${GREEN}Done${NC} - Fully complete, tested, documented"
                ((option_count++))
                ;;
            *)
                echo -e "   ❓ ${CYAN}$option${NC} - Custom status"
                ((option_count++))
                ;;
        esac
    done <<< "$status_options"
    
    echo ""
    
    # Workflow assessment
    echo -e "${BLUE}🎯 Workflow Assessment${NC}"
    echo "====================="
    
    if [[ $has_review == true && $has_blocked == true ]]; then
        echo -e "${GREEN}✅ Enhanced Kanban Workflow Active!${NC}"
        echo "   Your workflow includes Review and Blocked statuses"
        echo "   This enables proper code review and dependency tracking"
    elif [[ $has_review == true ]]; then
        echo -e "${YELLOW}⚠️  Partial Enhancement${NC}"
        echo "   'Review' status available, but 'Blocked' is missing"
        echo "   Consider adding 'Blocked' for complete workflow"
    elif [[ $has_blocked == true ]]; then
        echo -e "${YELLOW}⚠️  Partial Enhancement${NC}"
        echo "   'Blocked' status available, but 'Review' is missing"
        echo "   Consider adding 'Review' for code review tracking"
    else
        echo -e "${RED}❌ Basic Workflow Only${NC}"
        echo "   Missing both 'Review' and 'Blocked' statuses"
        echo "   Run ./scripts/complete-kanban-automation.sh to enhance"
    fi
    
    echo ""
    
    # Status distribution
    echo -e "${BLUE}📈 Issue Status Distribution${NC}"
    echo "==========================="
    
    # Count issues by status
    local status_counts=$(echo "$field_info" | jq -r '
    .data.node.items.nodes[] |
    .fieldValues.nodes[] |
    select(.field.name == "Status") |
    .name' | sort | uniq -c | sort -nr)
    
    if [[ -n "$status_counts" ]]; then
        while read -r count status; do
            case "$status" in
                "Todo")
                    echo -e "   📋 $count issues in ${BLUE}Todo${NC}"
                    ;;
                "In Progress")
                    echo -e "   ⚡ $count issues ${YELLOW}In Progress${NC}"
                    ;;
                "Review")
                    echo -e "   👀 $count issues in ${PURPLE}Review${NC}"
                    ;;
                "Blocked")
                    echo -e "   🚫 $count issues ${RED}Blocked${NC}"
                    ;;
                "Done")
                    echo -e "   ✅ $count issues ${GREEN}Done${NC}"
                    ;;
                *)
                    echo -e "   ❓ $count issues in ${CYAN}$status${NC}"
                    ;;
            esac
        done <<< "$status_counts"
    else
        echo "   No issues found with status values"
    fi
    
    echo ""
}

# Function to get project views
check_project_views() {
    echo -e "${BLUE}📋 Project Views${NC}"
    echo "================"
    
    # Note: GitHub's GraphQL API doesn't easily expose view information
    # We'll provide guidance on manual verification
    echo "To check your project views:"
    echo "1. Visit: $PROJECT_URL"
    echo "2. Look for these recommended views:"
    echo "   • Sprint Board (Board layout grouped by Status)"
    echo "   • All Issues (Table layout with all fields)"
    echo "   • Priority View (Table sorted by Priority)"
    echo ""
    
    echo -e "${CYAN}💡 Tip:${NC} Create a 'Sprint Board' view if you haven't already:"
    echo "   • Click 'New view' → 'Board'"
    echo "   • Name: 'Sprint Board'" 
    echo "   • Group by: 'Status'"
    echo ""
}

# Function to show recommendations
show_recommendations() {
    echo -e "${YELLOW}💡 Recommendations${NC}"
    echo "=================="
    
    # Check if enhanced workflow is active
    local field_info=$(gh api graphql -f query='
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
    }' -f projectId="$PROJECT_ID")
    
    local has_review=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Review") | .name // empty')
    local has_blocked=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Blocked") | .name // empty')
    
    if [[ -z "$has_review" || -z "$has_blocked" ]]; then
        echo -e "${RED}🔧 Enhancement Needed:${NC}"
        echo "   Run: ./scripts/complete-kanban-automation.sh"
        echo "   This will add missing 'Review' and 'Blocked' statuses"
        echo ""
    fi
    
    echo -e "${GREEN}📋 Best Practices:${NC}"
    echo "   • Move issues to 'In Progress' when starting work"
    echo "   • Move to 'Review' when code is ready for review"
    echo "   • Use 'Blocked' for dependency or decision blockers"
    echo "   • Update status regularly to track progress"
    echo ""
    
    echo -e "${BLUE}🎯 Next Actions:${NC}"
    echo "   • Start implementing the highest priority issues"
    echo "   • Use the enhanced workflow for all development"
    echo "   • Create pull requests and link to issues"
    echo "   • Update project board as work progresses"
    echo ""
}

# Main execution
main() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI not installed${NC}"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        exit 1
    fi
    
    check_project_status
    check_project_views
    show_recommendations
    
    echo -e "${BOLD}${GREEN}🎉 Verification Complete!${NC}"
    echo "Your kanban workflow is ready for development."
}

# Command line options
case "${1:-}" in
    --status-only)
        check_project_status
        ;;
    --views-only)
        check_project_views
        ;;
    --help)
        echo "Usage: $0 [--status-only|--views-only|--help]"
        echo ""
        echo "Options:"
        echo "  --status-only   Check only project status and workflow"
        echo "  --views-only    Check only project views"
        echo "  --help          Show this help"
        ;;
    *)
        main
        ;;
esac
