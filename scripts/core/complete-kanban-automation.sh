#!/bin/bash

# Complete Kanban Workflow Automation
# This script provides multiple approaches to enhance the GitHub project board with Review and Blocked status columns

set -e

echo "🚀 Complete Kanban Workflow Automation"
echo "======================================"
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
REPO_OWNER="dasdigitalplatform"
PROJECT_NUMBER="3"
PROJECT_ID="PVT_kwDOC-2N484A9m2C"
STATUS_FIELD_ID="PVTSSF_lADOC-2N484A9m2CzgxQnNU"
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"

# Function to display header
show_header() {
    echo -e "${BOLD}${CYAN}🎯 Enhancing Your Kanban Workflow${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo ""
    echo -e "${BLUE}Current Status:${NC} Todo → In Progress → Done"
    echo -e "${GREEN}Enhanced Status:${NC} Todo → In Progress → Review → Done (+ Blocked)"
    echo ""
}

# Function to validate prerequisites
validate_prerequisites() {
    echo -e "${CYAN}🔒 Validating Prerequisites${NC}"
    echo "==========================="
    
    local checks_passed=0
    
    if command -v gh &> /dev/null; then
        echo -e "${GREEN}✅ GitHub CLI installed${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ GitHub CLI not installed${NC}"
    fi
    
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    fi
    
    if command -v jq &> /dev/null; then
        echo -e "${GREEN}✅ jq JSON processor available${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ jq not installed${NC}"
    fi
    
    if command -v curl &> /dev/null; then
        echo -e "${GREEN}✅ curl available${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ curl not installed${NC}"
    fi
    
    echo ""
    
    if [[ $checks_passed -lt 4 ]]; then
        echo -e "${RED}❌ Prerequisites not met. Please install missing tools.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met!${NC}"
    echo ""
}

# Function to get current status field configuration
get_current_status() {
    echo -e "${BLUE}🔍 Analyzing Current Project Status${NC}"
    echo "================================="
    
    local field_info=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          title
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
    
    # Get project title
    PROJECT_TITLE=$(echo "$field_info" | jq -r '.data.node.title')
    echo "Project: $PROJECT_TITLE"
    echo "URL: $PROJECT_URL"
    echo ""
    
    # Get current status options
    echo -e "${BLUE}Current Status Options:${NC}"
    echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | "• " + .name'
    
    # Check what's missing
    REVIEW_EXISTS=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Review") | .name // empty')
    BLOCKED_EXISTS=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Blocked") | .name // empty')
    
    echo ""
    if [[ -n "$REVIEW_EXISTS" && -n "$BLOCKED_EXISTS" ]]; then
        echo -e "${GREEN}✅ Both 'Review' and 'Blocked' options already exist!${NC}"
        echo -e "${YELLOW}Your kanban workflow is already enhanced.${NC}"
        return 0
    elif [[ -n "$REVIEW_EXISTS" ]]; then
        echo -e "${YELLOW}⚠️  'Review' exists, but 'Blocked' is missing${NC}"
        return 1
    elif [[ -n "$BLOCKED_EXISTS" ]]; then
        echo -e "${YELLOW}⚠️  'Blocked' exists, but 'Review' is missing${NC}"
        return 1
    else
        echo -e "${YELLOW}⚠️  Both 'Review' and 'Blocked' options need to be added${NC}"
        return 1
    fi
}

# Function to show manual setup instructions
show_manual_setup() {
    echo -e "${BOLD}${YELLOW}📋 Manual Setup Instructions${NC}"
    echo "============================="
    echo ""
    echo -e "${CYAN}🎯 Quick Setup (5 minutes):${NC}"
    echo ""
    echo "1. ${BOLD}Open your project board:${NC}"
    echo "   $PROJECT_URL"
    echo ""
    echo "2. ${BOLD}Edit the Status field:${NC}"
    echo "   • Click Settings (⚙️) in the top-right"
    echo "   • Click 'Fields' in the left sidebar"
    echo "   • Find 'Status' field and click 'Edit'"
    echo ""
    echo "3. ${BOLD}Add new status options:${NC}"
    if [[ -z "$REVIEW_EXISTS" ]]; then
        echo "   • Click '+ Add option'"
        echo "   • Name: 'Review'"
        echo "   • Color: Yellow or Orange"
        echo "   • Description: 'Code review, validation, testing'"
    fi
    if [[ -z "$BLOCKED_EXISTS" ]]; then
        echo "   • Click '+ Add option' again"
        echo "   • Name: 'Blocked'"
        echo "   • Color: Red"
        echo "   • Description: 'Waiting for dependencies or decisions'"
    fi
    echo ""
    echo "4. ${BOLD}Save the changes${NC}"
    echo ""
    echo "5. ${BOLD}Create Sprint Board view (optional):${NC}"
    echo "   • Click 'New view' → 'Board'"
    echo "   • Name: 'Sprint Board'"
    echo "   • Group by: 'Status'"
    echo ""
}

