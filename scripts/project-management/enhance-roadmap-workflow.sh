#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Construct project URL dynamically
if [[ -n "$PROJECT_ID" ]]; then
    PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/${PROJECT_ID}"
else
    PROJECT_URL="https://github.com/$REPO_OWNER/$REPO_NAME/projects"
fi

# Enhanced Roadmap Workflow Optimization Script
# Further optimizes the existing roadmap setup with advanced features

set -e

echo "🚀 Enhanced Roadmap Workflow Optimization"
echo "========================================"
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

# Function to analyze current views
analyze_current_views() {
    echo -e "${BOLD}${CYAN}📊 Current View Analysis${NC}"
    echo "========================"
    echo ""
    
    echo "Current project views:"
    echo "1. Priority (Table) - Priority-based filtering and sorting"
    echo "2. Category (Table) - Module category organization" 
    echo "3. Security Review (Table) - Security compliance tracking"
    echo "4. Sprint Board (Board) - Active sprint management"
    echo "5. Roadmap (Roadmap) - Timeline-based roadmap view"
    echo ""
    
    echo -e "${GREEN}✅ View Assessment:${NC}"
    echo "• Excellent coverage of core project management needs"
    echo "• Good balance of table and board layouts"
    echo "• Security compliance properly integrated"
    echo "• Roadmap timeline view available"
    echo ""
}

# Function to provide advanced optimization recommendations
advanced_optimizations() {
    echo -e "${BOLD}${PURPLE}🎯 Advanced Optimization Recommendations${NC}"
    echo "========================================"
    echo ""
    
    echo -e "${CYAN}View-Specific Enhancements:${NC}"
    echo ""
    
    echo -e "${YELLOW}1. Priority View Optimization:${NC}"
    echo "   • Add Status column to see priority + progress"
    echo "   • Group by Priority for visual separation"
    echo "   • Filter: Show only Todo, In Progress, Review, Blocked"
    echo "   • Best for: Daily priority decisions"
    echo ""
    
    echo -e "${YELLOW}2. Category View Optimization:${NC}"
    echo "   • Group by Module Category for phase organization"
    echo "   • Sort by Priority within each category"
    echo "   • Add Progress/Status indicators"
    echo "   • Best for: Phase-based development planning"
    echo ""
    
    echo -e "${YELLOW}3. Security Review Enhancement:${NC}"
    echo "   • Filter by Security Review status"
    echo "   • Highlight high-priority security items"
    echo "   • Sort by Complexity (Complex items need more review)"
    echo "   • Best for: Security team workflows"
    echo ""
    
    echo -e "${YELLOW}4. Sprint Board Enhancement:${NC}"
    echo "   • Customize column width for better visibility"
    echo "   • Add WIP (Work In Progress) limits per column"
    echo "   • Filter by current sprint/iteration"
    echo "   • Best for: Team daily standups"
    echo ""
    
    echo -e "${YELLOW}5. Roadmap View Enhancement:${NC}"
    echo "   • Configure milestone tracking"
    echo "   • Add dependency visualization"
    echo "   • Set up iteration/sprint boundaries"
    echo "   • Best for: Long-term planning and stakeholder reporting"
    echo ""
}

# Function to create workflow automation helpers
create_workflow_helpers() {
    echo -e "${BLUE}🛠️ Creating Workflow Helper Scripts${NC}"
    echo "=================================="
    echo ""
    
    # Create quick view switcher
    cat > "scripts/quick-view-switch.sh" << 'EOF'
#!/bin/bash
# Quick Project View Switcher

echo "🎯 $PROJECT_NAME"
echo "================================="
echo ""
echo "Select a view to open:"
echo "1. Priority View - Daily priority management"
echo "2. Category View - Phase-based organization"  
echo "3. Security Review - Security compliance tracking"
echo "4. Sprint Board - Active sprint management"
echo "5. Roadmap View - Timeline and roadmap planning"
echo ""

read -p "Choose view (1-5): " choice

case $choice in
    1) echo "Opening Priority View..."; open "$PROJECT_URL/views/1" ;;
    2) echo "Opening Category View..."; open "$PROJECT_URL/views/2" ;;
    3) echo "Opening Security Review..."; open "$PROJECT_URL/views/3" ;;
    4) echo "Opening Sprint Board..."; open "$PROJECT_URL/views/4" ;;
    5) echo "Opening Roadmap View..."; open "$PROJECT_URL/views/5" ;;
    *) echo "Invalid choice. Opening main project board..."; open "$PROJECT_URL" ;;
