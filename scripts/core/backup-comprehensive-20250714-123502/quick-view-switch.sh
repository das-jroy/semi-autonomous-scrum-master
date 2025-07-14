#!/bin/bash

# Quick Project View Switcher
# Rapidly switch between different project board views

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

echo "🎯 Project View Switcher"
echo "========================"

# Load configuration
load_config

if [[ -z "$REPO_OWNER" || -z "$PROJECT_ID" ]]; then
    echo "❌ Missing configuration. Please ensure your config file has:"
    echo "  - project.owner"
    echo "  - project.project_id"
    echo ""
    echo "You can find your project ID by visiting your GitHub project and"
    echo "looking at the URL: https://github.com/orgs/YOUR_ORG/projects/PROJECT_ID"
    exit 1
fi

echo "Repository: $REPO_OWNER"
echo "Project ID: $PROJECT_ID"
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
    1) echo "Opening Priority View..."; open "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID/views/1" ;;
    2) echo "Opening Category View..."; open "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID/views/2" ;;
    3) echo "Opening Security Review..."; open "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID/views/3" ;;
    4) echo "Opening Sprint Board..."; open "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID/views/4" ;;
    5) echo "Opening Roadmap View..."; open "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID/views/5" ;;
    *) echo "Invalid choice. Opening main project board..."; open "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID" ;;
esac
