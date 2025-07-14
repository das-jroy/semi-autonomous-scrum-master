#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Sprint 1 Preparation Script
# Prepares foundation modules and high-priority items for Sprint 1

set -e

# PROJECT_ID loaded from config
# OWNER loaded from config
PROJECT_GQL_ID="PVT_kwDOC-2N484A9m2C"

echo "🚀 Sprint 1 Preparation for $PROJECT_NAME"
echo "============================================"

# Get field IDs
echo "🔍 Getting project field configuration..."
FIELD_DATA=$(gh api graphql -f query='
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
}' -f owner="$OWNER" -F number="$PROJECT_ID")

STATUS_FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Status") | .id')
DOR_OPTION_ID=$(echo "$FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "DOR") | .id')

echo "✅ Field IDs retrieved"
echo "   Status Field ID: $STATUS_FIELD_ID"
echo "   DOR Option ID: $DOR_OPTION_ID"

# Define Sprint 1 foundation modules (high priority)
FOUNDATION_MODULES=(
    "Implement Management Group Module (foundation/management-group)"
    "Implement Subscription Module (foundation/subscription)"
    "Configure GitHub Project Board for Module Implementation Tracking"
    "Update CI/CD Workflow for InfraWeave CLI Integration"
)

echo ""
echo "🎯 Sprint 1 Foundation Modules:"
echo "=============================="
for module in "${FOUNDATION_MODULES[@]}"; do
    echo "• $module"
done

echo ""
echo "📋 Moving foundation modules to DOR status..."
echo "============================================="

# Get all project items
ITEMS=$(gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json)

# Process each foundation module
for foundation_module in "${FOUNDATION_MODULES[@]}"; do
    echo ""
    echo "Processing: $foundation_module"
    
    # Find the item ID for this module
    ITEM_ID=$(echo "$ITEMS" | jq -r --arg title "$foundation_module" '.items[] | select(.title == $title) | .id')
    
    if [[ -n "$ITEM_ID" && "$ITEM_ID" != "null" ]]; then
        echo "  Found item ID: $ITEM_ID"
        
        # Move to DOR status
        echo "  Moving to DOR status..."
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
        }' -f projectId="$PROJECT_GQL_ID" -f itemId="$ITEM_ID" -f fieldId="$STATUS_FIELD_ID" -f value="$DOR_OPTION_ID"
        
        echo "  ✅ Moved to DOR status"
    else
        echo "  ⚠️  Item not found: $foundation_module"
    fi
done

echo ""
echo "🏷️  Setting GitHub Issue Types..."
echo "================================"

# Function to set issue type via GitHub CLI
set_issue_type() {
    local issue_title="$1"
    local issue_type="$2"
    
    # Find the issue number
    ISSUE_NUMBER=$(gh issue list --repo "$OWNER/$(basename $(pwd))" --search "\"$issue_title\"" --json number,title | jq -r --arg title "$issue_title" '.[] | select(.title == $title) | .number')
    
    if [[ -n "$ISSUE_NUMBER" && "$ISSUE_NUMBER" != "null" ]]; then
        echo "  Setting issue #$ISSUE_NUMBER to type: $issue_type"
        # Note: GitHub issue types are typically set via labels or during creation
        gh issue edit "$ISSUE_NUMBER" --add-label "type:$issue_type" --repo "$OWNER/$(basename $(pwd))" 2>/dev/null || echo "    (Label may already exist or repo not accessible)"
    fi
}

# Set types for foundation modules
for foundation_module in "${FOUNDATION_MODULES[@]}"; do
    if [[ "$foundation_module" == *"GitHub Project Board"* ]]; then
        set_issue_type "$foundation_module" "enhancement"
    elif [[ "$foundation_module" == *"CI/CD Workflow"* ]]; then
        set_issue_type "$foundation_module" "enhancement"
    else
        set_issue_type "$foundation_module" "feature"
    fi
done

echo ""
echo "📊 Updated Status Distribution:"
echo "=============================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | "\(.title): \(.status // "No Status")"' | \
sort | uniq -c | sort -nr

echo ""
echo "🎉 Sprint 1 Preparation Complete!"
echo "================================="
echo ""
echo "✅ Foundation modules moved to DOR status"
echo "✅ Issue types configured with labels"
echo "✅ Project board ready for sprint planning"
echo ""
echo "🚀 Ready to begin Sprint 1 with:"
echo "  • Management Group Module"
echo "  • Subscription Module" 
echo "  • GitHub Project Board optimization"
echo "  • CI/CD Workflow integration"
echo ""
echo "💡 Next Steps:"
echo "  1. Begin development on foundation modules"
echo "  2. Move items to 'In Progress' as work starts"
echo "  3. Use 'Review' status for code review phase"
echo "  4. Monitor progress via project board views"
