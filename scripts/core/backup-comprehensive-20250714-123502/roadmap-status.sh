#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Roadmap Status Report Generator
# Provides detailed progress tracking against the development roadmap

set -e

echo "🗺️ $PROJECT_NAME Roadmap Status Report"
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
# REPO_OWNER loaded from config
PROJECT_NUMBER="3"
PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"

# Function to get current date info
get_date_info() {
    echo -e "${CYAN}📅 Report Date: $(date '+%B %d, %Y')${NC}"
    echo -e "${CYAN}🕒 Generated at: $(date '+%I:%M %p %Z')${NC}"
    echo ""
}

# Function to analyze module completion by phase
analyze_phase_progress() {
    local phase_name="$1"
    local modules="$2"
    
    echo -e "${BOLD}${BLUE}$phase_name${NC}"
    echo "$(printf '=%.0s' $(seq 1 ${#phase_name}))"
    
    local total_modules=0
    local complete_modules=0
    local in_progress_modules=0
    
    # Parse modules and check status
    IFS=',' read -ra MODULE_ARRAY <<< "$modules"
    for module in "${MODULE_ARRAY[@]}"; do
        module=$(echo "$module" | xargs) # trim whitespace
        ((total_modules++))
        
        if [[ -d "modules/$module" ]]; then
            # Check if module has TODOs (indicates incomplete)
            if find "modules/$module" -name "*.tf" -o -name "*.md" | xargs grep -l "TODO" 2>/dev/null >/dev/null; then
                echo -e "   🔧 ${YELLOW}$module${NC} - In Progress"
                ((in_progress_modules++))
            else
                echo -e "   ✅ ${GREEN}$module${NC} - Complete"
                ((complete_modules++))
            fi
        else
            echo -e "   📋 ${CYAN}$module${NC} - Not Started"
        fi
    done
    
    # Calculate progress percentage
    local progress=0
    if [[ $total_modules -gt 0 ]]; then
        progress=$((complete_modules * 100 / total_modules))
    fi
    
    echo ""
    echo -e "${BOLD}Progress: $complete_modules/$total_modules modules complete (${progress}%)${NC}"
    
    # Progress bar
    local bar_length=20
    local completed_bars=$((progress * bar_length / 100))
    local remaining_bars=$((bar_length - completed_bars))
    
    echo -n "["
    printf "${GREEN}%*s${NC}" $completed_bars | tr ' ' '█'
    printf "%*s" $remaining_bars | tr ' ' '░'
    echo "] ${progress}%"
    echo ""
    
    return $progress
}