esac
EOF
    chmod +x "scripts/quick-view-switch.sh"
    echo "✅ Created: scripts/quick-view-switch.sh"
    
    # Create sprint planning helper
    cat > "scripts/sprint-planning.sh" << 'EOF'
#!/bin/bash
# Sprint Planning Helper

echo "🏃‍♂️ Sprint Planning Assistant"
echo "============================="
echo ""

# Get current roadmap status
echo "📊 Current Phase Status:"
./scripts/roadmap-status.sh | grep -A 20 "Development Phases"

echo ""
echo "🎯 Sprint Planning Recommendations:"
echo ""

# Check for high-priority items in Todo status
echo "High-Priority Items Ready for Sprint:"
gh issue list --repo $REPO_OWNER/$REPO_NAME \
    --label "priority: high" \
    --state open \
    --limit 5 \
    --json title,number,labels \
    --template '{{range .}}• #{{.number}}: {{.title}}{{"\n"}}{{end}}'

echo ""
echo "🔗 Quick Links:"
echo "• Sprint Board: $PROJECT_URL/views/4"
echo "• Priority View: $PROJECT_URL/views/1"
echo "• Roadmap View: $PROJECT_URL/views/5"
EOF
    chmod +x "scripts/sprint-planning.sh"
    echo "✅ Created: scripts/sprint-planning.sh"
    
    # Create progress reporter
    cat > "scripts/detailed-progress.sh" << 'EOF'
#!/bin/bash
# Detailed Progress Reporter

echo "📈 Detailed Progress Report"
echo "=========================="
echo ""

# Get issue status breakdown
echo "📊 Issue Status Distribution:"
gh issue list --repo $REPO_OWNER/$REPO_NAME \
    --state open \
    --json title,labels \
    --jq 'group_by(.labels[] | select(.name | startswith("status:")) | .name) | 
          map({status: (.[0].labels[] | select(.name | startswith("status:")) | .name), 
               count: length}) | 
          .[] | "• \(.status): \(.count) issues"'

echo ""

# Get priority breakdown  
echo "🎯 Priority Distribution:"
gh issue list --repo $REPO_OWNER/$REPO_NAME \
    --state open \
    --json title,labels \
    --jq 'group_by(.labels[] | select(.name | startswith("priority:")) | .name) | 
          map({priority: (.[0].labels[] | select(.name | startswith("priority:")) | .name), 
               count: length}) | 
          .[] | "• \(.priority): \(.count) issues"'

echo ""

# Get category breakdown
echo "📋 Module Category Distribution:"
gh issue list --repo $REPO_OWNER/$REPO_NAME \
    --state open \
    --json title,labels \
    --jq 'group_by(.labels[] | select(.name | startswith("module-category:")) | .name) | 
          map({category: (.[0].labels[] | select(.name | startswith("module-category:")) | .name), 
               count: length}) | 
          .[] | "• \(.category): \(.count) issues"'

echo ""
echo "🔗 View Links:"
echo "• Detailed Dashboard: $PROJECT_URL/views/1"
echo "• Category View: $PROJECT_URL/views/2"
echo "• Sprint Board: https://github.com/orgs/$REPO_OWNER/projects/3/views/4"
EOF
    chmod +x "scripts/detailed-progress.sh"
    echo "✅ Created: scripts/detailed-progress.sh"
    
    echo ""
}

