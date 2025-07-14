#!/bin/bash

# Roadmap View Optimization Script
# Optimizes existing roadmap views and creates complementary views

set -e

echo "🗺️ Roadmap View Optimization"
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
REPO_OWNER="dasdigitalplatform"
PROJECT_NUMBER="3"
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
EXISTING_ROADMAP_VIEW="https://github.com/orgs/dasdigitalplatform/projects/3/views/5"

# Function to analyze existing roadmap view
analyze_existing_view() {
    echo -e "${BOLD}${CYAN}📊 Existing Roadmap View Analysis${NC}"
    echo "================================="
    echo ""
    
    echo -e "${GREEN}Current Roadmap View:${NC}"
    echo "📍 URL: $EXISTING_ROADMAP_VIEW"
    echo "📋 View ID: 5"
    echo ""
    
    echo -e "${BLUE}Recommended Optimizations for View 5:${NC}"
    echo ""
    
    echo -e "${YELLOW}1. Sort Configuration:${NC}"
    echo "   • Primary: Priority (High → Medium → Low)"
    echo "   • Secondary: Module Category (Foundation → Compute → Data → Security → Advanced)"
    echo "   • Tertiary: Status (Todo → In Progress → Review → Blocked → Done)"
    echo ""
    
    echo -e "${YELLOW}2. Column Configuration:${NC}"
    echo "   • Title (300px) - Issue name"
    echo "   • Status (120px) - Current workflow status"
    echo "   • Priority (100px) - High/Medium/Low"
    echo "   • Module Category (150px) - Development phase"
    echo "   • Complexity (100px) - Development effort"
    echo "   • Assignees (120px) - Who's working on it"
    echo ""
    
    echo -e "${YELLOW}3. Filter Configuration:${NC}"
    echo "   • Show: Todo, In Progress, Review, Blocked (hide Done for active focus)"
    echo "   • Or use: All statuses for complete roadmap visibility"
    echo ""
}

# Function to suggest complementary views
suggest_complementary_views() {
    echo -e "${BOLD}${PURPLE}🎯 Complementary Roadmap Views${NC}"
    echo "============================="
    echo ""
    
    echo -e "${CYAN}Since you have View 5 (Roadmap), consider adding:${NC}"
    echo ""
    
    echo -e "${GREEN}📅 Phase Timeline View (Table)${NC}"
    echo "   • Purpose: Sequential phase-by-phase development tracking"
    echo "   • Group by: Module Category"
    echo "   • Sort: Module Category, then Priority"
    echo "   • Best for: Sprint planning and phase coordination"
    echo ""
    
    echo -e "${GREEN}🏗️ Phase Board View (Board)${NC}"
    echo "   • Purpose: Visual kanban board grouped by development phases"
    echo "   • Group by: Module Category"
    echo "   • Columns: Foundation | Compute | Data | Security | Advanced"
    echo "   • Best for: Resource allocation and phase management"
    echo ""
    
    echo -e "${GREEN}⚡ Active Sprint View (Board)${NC}"
    echo "   • Purpose: Current sprint focus (complement your existing roadmap)"
    echo "   • Group by: Status"
    echo "   • Filter: Only Todo, In Progress, Review, Blocked"
    echo "   • Best for: Daily standups and sprint execution"
    echo ""
    
    echo -e "${GREEN}📊 Progress Dashboard (Table)${NC}"
    echo "   • Purpose: Comprehensive progress tracking and reporting"
    echo "   • Show: All columns with metadata"
    echo "   • Sort: Priority, then Module Category"
    echo "   • Best for: Stakeholder reporting and detailed tracking"
    echo ""
}

# Function to create browser automation for complementary views
create_complementary_views_automation() {
    echo -e "${BLUE}🌐 Creating Browser Automation for Complementary Views${NC}"
    echo "====================================================="
    
    cat > "browser-console-complementary-views.js" << 'EOF'
// Browser Console Commands for Complementary Roadmap Views
// Since you already have View 5 (Roadmap), these complement it
// Open: https://github.com/orgs/dasdigitalplatform/projects/3
// Press F12 → Console tab → Run these commands

console.log('🎯 Creating Complementary Roadmap Views...');

// Create Phase Timeline View (Table grouped by Module Category)
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
      name: 'Phase Timeline',
      description: 'Sequential phase-by-phase development tracking'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Phase Timeline:', data))
  .catch(error => console.error('❌ Error:', error));

// Create Phase Board View (Board grouped by Module Category)
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
      description: 'Visual kanban board grouped by development phases'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Phase Board:', data))
  .catch(error => console.error('❌ Error:', error));

// Create Active Sprint View (Board grouped by Status, filtered for active work)
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
      name: 'Active Sprint',
      description: 'Current sprint focus with active work only'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Active Sprint:', data))
  .catch(error => console.error('❌ Error:', error));

// Create Progress Dashboard View (Table with all metadata)
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
      name: 'Progress Dashboard',
      description: 'Comprehensive progress tracking and reporting'
    }
  })
}).then(response => response.json())
  .then(data => console.log('✅ Created Progress Dashboard:', data))
  .catch(error => console.error('❌ Error:', error));

