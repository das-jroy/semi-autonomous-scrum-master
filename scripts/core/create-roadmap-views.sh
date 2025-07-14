#!/bin/bash

# GitHub Project Roadmap View Automation
# Creates and updates roadmap-specific views in the GitHub project board

set -e

echo "🗺️ GitHub Project Roadmap View Automation"
echo "=========================================="
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
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"

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

# Function to get current project views
get_current_views() {
    echo -e "${BLUE}📋 Current Project Views${NC}"
    echo "======================="
    
    # Note: GitHub's GraphQL API has limited support for views
    # We'll use the internal API approach that has worked before
    local token=$(gh auth token)
    
    echo "Attempting to retrieve current views..."
    echo ""
    
    # Try to get views using internal API
    local response=$(curl -s -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        "https://api.github.com/projects/$PROJECT_ID/views" 2>/dev/null || echo "API_ERROR")
    
    if [[ "$response" != "API_ERROR" ]] && echo "$response" | jq -e '.' > /dev/null 2>&1; then
        echo -e "${GREEN}Current views found:${NC}"
        echo "$response" | jq -r '.[] | "• " + .name + " (" + .layout + ")"' 2>/dev/null || echo "Unable to parse views"
    else
        echo -e "${YELLOW}⚠️  Unable to retrieve views via API${NC}"
        echo "Views may need to be checked manually at: $PROJECT_URL"
    fi
    
    echo ""
}

# Function to create roadmap timeline view
create_roadmap_timeline_view() {
    echo -e "${PURPLE}📅 Creating Roadmap Timeline View${NC}"
    echo "================================"
    
    local token=$(gh auth token)
    
    # Define the roadmap timeline view configuration
    local view_config='{
        "name": "Roadmap Timeline",
        "description": "Timeline view showing development phases and progress",
        "layout": "table_layout",
        "fields": [
            {
                "field_id": "title",
                "width": 300
            },
            {
                "field_id": "status", 
                "width": 150
            },
            {
                "field_id": "priority",
                "width": 100
            },
            {
                "field_id": "module_category",
                "width": 150
            },
            {
                "field_id": "complexity",
                "width": 100
            }
        ],
        "sort_by": [
            {
                "field_id": "priority",
                "direction": "desc"
            },
            {
                "field_id": "module_category", 
                "direction": "asc"
            }
        ]
    }'
    
    echo "Attempting to create Roadmap Timeline view..."
    
    # Try creating the view using internal API
    local response=$(curl -s -X POST \
        "https://github.com/orgs/$REPO_OWNER/memexes/$PROJECT_NUMBER/views" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -H "X-Requested-With: XMLHttpRequest" \
        --data-raw '{"view":{"layout":"table_layout","name":"Roadmap Timeline","description":"Timeline view showing development phases and progress"}}' 2>&1)
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local view_id=$(echo "$response" | jq -r '.id')
        echo -e "${GREEN}✅ Created Roadmap Timeline view (ID: $view_id)${NC}"
    else
        echo -e "${YELLOW}⚠️  Roadmap Timeline view creation may have failed${NC}"
        echo "Response: $response"
        echo ""
        echo -e "${BLUE}Manual Creation:${NC}"
        echo "1. Go to: $PROJECT_URL"
        echo "2. Click 'New view' → 'Table'"
        echo "3. Name: 'Roadmap Timeline'"
        echo "4. Sort by Priority (High to Low), then Module Category"
        echo "5. Show columns: Title, Status, Priority, Module Category, Complexity"
    fi
    
    echo ""
}

# Function to create phase board view
create_phase_board_view() {
    echo -e "${PURPLE}🏗️ Creating Phase Board View${NC}"
    echo "============================="
    
    local token=$(gh auth token)
    
    echo "Attempting to create Phase Board view..."
    
    # Try creating a board view grouped by Module Category (which represents phases)
    local response=$(curl -s -X POST \
        "https://github.com/orgs/$REPO_OWNER/memexes/$PROJECT_NUMBER/views" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -H "X-Requested-With: XMLHttpRequest" \
        --data-raw '{"view":{"layout":"board_layout","name":"Phase Board","description":"Board view grouped by development phases (module categories)"}}' 2>&1)
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local view_id=$(echo "$response" | jq -r '.id')
        echo -e "${GREEN}✅ Created Phase Board view (ID: $view_id)${NC}"
    else
        echo -e "${YELLOW}⚠️  Phase Board view creation may have failed${NC}"
        echo "Response: $response"
        echo ""
        echo -e "${BLUE}Manual Creation:${NC}"
        echo "1. Go to: $PROJECT_URL"
        echo "2. Click 'New view' → 'Board'"
        echo "3. Name: 'Phase Board'"
        echo "4. Group by: 'Module Category'"
        echo "5. This will show columns for: Foundation, Compute, Data, Security, Advanced"
    fi
    
    echo ""
}