# Function to generate browser console script
generate_browser_console_script() {
    echo -e "${PURPLE}🌐 Browser Console Automation${NC}"
    echo "============================="
    echo ""
    echo -e "${YELLOW}If you prefer to use browser automation:${NC}"
    echo ""
    echo "1. Open: $PROJECT_URL"
    echo "2. Press F12 (Developer Tools) → Console tab"
    echo "3. Run these commands one by one:"
    echo ""
    
    if [[ -z "$REVIEW_EXISTS" ]]; then
        echo -e "${CYAN}// Add Review status option${NC}"
        cat << 'EOF'
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: `
      mutation {
        updateProjectV2Field(input: {
          fieldId: "PVTSSF_lADOC-2N484A9m2CzgxQnNU"
          singleSelectField: {
            options: [
              {name: "Todo"},
              {name: "In Progress"}, 
              {name: "Review"},
              {name: "Done"}
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
      }
    `
  })
}).then(response => response.json())
  .then(data => console.log('✅ Added Review option:', data))
  .catch(error => console.error('❌ Error:', error));
EOF
        echo ""
    fi
    
    if [[ -z "$BLOCKED_EXISTS" ]]; then
        echo -e "${CYAN}// Add Blocked status option${NC}"
        cat << 'EOF'
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: `
      mutation {
        updateProjectV2Field(input: {
          fieldId: "PVTSSF_lADOC-2N484A9m2CzgxQnNU"
          singleSelectField: {
            options: [
              {name: "Todo"},
              {name: "In Progress"}, 
              {name: "Review"},
              {name: "Blocked"},
              {name: "Done"}
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
      }
    `
  })
}).then(response => response.json())
  .then(data => console.log('✅ Added Blocked option:', data))
  .catch(error => console.error('❌ Error:', error));
EOF
        echo ""
    fi
    
    echo -e "${CYAN}// Verify status options${NC}"
    cat << 'EOF'
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: `
      query {
        node(id: "PVT_kwDOC-2N484A9m2C") {
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
      }
    `
  })
}).then(response => response.json())
  .then(data => {
    const statusField = data.data.node.fields.nodes.find(field => field.name === 'Status');
    console.log('🎯 Current Status Options:', statusField.options.map(opt => opt.name));
  })
  .catch(error => console.error('❌ Error:', error));
EOF
    echo ""
}

# Function to show the enhanced workflow
show_enhanced_workflow() {
    echo -e "${BOLD}${GREEN}🎯 Your Enhanced Kanban Workflow${NC}"
    echo "==============================="
    echo ""
    echo -e "${BLUE}📋 Todo${NC} → Ready to implement"
    echo "   • New features to be developed"
    echo "   • Bugs to be fixed"
    echo "   • Documentation to be written"
    echo ""
    echo -e "${YELLOW}⚡ In Progress${NC} → Actively being developed"
    echo "   • Currently being coded"
    echo "   • Work in active development"
    echo "   • Assign to developer working on it"
    echo ""
    echo -e "${PURPLE}👀 Review${NC} → Code review, validation, testing"
    echo "   • Code written, needs review"
    echo "   • Pull request created"
    echo "   • Testing and validation phase"
    echo ""
    echo -e "${RED}🚫 Blocked${NC} → Waiting for dependencies or decisions"
    echo "   • Waiting for external dependencies"
    echo "   • Needs architectural decision"
    echo "   • Blocked by other issues"
    echo ""
    echo -e "${GREEN}✅ Done${NC} → Fully complete, tested, documented"
    echo "   • Code merged and deployed"
    echo "   • Documentation updated"
    echo "   • Ready for production"
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${BOLD}${CYAN}🚀 Next Steps${NC}"
    echo "============="
    echo ""
    echo -e "${GREEN}1. Set up the enhanced kanban columns${NC}"
    echo "   • Use manual setup (5 minutes) or browser console"
    echo ""
    echo -e "${GREEN}2. Start using the workflow${NC}"
    echo "   • Move your 17 issues through the statuses"
    echo "   • Use 'Review' for code review phase"
    echo "   • Use 'Blocked' when waiting on dependencies"
    echo ""
    echo -e "${GREEN}3. Create Sprint Board view${NC}"
    echo "   • Group issues by Status for kanban visualization"
    echo "   • Use as your primary development dashboard"
    echo ""
    echo -e "${GREEN}4. Establish team practices${NC}"
    echo "   • Move issues to 'Review' when PR is ready"
    echo "   • Move to 'Blocked' when dependencies needed"
    echo "   • Update status as work progresses"
    echo ""
    echo -e "${BLUE}📊 Current Status: You have 17 issues ready to go!${NC}"
    echo ""
}