console.log('🎯 Complementary view creation commands sent!');
console.log('');
console.log('After creation, configure each view:');
console.log('• Phase Timeline: Group by Module Category, sort by Phase → Priority');
console.log('• Phase Board: Group by Module Category for visual phase management');
console.log('• Active Sprint: Group by Status, filter out Done items');
console.log('• Progress Dashboard: Show all columns, sort by Priority → Module Category');
EOF

    echo -e "${GREEN}✅ Generated: browser-console-complementary-views.js${NC}"
    echo ""
}

# Function to provide manual setup instructions
provide_manual_setup() {
    echo -e "${BOLD}${YELLOW}📋 Manual Setup Instructions${NC}"
    echo "============================="
    echo ""
    
    echo -e "${CYAN}For your existing Roadmap View (View 5):${NC}"
    echo "1. Go to: $EXISTING_ROADMAP_VIEW"
    echo "2. Click the view settings (⚙️) or view options"
    echo "3. Configure sorting: Priority → Module Category → Status"
    echo "4. Configure columns: Title, Status, Priority, Module Category, Complexity, Assignees"
    echo "5. Optional: Filter to show only active work (exclude Done)"
    echo ""
    
    echo -e "${CYAN}To create complementary views:${NC}"
    echo "1. Go to: $PROJECT_URL"
    echo "2. Click 'New view' for each additional view"
    echo "3. Follow the configurations below:"
    echo ""
    
    echo -e "${BOLD}Phase Timeline:${NC}"
    echo "• Layout: Table"
    echo "• Name: 'Phase Timeline'"
    echo "• Group by: Module Category"
    echo "• Sort: Module Category (asc), Priority (desc)"
    echo "• Purpose: Sequential phase development"
    echo ""
    
    echo -e "${BOLD}Phase Board:${NC}"
    echo "• Layout: Board"
    echo "• Name: 'Phase Board'"
    echo "• Group by: Module Category"
    echo "• Shows columns: Foundation | Compute | Data | Security | Advanced"
    echo "• Purpose: Visual phase management"
    echo ""
    
    echo -e "${BOLD}Active Sprint:${NC}"
    echo "• Layout: Board"
    echo "• Name: 'Active Sprint'"
    echo "• Group by: Status"
    echo "• Filter: Exclude 'Done' status"
    echo "• Purpose: Current sprint focus"
    echo ""
    
    echo -e "${BOLD}Progress Dashboard:${NC}"
    echo "• Layout: Table"
    echo "• Name: 'Progress Dashboard'"
    echo "• Columns: All fields visible"
    echo "• Sort: Priority (desc), Module Category (asc)"
    echo "• Purpose: Comprehensive reporting"
    echo ""
}

# Function to show view usage recommendations
show_view_usage_recommendations() {
    echo -e "${BOLD}${GREEN}🎯 View Usage Recommendations${NC}"
    echo "============================="
    echo ""
    
    echo -e "${CYAN}When to use each view:${NC}"
    echo ""
    
    echo -e "${YELLOW}📍 Roadmap View (Your existing View 5):${NC}"
    echo "   • Weekly planning and roadmap reviews"
    echo "   • Stakeholder presentations"
    echo "   • Long-term development tracking"
    echo "   • Priority assessment and adjustment"
    echo ""
    
    echo -e "${YELLOW}📅 Phase Timeline:${NC}"
    echo "   • Sprint planning within each phase"
    echo "   • Resource allocation planning"
    echo "   • Dependency identification"
    echo "   • Sequential development tracking"
    echo ""
    
    echo -e "${YELLOW}🏗️ Phase Board:${NC}"
    echo "   • Visual phase progress monitoring"
    echo "   • Team assignment across phases"
    echo "   • Quick phase status overview"
    echo "   • Capacity planning discussions"
    echo ""
    
    echo -e "${YELLOW}⚡ Active Sprint:${NC}"
    echo "   • Daily standups"
    echo "   • Sprint execution monitoring"
    echo "   • Immediate work focus"
    echo "   • Blocker identification"
    echo ""
    
    echo -e "${YELLOW}📊 Progress Dashboard:${NC}"
    echo "   • Detailed progress reporting"
    echo "   • Stakeholder status updates"
    echo "   • Quality and metadata tracking"
    echo "   • Comprehensive project overview"
    echo ""
}

