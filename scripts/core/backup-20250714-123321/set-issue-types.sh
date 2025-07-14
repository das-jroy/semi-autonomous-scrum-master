#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Set Native GitHub Issue Types Script
# Configures native GitHub issue types for all project issues

set -e

# PROJECT_ID loaded from config
# OWNER loaded from config
# REPO loaded from config

echo "🏷️ Setting Native GitHub Issue Types"
echo "====================================="

# First, let's check if the project has a native Type field
echo "🔍 Checking for native Type field in project..."

TYPE_FIELD_DATA=$(gh api graphql -f query='
query($owner: String!, $number: Int!) {
  organization(login: $owner) {
    projectV2(number: $number) {
      fields(first: 30) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              name
              id
            }
          }
          ... on ProjectV2Field {
            id
            name
            dataType
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -F number="$PROJECT_ID")

# Check if Issue Type field exists
TYPE_FIELD_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Issue Type") | .id // empty')

if [[ -z "$TYPE_FIELD_ID" ]]; then
    echo "⚠️  No native Issue Type field found in project board."
    echo "📝 Creating Issue Type field with GitHub issue type options..."
    
    # Create Issue Type field with valid color options
    TYPE_FIELD_RESULT=$(gh api graphql -f query='
    mutation($projectId: ID!) {
      createProjectV2Field(input: {
        projectId: $projectId
        dataType: SINGLE_SELECT
        name: "Issue Type"
        singleSelectOptions: [
          {name: "Feature", description: "New module implementations", color: GREEN},
          {name: "Bug", description: "Issues and fixes", color: RED}, 
          {name: "Enhancement", description: "Improvements to existing functionality", color: BLUE},
          {name: "Documentation", description: "README, guides, examples", color: PURPLE}
        ]
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
            options {
              id
              name
            }
          }
        }
      }
    }' -f projectId="PVT_kwDOC-2N484A9m2C")
    
    TYPE_FIELD_ID=$(echo "$TYPE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.id')
    echo "✅ Created Issue Type field with ID: $TYPE_FIELD_ID"
    
    # Get the option IDs
    FEATURE_ID=$(echo "$TYPE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Feature") | .id')
    BUG_ID=$(echo "$TYPE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Bug") | .id')
    ENHANCEMENT_ID=$(echo "$TYPE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Enhancement") | .id')
    DOCUMENTATION_ID=$(echo "$TYPE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Documentation") | .id')
else
    echo "✅ Found existing Issue Type field: $TYPE_FIELD_ID"
    
    # Get existing option IDs
    FEATURE_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Issue Type") | .options[] | select(.name == "Feature") | .id')
    BUG_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Issue Type") | .options[] | select(.name == "Bug") | .id')
    ENHANCEMENT_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Issue Type") | .options[] | select(.name == "Enhancement") | .id')
    DOCUMENTATION_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Issue Type") | .options[] | select(.name == "Documentation") | .id')
fi

echo ""
echo "🎯 Issue Type Field Configuration:"
echo "Feature ID: $FEATURE_ID"
echo "Bug ID: $BUG_ID" 
echo "Enhancement ID: $ENHANCEMENT_ID"
echo "Documentation ID: $DOCUMENTATION_ID"

echo ""
echo "📋 Setting issue types based on content analysis..."

# Get all project items
ITEMS=$(gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json)

# Function to set project item type
set_project_item_type() {
    local item_id="$1"
    local type_option_id="$2"
    local type_name="$3"
    local title="$4"
    
    echo "  Setting '$title' to type: $type_name"
    
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
    }' -f projectId="PVT_kwDOC-2N484A9m2C" -f itemId="$item_id" -f fieldId="$TYPE_FIELD_ID" -f value="$type_option_id" > /dev/null
    
    echo "    ✅ Updated"
}

# Process each item and categorize by title
echo "$ITEMS" | jq -c '.items[]' | while read -r item; do
    ITEM_ID=$(echo "$item" | jq -r '.id')
    TITLE=$(echo "$item" | jq -r '.title')
    
    echo ""
    echo "Processing: $TITLE"
    
    # Categorize based on title content
    if [[ "$TITLE" == *"Configure GitHub"* || "$TITLE" == *"Update CI/CD"* ]]; then
        set_project_item_type "$ITEM_ID" "$ENHANCEMENT_ID" "Enhancement" "$TITLE"
    elif [[ "$TITLE" == *"documentation"* || "$TITLE" == *"README"* || "$TITLE" == *"guide"* ]]; then
        set_project_item_type "$ITEM_ID" "$DOCUMENTATION_ID" "Documentation" "$TITLE"
    elif [[ "$TITLE" == *"fix"* || "$TITLE" == *"bug"* || "$TITLE" == *"error"* ]]; then
        set_project_item_type "$ITEM_ID" "$BUG_ID" "Bug" "$TITLE"
    else
        # Default to Feature for module implementations
        set_project_item_type "$ITEM_ID" "$FEATURE_ID" "Feature" "$TITLE"
    fi
done

echo ""
echo "🎉 Issue Type Assignment Complete!"
echo "================================="

# Show updated distribution
echo ""
echo "📊 Updated Issue Type Distribution:"
echo "=================================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | .["issue Type"] // "Not Set"' | sort | uniq -c | sort -nr

echo ""
echo "✅ All issues now have GitHub native issue types set!"
echo ""
echo "💡 Issue Type Usage:"
echo "• Feature: New module implementations"
echo "• Enhancement: Improvements to existing functionality"
echo "• Bug: Issues and fixes"
echo "• Documentation: README, guides, examples"

echo ""
echo "🔗 You can now filter and organize by issue type in your project board views!"