# Function to save scripts for easy access
save_automation_scripts() {
    echo -e "${BLUE}💾 Saving Automation Scripts${NC}"
    echo "============================"
    
    # Save manual instructions
    cat > "manual-kanban-enhancement.md" << EOF
# Manual Kanban Enhancement Guide

## Quick Setup (5 minutes)

1. **Open your project board**: $PROJECT_URL

2. **Edit the Status field**:
   - Click Settings (⚙️) in the top-right
   - Click 'Fields' in the left sidebar  
   - Find 'Status' field and click 'Edit'

3. **Add new status options**:
$(if [[ -z "$REVIEW_EXISTS" ]]; then
echo "   - Click '+ Add option'"
echo "   - Name: 'Review'"
echo "   - Color: Yellow or Orange"
echo "   - Description: 'Code review, validation, testing'"
fi)
$(if [[ -z "$BLOCKED_EXISTS" ]]; then
echo "   - Click '+ Add option' again"
echo "   - Name: 'Blocked'" 
echo "   - Color: Red"
echo "   - Description: 'Waiting for dependencies or decisions'"
fi)

4. **Save the changes**

5. **Create Sprint Board view** (optional):
   - Click 'New view' → 'Board'
   - Name: 'Sprint Board'
   - Group by: 'Status'

## Enhanced Workflow

- 📋 **Todo** → Ready to implement
- ⚡ **In Progress** → Actively being developed  
- 👀 **Review** → Code review, validation, testing
- 🚫 **Blocked** → Waiting for dependencies or decisions
- ✅ **Done** → Fully complete, tested, documented

## Next Steps

1. Set up the enhanced kanban columns (5 minutes)
2. Move your 17 issues through the workflow
3. Use 'Review' for code review phase
4. Use 'Blocked' when waiting on dependencies
EOF

    # Save browser console script
    cat > "browser-console-kanban-enhancement.js" << EOF
// Browser Console Commands for Kanban Enhancement
// Open: $PROJECT_URL
// Press F12 → Console tab → Run these commands

console.log('🚀 Starting Kanban Enhancement...');

$(if [[ -z "$REVIEW_EXISTS" ]]; then
cat << 'REVIEWEOF'
// Add Review status option
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: \`
      mutation {
        updateProjectV2Field(input: {
          fieldId: "PVTSSF_lADOC-2N484A9m2CzgxQnNU"
          singleSelectField: {
            options: [
              {name: "Todo"},
              {name: "In Progress"}, 
              {name: "Review"},
              {name: "Done"}
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
      }
    \`
  })
}).then(response => response.json())
  .then(data => console.log('✅ Added Review option:', data))
  .catch(error => console.error('❌ Error:', error));

REVIEWEOF
fi)

$(if [[ -z "$BLOCKED_EXISTS" ]]; then
cat << 'BLOCKEDEOF'
// Add Blocked status option
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: \`
      mutation {
        updateProjectV2Field(input: {
          fieldId: "PVTSSF_lADOC-2N484A9m2CzgxQnNU"
          singleSelectField: {
            options: [
              {name: "Todo"},
              {name: "In Progress"}, 
              {name: "Review"},
              {name: "Blocked"},
              {name: "Done"}
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
      }
    \`
  })
}).then(response => response.json())
  .then(data => console.log('✅ Added Blocked option:', data))
  .catch(error => console.error('❌ Error:', error));

BLOCKEDEOF
fi)

// Verify status options
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: \`
      query {
        node(id: "PVT_kwDOC-2N484A9m2C") {
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
      }
    \`
  })
}).then(response => response.json())
  .then(data => {
    const statusField = data.data.node.fields.nodes.find(field => field.name === 'Status');
    console.log('🎯 Current Status Options:', statusField.options.map(opt => opt.name));
    console.log('✅ Kanban Enhancement Complete!');
  })
  .catch(error => console.error('❌ Error:', error));
EOF

    echo -e "${GREEN}✅ Saved: manual-kanban-enhancement.md${NC}"
    echo -e "${GREEN}✅ Saved: browser-console-kanban-enhancement.js${NC}"
    echo ""
}

# Main execution function
main() {
    show_header
    validate_prerequisites
    
    if get_current_status; then
        echo -e "${GREEN}✅ Kanban workflow already enhanced!${NC}"
        show_enhanced_workflow
        return 0
    fi
    
    echo -e "${YELLOW}🔧 Enhancement needed. Providing automation options...${NC}"
    echo ""
    
    show_manual_setup
    generate_browser_console_script
    save_automation_scripts
    show_enhanced_workflow
    show_next_steps
    
    echo -e "${BOLD}${GREEN}🎉 Kanban Enhancement Ready!${NC}"
    echo "Choose your preferred setup method above."
}

# Command line options
case "${1:-}" in
    --status)
        validate_prerequisites
        get_current_status
        ;;
    --manual)
        show_manual_setup
        ;;
    --browser)
        generate_browser_console_script
        ;;
    --help)
        echo "Usage: $0 [--status|--manual|--browser|--help]"
        echo ""
        echo "Options:"
        echo "  --status    Check current kanban status"
        echo "  --manual    Show manual setup instructions"
        echo "  --browser   Show browser console automation"
        echo "  --help      Show this help"
        ;;
    *)
        main
        ;;
esac