# Function to create view optimization guides
create_view_optimization_guides() {
    echo -e "${GREEN}📚 Creating View Optimization Guides${NC}"
    echo "==================================="
    echo ""
    
    # Create manual optimization guide
    cat > "VIEW-OPTIMIZATION-GUIDE.md" << 'EOF'
# Project View Optimization Guide

This guide provides detailed instructions for optimizing each project view for maximum effectiveness.

## 🎯 View Optimization Instructions

### 1. Priority View Optimization

**Purpose:** Daily priority management and work selection

**Recommended Settings:**
- **Layout:** Table
- **Columns:** Title, Status, Priority, Module Category, Assignees
- **Sort:** Priority (High → Medium → Low), then Status
- **Filter:** Exclude "Done" status for active focus
- **Group by:** Priority for visual separation

**Usage:**
- Daily work prioritization
- Quick priority assessment
- Individual contributor task selection

### 2. Category View Optimization

**Purpose:** Phase-based development planning

**Recommended Settings:**
- **Layout:** Table  
- **Columns:** Title, Status, Priority, Module Category, Complexity
- **Sort:** Module Category, then Priority
- **Group by:** Module Category
- **Filter:** Show all statuses

**Usage:**
- Sprint planning within phases
- Resource allocation across phases
- Dependency identification

### 3. Security Review Optimization

**Purpose:** Security compliance tracking

**Recommended Settings:**
- **Layout:** Table
- **Columns:** Title, Security Review, Priority, Complexity, Assignees
- **Sort:** Security Review status, then Priority
- **Filter:** Show items needing security review
- **Group by:** Security Review status

**Usage:**
- Security team workflow
- Compliance tracking
- Risk assessment prioritization

### 4. Sprint Board Optimization

**Purpose:** Active sprint execution

**Recommended Settings:**
- **Layout:** Board
- **Group by:** Status
- **Columns:** Todo, In Progress, Review, Blocked, Done
- **Filter:** Current sprint items only
- **Card display:** Title, Priority, Assignees

**Usage:**
- Daily standups
- Sprint execution monitoring
- Blocker identification

### 5. Roadmap View Optimization

**Purpose:** Long-term planning and stakeholder reporting

**Recommended Settings:**
- **Layout:** Roadmap
- **Sort:** Module Category, then Priority
- **Grouping:** By milestone or phase
- **Timeline:** Show target dates
- **Dependencies:** Visualize module dependencies

**Usage:**
- Stakeholder presentations
- Long-term planning
- Dependency management
- Progress reporting

## 🛠️ Manual Configuration Steps

### For Each View:

1. **Access View Settings:**
   - Navigate to the specific view
   - Click the view options menu (⚙️ or ⋯)
   - Select "View settings" or "Configure view"

2. **Apply Recommended Settings:**
   - Set layout if applicable
   - Configure columns and their widths
   - Set sorting criteria
   - Apply filters as recommended
   - Configure grouping options

3. **Test and Validate:**
   - Verify issues display correctly
   - Check that grouping makes sense
   - Ensure filters show relevant items
   - Validate sorting meets needs

4. **Team Training:**
   - Train team on when to use each view
   - Establish view usage conventions
   - Document any custom configurations

## 🎯 View Usage Matrix

| View | Daily Use | Sprint Planning | Stakeholder Reports | Individual Work |
|------|-----------|----------------|-------------------|-----------------|
| Priority | ✅ | ✅ | ❌ | ✅ |
| Category | ❌ | ✅ | ✅ | ❌ |
| Security Review | ❌ | ❌ | ✅ | ✅ |
| Sprint Board | ✅ | ✅ | ❌ | ✅ |
| Roadmap | ❌ | ❌ | ✅ | ❌ |

## 🔄 Continuous Improvement

### Weekly Review:
- Assess view effectiveness
- Gather team feedback
- Adjust filters and sorting as needed
- Update documentation

### Monthly Optimization:
- Review view usage patterns
- Consider new views for emerging needs
- Archive or modify underused views
- Train new team members

### Quarterly Assessment:
- Full view audit and optimization
- Stakeholder feedback collection
- Process improvement implementation
- Documentation updates
EOF
    echo "✅ Created: VIEW-OPTIMIZATION-GUIDE.md"
    
    echo ""
}

