#!/bin/bash
# Comprehensive Roadmap Dashboard

echo "🚀 Azure InfraWeave Roadmap Dashboard"
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
echo "• Main Board: https://github.com/orgs/dasdigitalplatform/projects/3"
echo "• Sprint Board: https://github.com/orgs/dasdigitalplatform/projects/3/views/4"
echo "• Roadmap: https://github.com/orgs/dasdigitalplatform/projects/3/views/5"
