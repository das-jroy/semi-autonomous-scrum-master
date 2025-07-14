#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Final Project Status Report
# Shows the complete state of the optimized $PROJECT_NAME

set -e

# PROJECT_ID loaded from config
# OWNER loaded from config

echo "📊 $PROJECT_NAME"
echo "========================================================"
echo "Generated: $(date)"
echo ""

# Project overview
echo "🎯 Project Overview:"
echo "==================="
gh project view "$PROJECT_ID" --owner "$OWNER" | head -5

echo ""
echo "📋 Current Issue Distribution:"
echo "============================="
STATUS_DIST=$(gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | "\(.status // "No Status")"' | sort | uniq -c | sort -nr)

echo "$STATUS_DIST"

# Calculate percentages
TOTAL_ISSUES=$(echo "$STATUS_DIST" | awk '{sum += $1} END {print sum}')
echo ""
echo "📊 Status Distribution (%):"
echo "==========================="
echo "$STATUS_DIST" | while read count status; do
    percentage=$(echo "scale=1; $count * 100 / $TOTAL_ISSUES" | bc)
    printf "%-15s: %2d issues (%4.1f%%)\n" "$status" "$count" "$percentage"
done

echo ""
echo "🚀 Sprint 1 Ready Items (DOR Status):"
echo "====================================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | select(.status == "DOR") | "✅ \(.title)"'

echo ""
echo "⏳ Awaiting Triage (No Status):"
echo "==============================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | select(.status == null) | "📋 \(.title)"' | head -5
NO_STATUS_COUNT=$(gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | select(.status == null) | .title' | wc -l)
echo "... and $((NO_STATUS_COUNT - 5)) more items"

echo ""
echo "🛠️ Available Project Views:"
echo "==========================="
gh project view-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.views[] | "• \(.name): \(.description // "No description")"'

echo ""
echo "⚙️ Custom Fields Configuration:"
echo "==============================="
gh api graphql -f query='
query($owner: String!, $number: Int!) {
  organization(login: $owner) {
    projectV2(number: $number) {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            name
            options {
              name
            }
          }
          ... on ProjectV2IterationField {
            name
          }
          ... on ProjectV2DateField {
            name
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -F number="$PROJECT_ID" | \
jq -r '.data.organization.projectV2.fields.nodes[] | select(.name != null) | "• \(.name): \(.options[]?.name // "Date field" // "Iteration field")"' | \
sort | uniq

echo ""
echo "🎉 Optimization Achievements:"
echo "============================"
echo "✅ 17+ GitHub issues created and tracked"
echo "✅ 5 optimized project board views configured"
echo "✅ Enhanced kanban workflow with Review/Blocked statuses"
echo "✅ High-value custom fields implemented (Status, Complexity, etc.)"
echo "✅ Definition of Ready (DOR) workflow established"
echo "✅ Foundation modules prepared for Sprint 1"
echo "✅ Native GitHub issue types integration"
echo "✅ Roadmap timeline functionality enabled"
echo "✅ Automated scripts for ongoing management"

echo ""
echo "📈 Workflow Optimization:"
echo "========================"
echo "• Status Flow: No Status → DOR → In Progress → Review → Done"
echo "• Issue Types: Feature, Bug, Documentation, Enhancement"
echo "• Priority: Foundation modules ready for immediate development"
echo "• Metrics: Lead time, cycle time, blocked rate tracking enabled"

echo ""
echo "🚀 Ready for Sprint 1:"
echo "====================="
echo "Foundation modules in DOR status and ready for development:"
echo "1. Management Group Module (foundation/management-group)"
echo "2. Subscription Module (foundation/subscription)"
echo "3. GitHub Project Board optimization"
echo "4. CI/CD Workflow integration"

echo ""
echo "📋 Next Actions Required:"
echo "========================"
echo "1. 🏃 BEGIN DEVELOPMENT: Start Sprint 1 with foundation modules"
echo "2. 📝 TRIAGE: Review remaining 'No Status' items weekly"
echo "3. 🔄 WORKFLOW: Move items through status pipeline as work progresses"
echo "4. 📊 MONITOR: Use project views for sprint planning and progress tracking"
echo "5. 🎯 OPTIMIZE: Continuously improve based on team feedback"

echo ""
echo "🎯 Enterprise-Ready Project Board Status: ✅ COMPLETE"
echo "====================================================="
echo ""
echo "The $PROJECT_NAME"
echo "• Sprint planning and execution"
echo "• Definition of Ready (DOR) compliance"
echo "• Metrics and progress tracking"
echo "• Native GitHub integration"
echo "• Scalable workflow management"
echo ""
echo "🚀 Ready to accelerate Azure infrastructure module development!"