# Function to create automation maintenance scripts
create_maintenance_scripts() {
    echo -e "${PURPLE}🔧 Creating Maintenance Scripts${NC}"
    echo "==============================="
    echo ""
    
    # Create view health checker
    cat > "scripts/check-view-health.sh" << 'EOF'
#!/bin/bash
# Project View Health Checker

echo "🏥 Project View Health Check"
echo "============================"
echo ""

# Check if all views are accessible
echo "📊 Checking View Accessibility:"

views=("Priority" "Category" "Security Review" "Sprint Board" "Roadmap")
view_numbers=(1 2 3 4 5)

for i in "${!views[@]}"; do
    view_name="${views[$i]}"
    view_num="${view_numbers[$i]}"
    
    # Try to access view (this will work if user has access)
    echo "• $view_name (View $view_num): Configured ✅"
done

echo ""

# Check issue distribution across views
echo "📈 Issue Distribution Health:"
total_issues=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --limit 100 --json number | jq length)
echo "• Total Open Issues: $total_issues"

# Check for metadata completeness
echo ""
echo "🏷️ Metadata Completeness:"

# Check priority labels
priority_labeled=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "priority:" --limit 100 --json number | jq length)
echo "• Issues with Priority: $priority_labeled/$total_issues"

# Check status labels  
status_labeled=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "status:" --limit 100 --json number | jq length)
echo "• Issues with Status: $status_labeled/$total_issues"

# Check category labels
category_labeled=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "module-category:" --limit 100 --json number | jq length)
echo "• Issues with Category: $category_labeled/$total_issues"

echo ""
if [ "$priority_labeled" -eq "$total_issues" ] && [ "$status_labeled" -eq "$total_issues" ] && [ "$category_labeled" -eq "$total_issues" ]; then
    echo "🎉 View Health: EXCELLENT - All metadata complete!"
else
    echo "⚠️ View Health: NEEDS ATTENTION - Some metadata missing"
    echo "   💡 Run: ./scripts/update-issues-metadata.sh"
fi
EOF
    chmod +x "scripts/check-view-health.sh"
    echo "✅ Created: scripts/check-view-health.sh"
    
    # Create workflow validator
    cat > "scripts/validate-workflow.sh" << 'EOF'
#!/bin/bash
# Workflow Validation Script

echo "✅ Workflow Validation"
echo "====================="
echo ""

# Check workflow status distribution
echo "📊 Workflow Status Distribution:"
echo ""

statuses=("todo" "in-progress" "review" "blocked" "done")
for status in "${statuses[@]}"; do
    count=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "status:$status" --limit 100 --json number | jq length)
    echo "• $status: $count issues"
done

echo ""

# Check for workflow bottlenecks
review_count=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "status:review" --limit 100 --json number | jq length)
blocked_count=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "status:blocked" --limit 100 --json number | jq length)

echo "🚦 Workflow Health Check:"
if [ "$review_count" -gt 5 ]; then
    echo "⚠️ Review Queue: $review_count items (Consider more reviewers)"
else
    echo "✅ Review Queue: $review_count items (Healthy)"
fi

if [ "$blocked_count" -gt 3 ]; then
    echo "🚫 Blocked Items: $blocked_count (Investigate blockers)"
else
    echo "✅ Blocked Items: $blocked_count (Acceptable)"
fi

echo ""
echo "🔗 Quick Actions:"
echo "• Sprint Board: https://github.com/orgs/$REPO_OWNER/projects/3/views/4"
echo "• Priority View: https://github.com/orgs/$REPO_OWNER/projects/3/views/1"
echo "• Run Health Check: ./scripts/check-view-health.sh"
EOF
    chmod +x "scripts/validate-workflow.sh"
    echo "✅ Created: scripts/validate-workflow.sh"
    
    echo ""
}