# Function to create roadmap progress view
create_roadmap_progress_view() {
    echo -e "${PURPLE}📊 Creating Roadmap Progress View${NC}"
    echo "================================"
    
    local token=$(gh auth token)
    
    echo "Attempting to create Roadmap Progress view..."
    
    # Create a table view optimized for progress tracking
    local response=$(curl -s -X POST \
        "https://github.com/orgs/$REPO_OWNER/memexes/$PROJECT_NUMBER/views" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -H "X-Requested-With: XMLHttpRequest" \
        --data-raw '{"view":{"layout":"table_layout","name":"Roadmap Progress","description":"Progress tracking view with all roadmap metadata"}}' 2>&1)
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local view_id=$(echo "$response" | jq -r '.id')
        echo -e "${GREEN}✅ Created Roadmap Progress view (ID: $view_id)${NC}"
    else
        echo -e "${YELLOW}⚠️  Roadmap Progress view creation may have failed${NC}"
        echo "Response: $response"
        echo ""
        echo -e "${BLUE}Manual Creation:${NC}"
        echo "1. Go to: $PROJECT_URL"
        echo "2. Click 'New view' → 'Table'"
        echo "3. Name: 'Roadmap Progress'"
        echo "4. Show all columns: Title, Status, Priority, Module Category, Complexity, Security Review"
        echo "5. Filter by Status: Todo, In Progress, Review (exclude Done for active work)"
    fi
    
    echo ""
}

# Function to update existing sprint board view
update_sprint_board_view() {
    echo -e "${PURPLE}🚀 Updating Sprint Board View${NC}"
    echo "============================="
    
    echo -e "${BLUE}The Sprint Board view should be configured as follows:${NC}"
    echo "• Layout: Board"
    echo "• Group by: Status"
    echo "• Columns: Todo → In Progress → Review → Blocked → Done"
    echo ""
    
    echo -e "${YELLOW}💡 Manual Update Recommended:${NC}"
    echo "1. Go to: $PROJECT_URL"
    echo "2. Switch to 'Sprint Board' view (or create if missing)"
    echo "3. Ensure it's grouped by 'Status'"
    echo "4. Verify all 5 status columns are visible"
    echo ""
}