# Function to provide roadmap view optimization tips
provide_optimization_tips() {
    echo -e "${BOLD}${BLUE}💡 Roadmap View Optimization Tips${NC}"
    echo "================================="
    echo ""
    
    echo -e "${GREEN}For your existing Roadmap View:${NC}"
    echo ""
    
    echo -e "${CYAN}🎯 Sorting Best Practices:${NC}"
    echo "   1. Primary: Priority (High → Medium → Low)"
    echo "   2. Secondary: Module Category (Foundation → Compute → Data → Security → Advanced)"
    echo "   3. Tertiary: Status (Todo → In Progress → Review → Blocked → Done)"
    echo ""
    
    echo -e "${CYAN}📋 Column Recommendations:${NC}"
    echo "   • Title (300px) - Clear issue identification"
    echo "   • Status (120px) - Current development stage"
    echo "   • Priority (100px) - Development priority"
    echo "   • Module Category (150px) - Roadmap phase"
    echo "   • Complexity (100px) - Development effort estimate"
    echo "   • Assignees (120px) - Responsibility tracking"
    echo ""
    
    echo -e "${CYAN}🔍 Filter Options:${NC}"
    echo "   • Active Work: Show Todo, In Progress, Review, Blocked (hide Done)"
    echo "   • Complete View: Show all statuses for full roadmap visibility"
    echo "   • Phase Focus: Filter by specific Module Category for phase work"
    echo ""
    
    echo -e "${CYAN}🎨 Visual Enhancements:${NC}"
    echo "   • Use Priority colors to quickly identify high-priority items"
    echo "   • Module Category grouping shows phase progression"
    echo "   • Status progression shows development flow"
    echo ""
}

# Function to show completion summary
show_completion_summary() {
    echo -e "${BOLD}${GREEN}🎉 Roadmap View Optimization Complete!${NC}"
    echo "====================================="
    echo ""
    
    echo -e "${CYAN}What you now have:${NC}"
    echo "✅ Analysis of your existing Roadmap View (View 5)"
    echo "✅ Optimization recommendations for current view"
    echo "✅ Complementary view suggestions"
    echo "✅ Browser automation for additional views"
    echo "✅ Manual setup instructions"
    echo "✅ Usage recommendations for each view type"
    echo ""
    
    echo -e "${YELLOW}Recommended next steps:${NC}"
    echo "1. Optimize your existing Roadmap View (View 5) with suggested configurations"
    echo "2. Create 2-3 complementary views using browser console or manual setup"
    echo "3. Test the views with your current 17 issues"
    echo "4. Establish team usage patterns for each view"
    echo ""
    
    echo -e "${BLUE}Your complete view set will be:${NC}"
    echo "🗺️ Roadmap View (View 5) - Strategic planning and roadmap overview"
    echo "📅 Phase Timeline - Sequential development tracking"
    echo "🏗️ Phase Board - Visual phase management"
    echo "⚡ Active Sprint - Daily execution focus"
    echo "📊 Progress Dashboard - Comprehensive reporting"
    echo ""
}

# Main execution function
main() {
    analyze_existing_view
    suggest_complementary_views
    create_complementary_views_automation
    provide_manual_setup
    show_view_usage_recommendations
    provide_optimization_tips
    show_completion_summary
}

# Command line options
case "${1:-}" in
    --analyze)
        analyze_existing_view
        provide_optimization_tips
        ;;
    --complementary)
        suggest_complementary_views
        create_complementary_views_automation
        ;;
    --manual)
        provide_manual_setup
        ;;
    --usage)
        show_view_usage_recommendations
        ;;
    --help)
        echo "Usage: $0 [--analyze|--complementary|--manual|--usage|--help]"
        echo ""
        echo "Options:"
        echo "  --analyze        Analyze existing roadmap view and provide optimization tips"
        echo "  --complementary  Show complementary views and create automation"
        echo "  --manual         Show manual setup instructions"
        echo "  --usage          Show view usage recommendations"
        echo "  --help           Show this help"
        ;;
    *)
        main
        ;;
esac