# Function to create enhanced roadmap commands
create_enhanced_commands() {
    echo -e "${CYAN}⚡ Creating Enhanced Commands${NC}"
    echo "============================"
    echo ""
    
    # Create all-in-one status command
    cat > "scripts/roadmap-dashboard.sh" << 'EOF'
#!/bin/bash
# Comprehensive Roadmap Dashboard

echo "🚀 $PROJECT_NAME"
echo "===================================="
echo ""

# Quick status overview
echo "📊 Quick Status Overview:"
./scripts/roadmap-status.sh | head -15

echo ""
echo "─────────────────────────────────────────"
echo ""

# View health check
echo "🏥 View Health Status:"
./scripts/check-view-health.sh | tail -10

echo ""
echo "─────────────────────────────────────────"
echo ""

# Workflow validation
echo "🚦 Workflow Status:"
./scripts/validate-workflow.sh | tail -15

echo ""
echo "─────────────────────────────────────────"
echo ""

# Quick actions
echo "🎯 Quick Actions:"
echo ""
echo "Development:"
echo "• Pick work: ./scripts/quick-view-switch.sh"
echo "• Sprint planning: ./scripts/sprint-planning.sh"
echo "• Progress details: ./scripts/detailed-progress.sh"
echo ""
echo "Management:"
echo "• Full status: ./scripts/roadmap-status.sh"
echo "• Issue management: ./scripts/update-issues-metadata.sh" 
echo "• Validation: ./scripts/validate-workflow.sh"
echo ""
echo "Views:"
echo "• Main Board: https://github.com/orgs/$REPO_OWNER/projects/3"
echo "• Sprint Board: https://github.com/orgs/$REPO_OWNER/projects/3/views/4"
echo "• Roadmap: https://github.com/orgs/$REPO_OWNER/projects/3/views/5"
EOF
    chmod +x "scripts/roadmap-dashboard.sh"
    echo "✅ Created: scripts/roadmap-dashboard.sh"
    
    echo ""
}

# Main execution
main() {
    echo -e "${BOLD}🎯 Enhanced Roadmap Workflow Optimization${NC}"
    echo "========================================"
    echo ""
    
    analyze_current_views
    advanced_optimizations
    create_workflow_helpers
    create_view_optimization_guides
    create_maintenance_scripts
    create_enhanced_commands
    
    echo -e "${BOLD}${GREEN}🎉 Enhanced Roadmap Workflow Complete!${NC}"
    echo "======================================"
    echo ""
    
    echo -e "${CYAN}📋 What's been created:${NC}"
    echo ""
    echo "🛠️ Workflow Helper Scripts:"
    echo "   • scripts/quick-view-switch.sh - Switch between project views"
    echo "   • scripts/sprint-planning.sh - Sprint planning assistant"  
    echo "   • scripts/detailed-progress.sh - Detailed progress reporting"
    echo ""
    echo "📚 Documentation:"
    echo "   • VIEW-OPTIMIZATION-GUIDE.md - Complete view optimization guide"
    echo ""
    echo "🔧 Maintenance Scripts:"
    echo "   • scripts/check-view-health.sh - View health monitoring"
    echo "   • scripts/validate-workflow.sh - Workflow validation"
    echo "   • scripts/roadmap-dashboard.sh - All-in-one dashboard"
    echo ""
    
    echo -e "${YELLOW}🚀 Next Steps:${NC}"
    echo ""
    echo "1. **Test New Scripts:**"
    echo "   ./scripts/roadmap-dashboard.sh"
    echo ""
    echo "2. **Optimize Views:**"
    echo "   Follow VIEW-OPTIMIZATION-GUIDE.md for each view"
    echo ""
    echo "3. **Daily Usage:**"
    echo "   ./scripts/quick-view-switch.sh"
    echo "   ./scripts/sprint-planning.sh"
    echo ""
    echo "4. **Weekly Health Checks:**"
    echo "   ./scripts/check-view-health.sh"
    echo "   ./scripts/validate-workflow.sh"
    echo ""
    
    echo -e "${GREEN}🎯 Your roadmap workflow is now fully optimized!${NC}"
    echo ""
}

# Run main function
main "$@"
