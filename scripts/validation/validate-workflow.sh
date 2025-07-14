#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Workflow Validation Script

echo "✅ Workflow Validation"
echo "====================="
echo ""

# Check workflow status distribution
echo "📊 Workflow Status Distribution:"
echo "Note: GitHub Projects v2 uses custom Status field instead of labels"
echo "• All new issues start in 'Todo' status by default"
echo "• Status changes are tracked through the project board"
echo ""

# Get general issue counts by type
echo "📋 Issue Categories:"
total_features=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "implementation" --limit 100 --json number | jq length)
total_docs=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "documentation" --limit 100 --json number | jq length)
total_infra=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "infrastructure" --limit 100 --json number | jq length)

echo "• Feature implementation: $total_features issues"
echo "• Documentation: $total_docs issues"  
echo "• Infrastructure: $total_infra issues"
echo ""

# Workflow health based on issue distribution
echo "🚦 Workflow Health Check:"
if [ "$total_features" -gt 10 ]; then
    echo "📈 Active Development: $total_features feature issues ready for work"
else
    echo "✅ Focused Development: $total_features feature issues in backlog"
fi

echo "✅ Workflow Status: Ready for development"
echo "� Use the project board to move issues through workflow stages"

# Construct dynamic project URLs
if [[ -n "$PROJECT_ID" ]]; then
    PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/${PROJECT_ID}"
else
    PROJECT_URL="https://github.com/$REPO_OWNER/$REPO_NAME/projects"
fi

echo ""
echo "🔗 Quick Actions:"
echo "• Sprint Board: $PROJECT_URL/views/4"
echo "• Priority View: $PROJECT_URL/views/1"
echo "• Run Health Check: ../validation/check-view-health.sh"
