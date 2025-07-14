#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

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
echo ""

# List high-priority items (highest priority for current sprint)
echo "🏗️ High-Priority Items (Start Here):"
priority_issues=$(gh issue list --repo $REPO_OWNER/$REPO_NAME \
    --label "high-priority" \
    --state open \
    --limit 5 \
    --json title,number --template '{{range .}}• #{{.number}}: {{.title}}{{"\n"}}{{end}}' | head -10)

if [ -n "$priority_issues" ]; then
    echo "$priority_issues"
else
    echo "• No high-priority issues found - checking for any ready work"
fi

echo ""
echo "🖥️ Other Ready Items:"
ready_issues=$(gh issue list --repo $REPO_OWNER/$REPO_NAME \
    --label "ready-for-dev" \
    --state open \
    --limit 3 \
    --json title,number --template '{{range .}}• #{{.number}}: {{.title}}{{"\n"}}{{end}}' | head -10)

if [ -n "$ready_issues" ]; then
    echo "$ready_issues"
else
    echo "• Items ready for development"
fi

echo ""
echo "🔗 Quick Links:"
echo "• Sprint Board: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER/views/4"
echo "• Priority View: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER/views/1"
echo "• Roadmap View: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER/views/5"
