#!/bin/bash
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
total_modules=$(gh issue list --repo dasdigitalplatform/vanguard-az-infraweave-catalog --state open --label "module" --limit 100 --json number | jq length)
total_docs=$(gh issue list --repo dasdigitalplatform/vanguard-az-infraweave-catalog --state open --label "documentation" --limit 100 --json number | jq length)
total_infra=$(gh issue list --repo dasdigitalplatform/vanguard-az-infraweave-catalog --state open --label "infrastructure" --limit 100 --json number | jq length)

echo "• Module implementation: $total_modules issues"
echo "• Documentation: $total_docs issues"  
echo "• Infrastructure: $total_infra issues"
echo ""

# Workflow health based on issue distribution
echo "🚦 Workflow Health Check:"
if [ "$total_modules" -gt 10 ]; then
    echo "📈 Active Development: $total_modules module issues ready for work"
else
    echo "✅ Focused Development: $total_modules module issues in backlog"
fi

echo "✅ Workflow Status: Ready for development"
echo "� Use the project board to move issues through workflow stages"

echo ""
echo "🔗 Quick Actions:"
echo "• Sprint Board: https://github.com/orgs/dasdigitalplatform/projects/3/views/4"
echo "• Priority View: https://github.com/orgs/dasdigitalplatform/projects/3/views/1"
echo "• Run Health Check: ./scripts/check-view-health.sh"
