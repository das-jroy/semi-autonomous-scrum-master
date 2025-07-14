#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Complete Roadmap Integration Script
# Integrates roadmap phases with GitHub project board views and automation

set -e

echo "🎯 Complete Roadmap Integration"
echo "==============================="
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
ROADMAP_VERSION="1.0"

# Function to show integration overview
show_integration_overview() {
    echo -e "${BOLD}${CYAN}🗺️ Roadmap Integration Overview${NC}"
    echo "==============================="
    echo ""
    
    echo -e "${GREEN}Integration Components:${NC}"
    echo "📊 Project Board: Enhanced with roadmap metadata"
    echo "🎯 GitHub Issues: 17 issues mapped to roadmap phases"
    echo "📋 Custom Views: Roadmap-specific visualization"
    echo "🤖 Automation: Scripts for ongoing roadmap management"
    echo "📚 Documentation: Complete roadmap and guides"
    echo ""
    
    echo -e "${BLUE}Roadmap Phases Integration:${NC}"
    echo "• Phase 1 (Foundation): 4 modules - Resource Group, Key Vault, Virtual Network, Storage"
    echo "• Phase 2 (Compute): 4 modules - VM, Container Apps, App Service, Function App"
    echo "• Phase 3 (Data): 4 modules - SQL Database, Cosmos DB, Data Factory, Synapse"
    echo "• Phase 4 (Security): 3 modules - Application Gateway, Front Door, Active Directory"
    echo "• Phase 5 (Advanced): 3 modules - Logic Apps, Service Bus, Event Hub"
    echo ""
}

# Function to validate roadmap integration
validate_roadmap_integration() {
    echo -e "${BLUE}🔍 Validating Roadmap Integration${NC}"
    echo "================================"
    
    local integration_score=0
    local total_checks=6
    
    # Check 1: Roadmap document exists
    if [[ -f "ROADMAP.md" ]]; then
        echo -e "${GREEN}✅ Roadmap document exists${NC}"
        ((integration_score++))
    else
        echo -e "${RED}❌ Roadmap document missing${NC}"
    fi
    
    # Check 2: Roadmap status script exists
    if [[ -f "scripts/roadmap-status.sh" ]]; then
        echo -e "${GREEN}✅ Roadmap status script available${NC}"
        ((integration_score++))
    else
        echo -e "${RED}❌ Roadmap status script missing${NC}"
    fi
    
    # Check 3: Roadmap views script exists
    if [[ -f "scripts/create-roadmap-views.sh" ]]; then
        echo -e "${GREEN}✅ Roadmap views script available${NC}"
        ((integration_score++))
    else
        echo -e "${RED}❌ Roadmap views script missing${NC}"
    fi
    
    # Check 4: GitHub issues exist
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        local issue_count=$(gh issue list --repo "$REPO_OWNER/$REPO_NAME" --limit 100 --json number | jq length 2>/dev/null || echo "0")
        if [[ $issue_count -ge 15 ]]; then
            echo -e "${GREEN}✅ GitHub issues created ($issue_count issues)${NC}"
            ((integration_score++))
        else
            echo -e "${YELLOW}⚠️  Limited GitHub issues ($issue_count issues)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  GitHub CLI not available for issue check${NC}"
    fi
    
    # Check 5: Module structure exists
    local module_count=$(find modules -maxdepth 1 -type d | wc -l)
    ((module_count--)) # subtract modules directory itself
    if [[ $module_count -ge 8 ]]; then
        echo -e "${GREEN}✅ Module structure exists ($module_count modules)${NC}"
        ((integration_score++))
    else
        echo -e "${YELLOW}⚠️  Limited module structure ($module_count modules)${NC}"
    fi
    
    # Check 6: Browser automation scripts exist
    if [[ -f "browser-console-roadmap-views.js" ]]; then
        echo -e "${GREEN}✅ Browser automation scripts available${NC}"
        ((integration_score++))
    else
        echo -e "${RED}❌ Browser automation scripts missing${NC}"
    fi
    
    echo ""
    
    # Calculate integration percentage
    local integration_percentage=$((integration_score * 100 / total_checks))
    
    echo -e "${BOLD}Integration Score: $integration_score/$total_checks (${integration_percentage}%)${NC}"
    
    if [[ $integration_percentage -ge 80 ]]; then
        echo -e "${GREEN}🎉 Excellent roadmap integration!${NC}"
    elif [[ $integration_percentage -ge 60 ]]; then
        echo -e "${YELLOW}⚠️  Good integration, some improvements possible${NC}"
    else
        echo -e "${RED}❌ Integration needs improvement${NC}"
    fi
    
    echo ""
}