# Function to show overall project status
show_project_overview() {
    echo -e "${BOLD}${PURPLE}📊 Project Overview${NC}"
    echo "=================="
    
    # Count total modules and issues
    local total_modules=$(find modules -maxdepth 1 -type d | wc -l)
    ((total_modules--)) # subtract the modules directory itself
    
    local complete_modules=0
    local incomplete_modules=0
    
    for module_dir in modules/*/; do
        if [[ -d "$module_dir" ]]; then
            # Check if module has TODOs (indicates incomplete)
            if find "$module_dir" -name "*.tf" -o -name "*.md" | xargs grep -l "TODO" 2>/dev/null >/dev/null; then
                ((incomplete_modules++))
            else
                ((complete_modules++))
            fi
        fi
    done
    
    echo "📦 Total Modules: $total_modules"
    echo -e "✅ ${GREEN}Complete: $complete_modules${NC}"
    echo -e "🔧 ${YELLOW}In Progress: $incomplete_modules${NC}"
    echo "📋 GitHub Issues: 17"
    echo "🎯 Project Board: Enhanced Kanban Workflow"
    echo ""
    
    # Get GitHub issues status if possible
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        echo -e "${BLUE}📈 Issue Distribution:${NC}"
        
        # This would require GitHub CLI access - simplified for now
        echo "   📋 Todo: Available for pickup"
        echo "   ⚡ In Progress: Being actively developed"
        echo "   👀 Review: Code review and validation"
        echo "   🚫 Blocked: Waiting on dependencies"
        echo "   ✅ Done: Complete and tested"
        echo ""
    fi
}

# Function to show roadmap phases
show_roadmap_phases() {
    echo -e "${BOLD}${CYAN}🗺️ Development Phases${NC}"
    echo "===================="
    echo ""
    
    # Phase 1: Foundation Modules
    analyze_phase_progress "Phase 1: Foundation Modules 🏗️" "az-resource-group,az-key-vault,az-virtual-network,az-storage-account"
    phase1_progress=$?
    
    # Phase 2: Compute & App Services
    analyze_phase_progress "Phase 2: Compute & App Services 🖥️" "az-virtual-machine,az-container-apps,az-app-service,az-function-app"
    phase2_progress=$?
    
    # Phase 3: Data & Analytics
    analyze_phase_progress "Phase 3: Data & Analytics 📊" "az-sql-database,az-cosmos-db,az-data-factory,az-synapse-analytics"
    phase3_progress=$?
    
    # Phase 4: Security & Networking
    analyze_phase_progress "Phase 4: Security & Networking 🛡️" "az-application-gateway,az-front-door,az-active-directory"
    phase4_progress=$?
    
    # Phase 5: Advanced Services
    analyze_phase_progress "Phase 5: Advanced Services 🤖" "az-logic-apps,az-service-bus,az-event-hub"
    phase5_progress=$?
    
    # Overall progress summary
    local overall_progress=$(((phase1_progress + phase2_progress + phase3_progress + phase4_progress + phase5_progress) / 5))
    
    echo -e "${BOLD}${GREEN}🎯 Overall Roadmap Progress: ${overall_progress}%${NC}"
    echo ""
}

# Function to show current priorities
show_current_priorities() {
    echo -e "${BOLD}${YELLOW}🎯 Current Priorities${NC}"
    echo "==================="
    echo ""
    
    echo -e "${GREEN}High Priority (Start Immediately):${NC}"
    echo "   🏗️ Resource Group - Foundation for all resources"
    echo "   🔐 Key Vault - Security and secrets management"
    echo "   🌐 Virtual Network - Network foundation"
    echo "   💾 Storage Account - Data storage foundation"
    echo ""
    
    echo -e "${YELLOW}Medium Priority (Next Sprint):${NC}"
    echo "   🖥️ Virtual Machine - IaaS compute"
    echo "   📦 Container Apps - Serverless containers"
    echo "   🚀 App Service - PaaS web applications"
    echo "   ⚡ Function App - Serverless functions"
    echo ""
    
    echo -e "${BLUE}Dependencies & Blockers:${NC}"
    echo "   • Phase 2 modules depend on Phase 1 completion"
    echo "   • Network modules need Virtual Network foundation"
    echo "   • Security modules integrate with Key Vault"
    echo ""
}

# Function to show timeline and milestones
show_timeline() {
    echo -e "${BOLD}${PURPLE}📅 Timeline & Milestones${NC}"
    echo "======================="
    echo ""
    
    echo -e "${CYAN}Q3 2025 (Current Quarter):${NC}"
    echo "   Week 1-3:  Phase 1 (Foundation Modules)"
    echo "   Week 4-7:  Phase 2 (Compute & App Services)"
    echo "   Week 8-10: Phase 3 (Data & Analytics)"
    echo "   Week 11-13: Phase 4 (Security & Networking)"
    echo ""
    
    echo -e "${CYAN}Q4 2025:${NC}"
    echo "   Week 1-4:  Phase 5 (Advanced Services)"
    echo "   Week 5-6:  Final integration testing"
    echo "   Week 7-8:  Documentation and release prep"
    echo "   Week 9-12: Beta testing and feedback"
    echo ""
    
    # Calculate current week position (simplified)
    echo -e "${GREEN}Current Focus:${NC} Foundation modules (Phase 1)"
    echo -e "${YELLOW}Next Milestone:${NC} Complete Phase 1 by end of month"
    echo ""
}

# Function to show next actions
show_next_actions() {
    echo -e "${BOLD}${GREEN}🚀 Recommended Next Actions${NC}"
    echo "=========================="
    echo ""
    
    echo -e "${CYAN}For Developers:${NC}"
    echo "   1. Pick a Phase 1 module from high-priority list"
    echo "   2. Move issue to 'In Progress' on project board"
    echo "   3. Follow module development standards"
    echo "   4. Submit for review when ready"
    echo ""
    
    echo -e "${CYAN}For Project Managers:${NC}"
    echo "   1. Monitor Phase 1 completion progress"
    echo "   2. Identify and resolve any blockers"
    echo "   3. Plan resource allocation for Phase 2"
    echo "   4. Coordinate with stakeholders"
    echo ""
    
    echo -e "${CYAN}For Team Leads:${NC}"
    echo "   1. Assign Phase 1 modules to team members"
    echo "   2. Conduct code reviews for completed work"
    echo "   3. Ensure quality standards are met"
    echo "   4. Plan for upcoming phases"
    echo ""
}

# Function to show useful commands
show_useful_commands() {
    echo -e "${BOLD}${BLUE}🛠️ Useful Commands${NC}"
    echo "=================="
    echo ""
    
    echo -e "${CYAN}Project Status:${NC}"
    echo "   ./scripts/project-automation-summary.sh"
    echo "   ./scripts/verify-kanban-status.sh"
    echo ""
    
    echo -e "${CYAN}Module Development:${NC}"
    echo "   ./scripts/validate-modules.sh"
    echo "   ./scripts/test-modules.sh"
    echo "   ./scripts/todo-management.sh"
    echo ""
    
    echo -e "${CYAN}Issue Management:${NC}"
    echo "   ./scripts/update-issues-metadata.sh"
    echo "   ./scripts/create-missing-issues.sh"
    echo ""
    
    echo -e "${CYAN}Quick Links:${NC}"
    echo "   Project Board: $PROJECT_URL"
    echo "   Repository: $REPO_URL"
    echo "   Roadmap: $REPO_URL/blob/main/ROADMAP.md"
    echo ""
}

# Main execution function
main() {
    get_date_info
    show_project_overview
    show_roadmap_phases
    show_current_priorities
    show_timeline
    show_next_actions
    show_useful_commands
    
    echo -e "${BOLD}${GREEN}🎉 Roadmap Status Report Complete!${NC}"
    echo ""
    echo -e "${YELLOW}The $PROJECT_NAME project is progressing well with:${NC}"
    echo "• Complete automation and project board setup"
    echo "• Clear roadmap with prioritized phases"
    echo "• 17 tracked issues ready for development"
    echo "• Comprehensive tooling for ongoing management"
    echo ""
    echo -e "${CYAN}Ready to begin Phase 1 development! 🚀${NC}"
}

# Command line options
case "${1:-}" in
    --overview)
        get_date_info
        show_project_overview
        ;;
    --phases)
        show_roadmap_phases
        ;;
    --priorities)
        show_current_priorities
        ;;
    --timeline)
        show_timeline
        ;;
    --actions)
        show_next_actions
        ;;
    --help)
        echo "Usage: $0 [--overview|--phases|--priorities|--timeline|--actions|--help]"
        echo ""
        echo "Options:"
        echo "  --overview     Show project overview only"
        echo "  --phases       Show roadmap phases progress"
        echo "  --priorities   Show current priorities"
        echo "  --timeline     Show timeline and milestones"
        echo "  --actions      Show recommended next actions"
        echo "  --help         Show this help"
        ;;
    *)
        main
        ;;
esac