# Function to generate browser console script for view management
generate_view_browser_script() {
    echo -e "${BLUE}🌐 Browser Console Script for View Management${NC}"
    echo "============================================="
    
    cat > "browser-console-roadmap-views.js" << 'EOF'
// Browser Console Commands for Creating Roadmap Views
// Open: https://github.com/orgs/dasdigitalplatform/projects/3
// Press F12 → Console tab → Run these commands

console.log('🗺️ Starting Roadmap View Creation...');

// Create Roadmap Timeline View
fetch('/orgs/dasdigitalplatform/memexes/16149890/views', {
  method: 'POST',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    view: {
      layout: 'table_layout',
      name: 'Roadmap Timeline',
      description: 'Timeline view showing development phases and progress'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Roadmap Timeline:', data))
  .catch(error => console.error('❌ Error:', error));

// Create Phase Board View
fetch('/orgs/dasdigitalplatform/memexes/16149890/views', {
  method: 'POST',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    view: {
      layout: 'board_layout',
      name: 'Phase Board',
      description: 'Board view grouped by development phases'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Phase Board:', data))
  .catch(error => console.error('❌ Error:', error));

// Create Roadmap Progress View
fetch('/orgs/dasdigitalplatform/memexes/16149890/views', {
  method: 'POST',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    view: {
      layout: 'table_layout',
      name: 'Roadmap Progress',
      description: 'Progress tracking view with all roadmap metadata'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Roadmap Progress:', data))
  .catch(error => console.error('❌ Error:', error));

console.log('🎯 Roadmap view creation commands sent!');
console.log('After creation, manually configure:');
console.log('• Roadmap Timeline: Sort by Priority, then Module Category');
console.log('• Phase Board: Group by Module Category');
console.log('• Roadmap Progress: Show all metadata columns');
EOF

    echo -e "${GREEN}✅ Generated browser console script: browser-console-roadmap-views.js${NC}"
    echo ""
    echo -e "${CYAN}To use the browser script:${NC}"
    echo "1. Open: $PROJECT_URL"
    echo "2. Press F12 → Console tab"
    echo "3. Copy and paste the contents of browser-console-roadmap-views.js"
    echo "4. Run the commands one by one"
    echo ""
}

# Function to show recommended roadmap views
show_recommended_views() {
    echo -e "${BOLD}${CYAN}📋 Recommended Roadmap Views${NC}"
    echo "============================"
    echo ""
    
    echo -e "${GREEN}1. Roadmap Timeline (Table)${NC}"
    echo "   • Purpose: Sequential view of all modules in development order"
    echo "   • Layout: Table"
    echo "   • Sort: Priority (High→Low), then Module Category"
    echo "   • Columns: Title, Status, Priority, Module Category, Complexity"
    echo "   • Use: Planning and sequential development tracking"
    echo ""
    
    echo -e "${GREEN}2. Phase Board (Board)${NC}"
    echo "   • Purpose: Visual board grouped by development phases"
    echo "   • Layout: Board"
    echo "   • Group by: Module Category"
    echo "   • Columns: Foundation, Compute, Data, Security, Advanced"
    echo "   • Use: Phase-based development and resource allocation"
    echo ""
    
    echo -e "${GREEN}3. Roadmap Progress (Table)${NC}"
    echo "   • Purpose: Comprehensive progress tracking with all metadata"
    echo "   • Layout: Table"
    echo "   • Columns: All fields visible"
    echo "   • Filter: Active work (Todo, In Progress, Review)"
    echo "   • Use: Detailed progress monitoring and reporting"
    echo ""
    
    echo -e "${GREEN}4. Sprint Board (Board) - Already Exists${NC}"
    echo "   • Purpose: Active sprint management"
    echo "   • Layout: Board"
    echo "   • Group by: Status"
    echo "   • Columns: Todo → In Progress → Review → Blocked → Done"
    echo "   • Use: Daily standup and sprint planning"
    echo ""
}

# Function to show manual creation instructions
show_manual_instructions() {
    echo -e "${BOLD}${YELLOW}📋 Manual View Creation Instructions${NC}"
    echo "===================================="
    echo ""
    
    echo -e "${CYAN}For each view, follow these steps:${NC}"
    echo "1. Go to: $PROJECT_URL"
    echo "2. Click 'New view' button"
    echo "3. Choose layout (Table or Board)"
    echo "4. Set name and description"
    echo "5. Configure grouping, sorting, and columns"
    echo "6. Save the view"
    echo ""
    
    echo -e "${BLUE}Specific Configurations:${NC}"
    echo ""
    echo -e "${BOLD}Roadmap Timeline:${NC}"
    echo "• Name: 'Roadmap Timeline'"
    echo "• Layout: Table"
    echo "• Sort: Priority (desc), Module Category (asc)"
    echo "• Columns: Title, Status, Priority, Module Category, Complexity"
    echo ""
    
    echo -e "${BOLD}Phase Board:${NC}"
    echo "• Name: 'Phase Board'"
    echo "• Layout: Board"
    echo "• Group by: Module Category"
    echo "• Shows: Foundation, Compute, Data, Security, Advanced columns"
    echo ""
    
    echo -e "${BOLD}Roadmap Progress:${NC}"
    echo "• Name: 'Roadmap Progress'"
    echo "• Layout: Table"
    echo "• Columns: All fields visible"
    echo "• Optional filter: Exclude 'Done' status for active work focus"
    echo ""
}

# Function to show completion summary
show_completion_summary() {
    echo -e "${BOLD}${GREEN}🎉 Roadmap View Automation Complete!${NC}"
    echo "===================================="
    echo ""
    
    echo -e "${CYAN}What was accomplished:${NC}"
    echo "✅ Attempted automated view creation"
    echo "✅ Generated browser console script"
    echo "✅ Provided manual creation instructions"
    echo "✅ Defined optimal roadmap view configurations"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Use browser console script or manual creation"
    echo "2. Configure views according to specifications"
    echo "3. Test views with your roadmap workflow"
    echo "4. Adjust configurations as needed"
    echo ""
    
    echo -e "${BLUE}Benefits of Roadmap Views:${NC}"
    echo "• Phase-based development tracking"
    echo "• Visual progress monitoring"
    echo "• Better resource allocation"
    echo "• Stakeholder reporting"
    echo ""
}

# Main execution function
main() {
    validate_prerequisites
    get_current_views
    
    echo -e "${BOLD}${PURPLE}🛠️ Creating Roadmap Views${NC}"
    echo "========================="
    echo ""
    
    create_roadmap_timeline_view
    create_phase_board_view
    create_roadmap_progress_view
    update_sprint_board_view
    
    generate_view_browser_script
    show_recommended_views
    show_manual_instructions
    show_completion_summary
}

# Command line options
case "${1:-}" in
    --views-only)
        get_current_views
        show_recommended_views
        ;;
    --manual)
        show_manual_instructions
        ;;
    --browser)
        generate_view_browser_script
        ;;
    --help)
        echo "Usage: $0 [--views-only|--manual|--browser|--help]"
        echo ""
        echo "Options:"
        echo "  --views-only   Show current and recommended views"
        echo "  --manual       Show manual creation instructions"
        echo "  --browser      Generate browser console script"
        echo "  --help         Show this help"
        ;;
    *)
        main
        ;;
esac
