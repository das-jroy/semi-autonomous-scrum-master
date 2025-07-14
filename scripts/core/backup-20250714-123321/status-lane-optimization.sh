#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Status Lane Optimization Script
# Optimizes the use of Todo, Backlog, and No Status lanes based on GitHub best practices

set -e

# PROJECT_ID loaded from config
# OWNER loaded from config

echo "🎯 Status Lane Optimization for $PROJECT_NAME Project"
echo "======================================================="

# Function to get project field IDs
get_field_ids() {
    gh api graphql -f query='
    query($owner: String!, $number: Int!) {
      organization(login: $owner) {
        projectV2(number: $number) {
          id
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  name
                  id
                }
              }
            }
          }
        }
      }
    }' -f owner="$OWNER" -F number="$PROJECT_ID"
}

# Get current status distribution
echo "📊 Current Status Distribution:"
echo "------------------------------"
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | "\(.title): \(.status // "No Status")"' | \
sort | uniq -c | sort -nr

echo ""
echo "💡 Status Lane Optimization Recommendations:"
echo "============================================"

echo "1. INTAKE LANE OPTIONS:"
echo "   a) Keep 'Todo' as intake → ideal for quick capture"
echo "   b) Use 'No Status' as intake → GitHub native approach"
echo "   c) Rename 'Todo' to 'Backlog' → clearer intention"

echo ""
echo "2. RECOMMENDED WORKFLOW:"
echo "   No Status/Todo → DOR → In Progress → Review → Done"
echo "   ↓"
echo "   Blocked (can come from any status)"

echo ""
echo "3. FIELD USAGE GUIDANCE:"
echo "   • No Status: New issues, not yet triaged"
echo "   • Todo/Backlog: Triaged but not DOR-complete"
echo "   • DOR: Definition of Ready complete, sprint-ready"
echo "   • In Progress: Active development"
echo "   • Review: Code review, testing, validation"
echo "   • Blocked: Waiting on dependencies"
echo "   • Done: Completed and merged"

# Check issues that need DOR review
echo ""
echo "🔍 Issues Currently Needing Status Review:"
echo "=========================================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | select(.status == null or .status == "Todo") | "• \(.title)"' | head -10

echo ""
echo "⚡ Quick Actions Available:"
echo "========================="
echo "1. Move DOR-ready issues from Todo to DOR status"
echo "2. Set new issues to 'No Status' for triage"
echo "3. Rename Todo column to Backlog (if preferred)"

# Show action scripts
echo ""
echo "🛠️  Action Scripts:"
echo "=================="

cat << 'EOF'
# Move specific issue to DOR status:
gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $value }
  }) {
    projectV2Item {
      id
    }
  }
}' -f projectId="PVT_kwDOC-2N484A9m2C" -f itemId="ITEM_ID" -f fieldId="STATUS_FIELD_ID" -f value="0506ffe1"

# Bulk move Todo items to DOR (run after reviewing each):
for item in $(gh project item-list 3 --owner $REPO_OWNER --format json | jq -r '.items[] | select(.status == "Todo") | .id'); do
  echo "Moving item $item to DOR status..."
  # Add API call here
done
EOF

echo ""
echo "✅ Next Steps:"
echo "============="
echo "1. Review issues in Todo status"
echo "2. Move DOR-complete issues to DOR status"
echo "3. Consider renaming Todo to Backlog for clarity"
echo "4. Use native GitHub issue types for categorization"
echo "5. Begin Sprint 1 with foundation modules"

echo ""
echo "📋 Native GitHub Issue Types Integration:"
echo "========================================"
echo "• Feature: New module implementations"
echo "• Bug: Issues with existing modules"
echo "• Documentation: README, guides, examples"
echo "• Enhancement: Improvements to existing modules"

echo ""
echo "Status lane optimization analysis complete! 🎉"