# Function to show available roadmap commands
show_roadmap_commands() {
    echo -e "${BOLD}${PURPLE}🛠️ Available Roadmap Commands${NC}"
    echo "============================="
    echo ""
    
    echo -e "${CYAN}Core Roadmap Management:${NC}"
    echo "   📊 ./scripts/roadmap-status.sh - Complete roadmap progress report"
    echo "   📋 ./scripts/create-roadmap-views.sh - Create roadmap-specific views"
    echo "   🔍 ./scripts/verify-kanban-status.sh - Verify kanban workflow"
    echo "   📈 ./scripts/project-automation-summary.sh - Overall project status"
    echo ""
    
    echo -e "${CYAN}Issue & Board Management:${NC}"
    echo "   📝 ./scripts/secure-github-issues.sh - Create issues from TODOs"
    echo "   🔧 ./scripts/update-issues-metadata.sh - Update issue metadata"
    echo "   ✅ ./scripts/add-issues-to-project.sh - Add issues to board"
    echo ""
    
    echo -e "${CYAN}Module Development:${NC}"
    echo "   🏗️ ./scripts/scaffold-remaining-modules.sh - Create module scaffolds"
    echo "   ✅ ./scripts/validate-modules.sh - Validate module completion"
    echo "   🔍 ./scripts/test-modules.sh - Run module tests"
    echo ""
    
    echo -e "${CYAN}Browser Automation:${NC}"
    echo "   🌐 browser-console-roadmap-views.js - Create views via browser"
    echo "   🎯 browser-console-kanban-enhancement.js - Enhance kanban via browser"
    echo ""
}

# Function to generate roadmap workflow guide
generate_roadmap_workflow() {
    echo -e "${BLUE}📋 Generating Roadmap Workflow Guide${NC}"
    echo "===================================="
    
    cat > "ROADMAP-WORKFLOW.md" << 'EOF'
# Roadmap Workflow Guide

This guide outlines how to use the roadmap integration with your GitHub project board for effective development tracking.

## 🎯 Quick Start

### Daily Workflow
1. **Check Progress:** `./scripts/roadmap-status.sh`
2. **Pick Work:** Visit project board and select high-priority Phase 1 items
3. **Update Status:** Move issues through kanban workflow
4. **Track Dependencies:** Use "Blocked" status for dependencies

### Weekly Planning
1. **Review Phases:** Check phase completion percentages
2. **Resource Planning:** Assign team members to priority modules
3. **Dependency Management:** Ensure Phase 1 completion before Phase 2
4. **Stakeholder Updates:** Use roadmap progress for reporting

## 🗺️ Roadmap Views

### 1. Roadmap Timeline (Table View)
- **Purpose:** Sequential development tracking
- **Sort:** Priority (High→Low), Module Category
- **Use:** Sprint planning and work prioritization

### 2. Phase Board (Board View)
- **Purpose:** Phase-based visual management
- **Group by:** Module Category
- **Use:** Resource allocation across phases

### 3. Roadmap Progress (Table View)
- **Purpose:** Comprehensive progress tracking
- **Columns:** All metadata visible
- **Use:** Detailed monitoring and reporting

### 4. Sprint Board (Board View)
- **Purpose:** Active sprint management
- **Group by:** Status
- **Use:** Daily standups and sprint execution

## 📊 Progress Tracking

### Phase Completion Metrics
- **Foundation (Phase 1):** Resource Group → Key Vault → Virtual Network → Storage
- **Compute (Phase 2):** VM → Container Apps → App Service → Function App
- **Data (Phase 3):** SQL → Cosmos DB → Data Factory → Synapse
- **Security (Phase 4):** App Gateway → Front Door → Active Directory
- **Advanced (Phase 5):** Logic Apps → Service Bus → Event Hub

### Quality Gates
- [ ] Terraform validation passes
- [ ] Integration tests complete
- [ ] Documentation updated
- [ ] Security review passed
- [ ] Code review approved

## 🚀 Automation Commands

### Status Checks
```bash
# Overall roadmap status
./scripts/roadmap-status.sh

# Kanban workflow verification
./scripts/verify-kanban-status.sh

# Project automation summary
./scripts/project-automation-summary.sh
```

### Development Support
```bash
# Validate modules
./scripts/validate-modules.sh

# Test modules
./scripts/test-modules.sh

# Update issue metadata
./scripts/update-issues-metadata.sh
```

### View Management
```bash
# Create roadmap views
./scripts/create-roadmap-views.sh

# Manual browser console setup
# Use: browser-console-roadmap-views.js
```

## 🎯 Best Practices

### Development Workflow
1. **Start with Phase 1:** Foundation modules must be complete first
2. **Follow Dependencies:** Check module dependencies before starting
3. **Update Status Regularly:** Keep project board current
4. **Use Review Status:** Move to review when code is ready
5. **Track Blockers:** Use "Blocked" status for dependency issues

### Team Coordination
1. **Daily Standups:** Use Sprint Board view for status updates
2. **Sprint Planning:** Use Roadmap Timeline for prioritization
3. **Resource Planning:** Use Phase Board for team allocation
4. **Progress Reporting:** Use Roadmap Progress for stakeholder updates

### Quality Assurance
1. **Code Reviews:** All changes require review
2. **Testing:** Each module needs comprehensive tests
3. **Documentation:** Keep READMEs and examples current
4. **Security:** Security review required for each module

## 📈 Success Metrics

### Velocity Tracking
- **Modules per Sprint:** Target 2-3 modules per 2-week sprint
- **Phase Completion:** Track percentage complete per phase
- **Quality Score:** Maintain high quality standards
- **Dependency Resolution:** Minimize blocked time

### Project Health
- **Issue Velocity:** Issues moving through workflow
- **Code Quality:** No major security or quality issues
- **Documentation Coverage:** All modules documented
- **Test Coverage:** All modules tested

## 🔗 Resources

- **Project Board:** https://github.com/orgs/$REPO_OWNER/projects/3
- **Roadmap Document:** [ROADMAP.md](ROADMAP.md)
- **Automation Scripts:** [scripts/README.md](scripts/README.md)
- **Contributing Guide:** [CONTRIBUTING.md](CONTRIBUTING.md)

---

This workflow integrates roadmap planning with daily development activities for maximum effectiveness.
EOF

    echo -e "${GREEN}✅ Generated: ROADMAP-WORKFLOW.md${NC}"
    echo ""
}

