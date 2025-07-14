#!/bin/bash

# Setup Wizard - Interactive configuration for new projects
# Guides users through the initial setup process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧙‍♂️ Semi-Autonomous Scrum Master Setup Wizard${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""
echo "This wizard will help you configure your project for automated"
echo "GitHub issue and project board management."
echo ""

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Please install GitHub CLI first:"
    echo "  brew install gh  # macOS"
    echo "  or visit: https://cli.github.com/"
    exit 1
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI is not authenticated${NC}"
    echo "Please authenticate first:"
    echo "  gh auth login"
    exit 1
fi

# Check jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed (recommended for JSON processing)${NC}"
    echo "Install with: brew install jq"
    echo ""
fi

echo -e "${GREEN}✅ Prerequisites checked${NC}"
echo ""

# Collect project information
echo -e "${BLUE}📝 Project Configuration${NC}"
echo "=============================="

read -p "GitHub username or organization: " repo_owner
read -p "Repository name: " repo_name
read -p "Project display name: " project_name
read -p "Project description: " project_desc

echo ""
echo -e "${BLUE}🏗️ Project Type Selection${NC}"
echo "========================="
echo "Choose your project type:"
echo "1) Web Application (frontend + backend)"
echo "2) API Service (REST API/microservice)"
echo "3) Infrastructure (cloud/DevOps)"
echo "4) Generic (custom configuration)"
echo ""
read -p "Select project type (1-4): " project_type_choice

case $project_type_choice in
    1) project_type="web-application" ;;
    2) project_type="api-service" ;;
    3) project_type="infrastructure" ;;
    4) project_type="generic" ;;
    *) project_type="web-application" ;;
esac

echo ""
echo -e "${BLUE}👥 Team Configuration${NC}"
echo "===================="
echo "Choose your team profile:"
echo "1) Standard Team (5 people, 2-week sprints)"
echo "2) Agile Team (7 people, 1-week sprints)"
echo "3) Custom (configure manually)"
echo ""
read -p "Select team profile (1-3): " team_choice

case $team_choice in
    1) 
        sprint_duration=2
        team_capacity=40
        ;;
    2)
        sprint_duration=1
        team_capacity=60
        ;;
    3)
        read -p "Sprint duration (weeks): " sprint_duration
        read -p "Team capacity (story points per sprint): " team_capacity
        ;;
    *)
        sprint_duration=2
        team_capacity=40
        ;;
esac

# Generate configuration file
echo ""
echo -e "${BLUE}⚙️ Generating configuration...${NC}"

CONFIG_FILE="configs/project-config.json"

cat > "$CONFIG_FILE" << EOF
{
  "project": {
    "name": "$project_name",
    "description": "$project_desc",
    "owner": "$repo_owner",
    "repository": "$repo_name",
    "project_id": ""
  },
  "project_type": "$project_type",
  "defaults": {
    "sprint_duration_weeks": $sprint_duration,
    "team_capacity_points": $team_capacity,
    "default_assignee": "",
    "default_labels": ["enhancement", "bug", "task"]
  },
  "issue_types": {
    "feature": "Feature",
    "bug": "Bug", 
    "task": "Task",
    "epic": "Epic",
    "story": "Story"
  },
  "project_views": {
    "board": "Kanban Board",
    "table": "Issue Table",
    "roadmap": "Project Roadmap",
    "sprint": "Sprint Board",
    "backlog": "Product Backlog"
  }
}
EOF

echo -e "${GREEN}✅ Configuration saved to: $CONFIG_FILE${NC}"

# Summary
echo ""
echo -e "${CYAN}📋 Configuration Summary${NC}"
echo "========================"
echo "Repository: $repo_owner/$repo_name"
echo "Project: $project_name"
echo "Type: $project_type"
echo "Sprint Duration: $sprint_duration weeks"
echo "Team Capacity: $team_capacity points"
echo ""

# Next steps
echo -e "${PURPLE}🚀 Next Steps${NC}"
echo "============="
echo "1. Add your documentation to: examples/sample-docs/"
echo "2. Run: ./scripts/core/process-documentation.sh"
echo "3. Run: ./scripts/core/setup-project.sh"
echo ""
echo "Or run the complete setup:"
echo "  ./scripts/core/complete-setup.sh"
echo ""

read -p "Would you like to open the sample documentation directory? (y/n): " open_docs
if [[ "$open_docs" =~ ^[Yy] ]]; then
    if command -v open &> /dev/null; then
        open examples/sample-docs/
    elif command -v xdg-open &> /dev/null; then
        xdg-open examples/sample-docs/
    else
        echo "Please manually navigate to: examples/sample-docs/"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Setup wizard completed!${NC}"
echo "Your project is now configured for automated scrum management."
