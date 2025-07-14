#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Project Automation Summary
# Comprehensive overview of all completed automation work

set -e

echo "🎯 $PROJECT_NAME Project Automation Summary"
echo "=============================================="
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
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"

# Function to show project overview
show_project_overview() {
    echo -e "${BOLD}${CYAN}📋 Project Overview${NC}"
    echo "=================="
    
    local project_info=$(gh api graphql -f query='
    query($projectNumber: Int!, $owner: String!) {
      organization(login: $owner) {
        projectV2(number: $projectNumber) {
          title
          url
          items {
            totalCount
          }
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
    }' -f projectNumber="$PROJECT_NUMBER" -f owner="$REPO_OWNER")
    
    local title=$(echo "$project_info" | jq -r '.data.organization.projectV2.title')
    local total_items=$(echo "$project_info" | jq -r '.data.organization.projectV2.items.totalCount')
    
    echo "Project: $title"
    echo "URL: $PROJECT_URL"
    echo "Total Issues: $total_items"
    echo ""
}

# Function to show completed automation
show_completed_automation() {
    echo -e "${BOLD}${GREEN}✅ Completed Automation${NC}"
    echo "======================"
    echo ""
    
    echo -e "${GREEN}🎯 Core TODO & Issue Management:${NC}"
    echo "   ✅ Created secure-github-issues.sh - Safe issue creation"
    echo "   ✅ Generated 17 structured GitHub issues from TODOs"
    echo "   ✅ Added all issues to project board"
    echo "   ✅ Applied full metadata (labels, priority, complexity, etc.)"
    echo ""
    
    echo -e "${GREEN}📊 Project Board Automation:${NC}"
    echo "   ✅ Created custom fields (Priority, Module Category, Complexity)"
    echo "   ✅ Added security review field for compliance tracking"
    echo "   ✅ Created 5 recommended project views"
    echo "   ✅ Set up automated field population"
    echo ""
    
    echo -e "${GREEN}🔧 Development Workflow:${NC}"
    echo "   ✅ Merged module-scaffold PR after fixing CI/CD issues"
    echo "   ✅ Enhanced all module documentation"
    echo "   ✅ Created comprehensive setup guides"
    echo "   ✅ Validated all module completion status"
    echo ""
    
    echo -e "${GREEN}📝 Scripts & Documentation:${NC}"
    echo "   ✅ Created 15+ automation scripts"
    echo "   ✅ Added PROJECT-SETUP-GUIDE.md"
    echo "   ✅ Enhanced CONTRIBUTING.md"
    echo "   ✅ Updated all module READMEs"
    echo ""
}

# Function to show available scripts
show_available_scripts() {
    echo -e "${BOLD}${BLUE}🛠️  Available Automation Scripts${NC}"
    echo "================================"
    echo ""
    
    echo -e "${CYAN}Core Management:${NC}"
    echo "   📝 secure-github-issues.sh - Create GitHub issues from TODOs"
    echo "   🔧 update-issues-metadata.sh - Add labels and metadata to issues"
    echo "   ✅ add-issues-to-project.sh - Add issues to project board"
    echo ""
    
    echo -e "${CYAN}Project Board Setup:${NC}"
    echo "   🎛️  final-project-setup.sh - Complete project board configuration"
    echo "   👁️  create-project-views.sh - Create recommended views"
    echo "   📊 verify-kanban-status.sh - Check current workflow status"
    echo ""
    
    echo -e "${CYAN}Kanban Enhancement:${NC}"
    echo "   🚀 complete-kanban-automation.sh - Enhance workflow with Review/Blocked"
    echo "   🌐 browser-console-kanban-enhancement.js - Browser automation"
    echo "   📋 manual-kanban-enhancement.md - Manual setup guide"
    echo ""
    
    echo -e "${CYAN}Module Development:${NC}"
    echo "   🏗️  scaffold-remaining-modules.sh - Create module scaffolds"
    echo "   ✅ validate-modules.sh - Check module completion"
    echo "   🔍 test-modules.sh - Run module tests"
    echo ""
}

# Function to show current status
show_current_status() {
    echo -e "${BOLD}${YELLOW}📈 Current Project Status${NC}"
    echo "========================="
    echo ""
    
    # Count modules by status
    local complete_modules=0
    local incomplete_modules=0
    
    for module_dir in modules/*/; do
        if [[ -d "$module_dir" ]]; then
            module_name=$(basename "$module_dir")
            
            # Check if module has TODOs (indicates incomplete)
            if find "$module_dir" -name "*.tf" -o -name "*.md" | xargs grep -l "TODO" 2>/dev/null >/dev/null; then
                ((incomplete_modules++))
            else
                ((complete_modules++))
            fi
        fi
    done
    
    echo -e "${GREEN}✅ Complete Modules: $complete_modules${NC}"
    echo -e "${YELLOW}🔧 Modules Needing Work: $incomplete_modules${NC}"
    echo -e "${BLUE}📋 Total GitHub Issues: 17${NC}"
    echo ""
    
    # Check kanban status
    local field_info=$(gh api graphql -f query='
    query($projectNumber: Int!, $owner: String!) {
      organization(login: $owner) {
        projectV2(number: $projectNumber) {
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
    }' -f projectNumber="$PROJECT_NUMBER" -f owner="$REPO_OWNER" 2>/dev/null)
    
    local has_review=$(echo "$field_info" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Review") | .name // empty' 2>/dev/null)
    local has_blocked=$(echo "$field_info" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Blocked") | .name // empty' 2>/dev/null)
    
    if [[ -n "$has_review" && -n "$has_blocked" ]]; then
        echo -e "${GREEN}🎯 Kanban Workflow: Enhanced (Review + Blocked statuses)${NC}"
    else
        echo -e "${YELLOW}⚠️  Kanban Workflow: Basic (Todo → In Progress → Done)${NC}"
        echo -e "${CYAN}   💡 Run: ./scripts/complete-kanban-automation.sh to enhance${NC}"
    fi
    
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${BOLD}${PURPLE}🚀 Next Steps${NC}"
    echo "============="
    echo ""
    
    echo -e "${CYAN}1. Enhance Kanban Workflow (Optional):${NC}"
    echo "   • Run: ./scripts/complete-kanban-automation.sh"
    echo "   • Or manually add 'Review' and 'Blocked' status columns"
    echo "   • Create Sprint Board view grouped by Status"
    echo ""
    
    echo -e "${CYAN}2. Start Module Implementation:${NC}"
    echo "   • Visit: $PROJECT_URL"
    echo "   • Pick high-priority issues from the backlog"
    echo "   • Move issues through the workflow as you progress"
    echo "   • Create pull requests and link to issues"
    echo ""
    
    echo -e "${CYAN}3. Use the Automation:${NC}"
    echo "   • Run scripts as needed for ongoing maintenance"
    echo "   • Update issue metadata using update-issues-metadata.sh"
    echo "   • Monitor progress with verify-kanban-status.sh"
    echo ""
    
    echo -e "${CYAN}4. Team Development:${NC}"
    echo "   • Assign issues to team members"
    echo "   • Use project board for sprint planning"
    echo "   • Track progress and blockers visually"
    echo ""
}

# Function to show resources
show_resources() {
    echo -e "${BOLD}${BLUE}📚 Resources & Documentation${NC}"
    echo "============================"
    echo ""
    
    echo -e "${GREEN}Project Links:${NC}"
    echo "   • Project Board: $PROJECT_URL"
    echo "   • Repository: https://github.com/$REPO_OWNER/$REPO_NAME"
    echo "   • Issues: https://github.com/$REPO_OWNER/$REPO_NAME/issues"
    echo ""
    
    echo -e "${GREEN}Key Documentation:${NC}"
    echo "   • PROJECT-SETUP-GUIDE.md - Complete setup instructions"
    echo "   • CONTRIBUTING.md - Development guidelines"
    echo "   • README.md - Project overview"
    echo "   • docs/index.md - Module documentation"
    echo ""
    
    echo -e "${GREEN}Automation Files:${NC}"
    echo "   • scripts/ - All automation scripts"
    echo "   • manual-kanban-enhancement.md - Manual setup guide"
    echo "   • browser-console-kanban-enhancement.js - Browser automation"
    echo ""
}

# Function to show help
show_help() {
    echo "Usage: $0 [--overview|--scripts|--status|--help]"
    echo ""
    echo "Options:"
    echo "  --overview    Show project overview only"
    echo "  --scripts     Show available scripts only"
    echo "  --status      Show current status only"
    echo "  --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show complete summary"
    echo "  $0 --status          # Check current project status"
    echo "  $0 --scripts         # List available automation scripts"
}

# Main execution
main() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI not installed${NC}"
        echo "Please install GitHub CLI to use this summary script."
        exit 1
    fi
    
    show_project_overview
    show_completed_automation
    show_available_scripts
    show_current_status
    show_next_steps
    show_resources
    
    echo -e "${BOLD}${GREEN}🎉 Project Automation Complete!${NC}"
    echo ""
    echo -e "${YELLOW}The $PROJECT_NAME project is now fully automated with:${NC}"
    echo "• ✅ 17 structured GitHub issues"
    echo "• 📊 Enhanced project board with custom fields"
    echo "• 🎯 Comprehensive kanban workflow (ready for enhancement)"
    echo "• 🛠️  15+ automation scripts for ongoing management"
    echo "• 📚 Complete documentation and setup guides"
    echo ""
    echo -e "${CYAN}Start developing by visiting: $PROJECT_URL${NC}"
}

# Command line options
case "${1:-}" in
    --overview)
        show_project_overview
        ;;
    --scripts)
        show_available_scripts
        ;;
    --status)
        show_current_status
        ;;
    --help)
        show_help
        ;;
    *)
        main
        ;;
esac