# Function to show next steps for roadmap implementation
show_roadmap_next_steps() {
    echo -e "${BOLD}${GREEN}🚀 Roadmap Implementation Next Steps${NC}"
    echo "===================================="
    echo ""
    
    echo -e "${CYAN}Immediate Actions (Today):${NC}"
    echo "1. Create roadmap views using browser console or manual setup"
    echo "2. Review and prioritize Phase 1 foundation modules"
    echo "3. Assign team members to high-priority issues"
    echo "4. Set up Sprint Board view if not already done"
    echo ""
    
    echo -e "${CYAN}This Week:${NC}"
    echo "1. Begin Phase 1 module development"
    echo "2. Establish daily standup using Sprint Board"
    echo "3. Run weekly roadmap status reports"
    echo "4. Track progress and resolve blockers"
    echo ""
    
    echo -e "${CYAN}This Month:${NC}"
    echo "1. Complete Phase 1 (Foundation Modules)"
    echo "2. Prepare for Phase 2 (Compute Services)"
    echo "3. Establish quality gates and review process"
    echo "4. Document lessons learned and process improvements"
    echo ""
    
    echo -e "${BLUE}Key Commands to Remember:${NC}"
    echo "• Daily: ./scripts/roadmap-status.sh"
    echo "• Weekly: ./scripts/project-automation-summary.sh"
    echo "• As needed: ./scripts/verify-kanban-status.sh"
    echo ""
}

# Main execution function
main() {
    show_integration_overview
    validate_roadmap_integration
    show_roadmap_commands
    generate_roadmap_workflow
    show_roadmap_next_steps
    
    echo -e "${BOLD}${GREEN}🎉 Roadmap Integration Complete!${NC}"
    echo ""
    echo -e "${YELLOW}Your $PROJECT_NAME project now has:${NC}"
    echo "• ✅ Complete roadmap with 5 development phases"
    echo "• 📊 Real-time progress tracking and reporting"
    echo "• 🎯 Roadmap-specific project board views"
    echo "• 🤖 Comprehensive automation scripts"
    echo "• 📚 Complete workflow documentation"
    echo ""
    echo -e "${CYAN}Ready to begin systematic development following the roadmap! 🚀${NC}"
}

# Command line options
case "${1:-}" in
    --status)
        validate_roadmap_integration
        ;;
    --commands)
        show_roadmap_commands
        ;;
    --workflow)
        generate_roadmap_workflow
        ;;
    --next-steps)
        show_roadmap_next_steps
        ;;
    --help)
        echo "Usage: $0 [--status|--commands|--workflow|--next-steps|--help]"
        echo ""
        echo "Options:"
        echo "  --status       Validate roadmap integration"
        echo "  --commands     Show available roadmap commands"
        echo "  --workflow     Generate roadmap workflow guide"
        echo "  --next-steps   Show recommended next steps"
        echo "  --help         Show this help"
        ;;
    *)
        main
        ;;
esac
