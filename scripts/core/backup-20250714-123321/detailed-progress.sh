#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config

# Detailed Progress Reporter

echo "📈 Detailed Progress Report"
echo "=========================="
echo ""

echo "📊 Issue Status Distribution:"
echo "Note: Status tracking is via GitHub Projects v2 custom fields"
echo "All issues are currently in 'Todo' status by default"

echo ""

# Get priority breakdown using actual labels
echo "🎯 Label-Based Categories:"
for label in "foundation" "compute" "database" "containers" "networking" "security" "storage" "monitoring"; do
    count=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "$label" --limit 100 --json number | jq length)
    if [ "$count" -gt 0 ]; then
        echo "• $label: $count issues"
    fi
done

echo ""

# Get other categorizations
echo "📋 Issue Types:"
for label in "module" "enhancement" "documentation" "infrastructure" "project-management" "ci-cd"; do
    count=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --label "$label" --limit 100 --json number | jq length)
    if [ "$count" -gt 0 ]; then
        echo "• $label: $count issues"
    fi
done

echo ""
echo "🔗 View Links:"
echo "• Detailed Dashboard: https://github.com/orgs/$REPO_OWNER/projects/3/views/1"
echo "• Category View: https://github.com/orgs/$REPO_OWNER/projects/3/views/2"
echo "• Sprint Board: https://github.com/orgs/$REPO_OWNER/projects/3/views/4"
