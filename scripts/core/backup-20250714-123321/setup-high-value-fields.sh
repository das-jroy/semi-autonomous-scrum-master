#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Simplified High-Value Fields Implementation
# Sets intelligent defaults on existing fields and provides setup guidance

set -e

echo "🚀 HIGH-VALUE FIELDS SETUP FOR AZURE INFRAWEAVE PROJECT"
echo "======================================================="
echo ""

# Configuration
# REPO_OWNER loaded from config
# REPO_NAME loaded from config
PROJECT_NUMBER="3"

# Check GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Error: GitHub CLI not authenticated"
    echo "Please run 'gh auth login' first"
    exit 1
fi

echo "📋 Getting project information..."

# Get project details
PROJECT_DATA=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    projectV2(number: $number) {
      id
      title
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            dataType
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F number="$PROJECT_NUMBER")

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.id')
echo "✅ Found project: $(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.title')"
echo ""

# Check existing fields
echo "📊 Current project fields:"
echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | "• \(.name) (\(.dataType))"'
echo ""

# Get field IDs
STATUS_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Status") | .id')
TYPE_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Type") | .id')
MILESTONE_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Milestone") | .id')

echo "🔍 FIELD ANALYSIS:"
echo "=================="

if [ "$STATUS_FIELD_ID" != "null" ] && [ -n "$STATUS_FIELD_ID" ]; then
    echo "✅ Status field exists"
    STATUS_OPTIONS=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Status") | .options[]?.name // empty')
    if [ -n "$STATUS_OPTIONS" ]; then
        echo "   Options: $(echo "$STATUS_OPTIONS" | tr '\n' ', ' | sed 's/,$//')"
    fi
else
    echo "❌ Status field missing - needs manual creation"
fi

if [ "$TYPE_FIELD_ID" != "null" ] && [ -n "$TYPE_FIELD_ID" ]; then
    echo "✅ Type field exists"
    TYPE_OPTIONS=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Type") | .options[]?.name // empty')
    if [ -n "$TYPE_OPTIONS" ]; then
        echo "   Options: $(echo "$TYPE_OPTIONS" | tr '\n' ', ' | sed 's/,$//')"
    fi
else
    echo "❌ Type field missing - needs manual creation"
fi

if [ "$MILESTONE_FIELD_ID" != "null" ] && [ -n "$MILESTONE_FIELD_ID" ]; then
    echo "✅ Milestone field exists"
    MILESTONE_OPTIONS=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Milestone") | .options[]?.name // empty')
    if [ -n "$MILESTONE_OPTIONS" ]; then
        echo "   Options: $(echo "$MILESTONE_OPTIONS" | tr '\n' ', ' | sed 's/,$//')"
    fi
else
    echo "❌ Milestone field missing - needs manual creation"
fi

echo ""

# If missing fields, provide manual setup instructions
MISSING_FIELDS=""
if [ "$STATUS_FIELD_ID" = "null" ] || [ -z "$STATUS_FIELD_ID" ]; then
    MISSING_FIELDS="$MISSING_FIELDS Status"
fi
if [ "$TYPE_FIELD_ID" = "null" ] || [ -z "$TYPE_FIELD_ID" ]; then
    MISSING_FIELDS="$MISSING_FIELDS Type"
fi
if [ "$MILESTONE_FIELD_ID" = "null" ] || [ -z "$MILESTONE_FIELD_ID" ]; then
    MISSING_FIELDS="$MISSING_FIELDS Milestone"
fi

if [ -n "$MISSING_FIELDS" ]; then
    echo "🔧 MANUAL FIELD CREATION REQUIRED"
    echo "================================="
    echo ""
    echo "Missing fields:$MISSING_FIELDS"
    echo ""
    echo "Please manually create these fields in your GitHub project:"
    echo ""
    
    if [[ "$MISSING_FIELDS" == *"Status"* ]]; then
        echo "📋 STATUS FIELD:"
        echo "• Name: Status"
        echo "• Type: Single select"
        echo "• Options:"
        echo "  - Draft"
        echo "  - Ready (DOR)"
        echo "  - In Progress" 
        echo "  - Code Review"
        echo "  - Testing"
        echo "  - Done"
        echo ""
    fi
    
    if [[ "$MISSING_FIELDS" == *"Type"* ]]; then
        echo "🏷️  TYPE FIELD:"
        echo "• Name: Type"
        echo "• Type: Single select"
        echo "• Options:"
        echo "  - Feature"
        echo "  - Bug Fix"
        echo "  - Enhancement"
        echo "  - Documentation"
        echo "  - Infrastructure"
        echo "  - Epic"
        echo ""
    fi
    
    if [[ "$MISSING_FIELDS" == *"Milestone"* ]]; then
        echo "🎯 MILESTONE FIELD:"
        echo "• Name: Milestone"
        echo "• Type: Single select"
        echo "• Options:"
        echo "  - Foundation Phase"
        echo "  - Core Modules"
        echo "  - Advanced Services"
        echo "  - Production Ready"
        echo "  - v1.0 Release"
        echo "  - Future Enhancements"
        echo ""
    fi
    
    echo "To create fields manually:"
    echo "1. Go to your project board"
    echo "2. Click the '+ Field' button"
    echo "3. Choose 'Single select' for each field"
    echo "4. Add the options listed above"
    echo ""
    
    read -p "Have you created the missing fields? Continue with default value setting? [y/N]: " continue_setup
    
    if [[ ! $continue_setup =~ ^[Yy]$ ]]; then
        echo "Setup paused. Run this script again after creating the fields."
        exit 0
    fi
    
    # Refresh project data after manual field creation
    echo "🔄 Refreshing project data..."
    PROJECT_DATA=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        projectV2(number: $number) {
          id
          title
          fields(first: 20) {
            nodes {
              ... on ProjectV2Field {
                id
                name
                dataType
              }
              ... on ProjectV2SingleSelectField {
                id
                name
                dataType
                options {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F number="$PROJECT_NUMBER")
    
    # Update field IDs
    STATUS_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Status") | .id')
    TYPE_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Type") | .id')
    MILESTONE_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Milestone") | .id')
fi

echo "📊 SETTING INTELLIGENT DEFAULT VALUES"
echo "====================================="

# Get all issues in the project
echo "🔍 Finding all project issues..."

ITEMS_DATA=$(gh api graphql -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              id
              number
              title
              labels(first: 10) {
                nodes {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}' -f projectId="$PROJECT_ID")

ISSUE_COUNT=$(echo "$ITEMS_DATA" | jq -r '.data.node.items.nodes | length')
echo "📋 Found $ISSUE_COUNT issues to update"
echo ""

# Function to set field value for an item
set_field_value() {
    local item_id="$1"
    local field_id="$2" 
    local value_name="$3"
    local issue_number="$4"
    local field_name="$5"
    
    if [ "$field_id" = "null" ] || [ -z "$field_id" ]; then
        echo "   ⚠️  Issue #$issue_number: $field_name field not available"
        return
    fi
    
    # Get field options to find the option ID
    FIELD_DATA=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID")
    
    OPTION_ID=$(echo "$FIELD_DATA" | jq -r --arg fieldId "$field_id" --arg name "$value_name" '.data.node.fields.nodes[] | select(.id == $fieldId) | .options[]? | select(.name == $name) | .id')
    
    if [ "$OPTION_ID" != "null" ] && [ -n "$OPTION_ID" ]; then
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {
              singleSelectOptionId: $value
            }
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$field_id" -f value="$OPTION_ID" >/dev/null
        
        echo "   ✅ Issue #$issue_number: $field_name = '$value_name'"
    else
        echo "   ❌ Issue #$issue_number: Could not find $field_name option '$value_name'"
    fi
}

# Process each issue
echo "🎯 Setting intelligent default values..."
echo ""

echo "$ITEMS_DATA" | jq -r '.data.node.items.nodes[] | "\(.id)|\(.content.number)|\(.content.title)|\(.content.labels.nodes[].name // "")"' | while IFS='|' read -r item_id issue_number title labels; do
    echo "📝 Processing Issue #$issue_number: $title"
    
    # Determine Status based on title/labels
    if [[ "$title" == *"TODO"* ]] || [[ "$title" == *"Draft"* ]]; then
        status_value="Draft"
    else
        status_value="Ready (DOR)"
    fi
    
    # Determine Type based on title/labels
    if [[ "$title" == *"Bug"* ]] || [[ "$title" == *"Fix"* ]] || [[ "$labels" == *"bug"* ]]; then
        type_value="Bug Fix"
    elif [[ "$title" == *"Enhance"* ]] || [[ "$title" == *"Improve"* ]]; then
        type_value="Enhancement"
    elif [[ "$title" == *"Doc"* ]] || [[ "$labels" == *"documentation"* ]]; then
        type_value="Documentation"
    elif [[ "$title" == *"Infrastructure"* ]] || [[ "$title" == *"Setup"* ]]; then
        type_value="Infrastructure"
    else
        type_value="Feature"
    fi
    
    # Determine Milestone based on module/content
    if [[ "$title" == *"Foundation"* ]] || [[ "$title" == *"Core"* ]] || [[ "$title" == *"Basic"* ]]; then
        milestone_value="Foundation Phase"
    elif [[ "$title" == *"Advanced"* ]] || [[ "$title" == *"Complex"* ]]; then
        milestone_value="Advanced Services"
    elif [[ "$title" == *"Production"* ]] || [[ "$title" == *"Deploy"* ]]; then
        milestone_value="Production Ready"
    else
        milestone_value="Core Modules"
    fi
    
    # Set the field values
    set_field_value "$item_id" "$STATUS_FIELD_ID" "$status_value" "$issue_number" "Status"
    set_field_value "$item_id" "$TYPE_FIELD_ID" "$type_value" "$issue_number" "Type"
    set_field_value "$item_id" "$MILESTONE_FIELD_ID" "$milestone_value" "$issue_number" "Milestone"
    
    echo ""
done

echo "✅ HIGH-VALUE FIELDS SETUP COMPLETE!"
echo "===================================="
echo ""

echo "📊 Summary:"
echo "• Status field: Tracks DOR compliance and workflow state"
echo "• Type field: Categorizes work for better reporting"
echo "• Milestone field: Aligns work with release planning"
echo "• Default values set on all $ISSUE_COUNT issues"
echo ""

echo "🎯 NEXT STEPS:"
echo "============="
echo "1. Review the assigned values in your project board"
echo "2. Adjust Status/Type/Milestone values as needed"
echo "3. Consider adding 'Ready (DOR)' kanban column manually"
echo "4. Create new project views for enhanced tracking"
echo ""

echo "📈 DOR (Definition of Ready) INTEGRATION:"
echo "========================================"
echo ""
echo "Before moving an issue to 'Ready (DOR)' status, ensure:"
echo "□ Requirements clearly defined"
echo "□ Acceptance criteria specified"
echo "□ Dependencies identified"
echo "□ Technical approach outlined"
echo "□ Test scenarios defined"
echo "□ Security requirements reviewed"
echo ""

echo "💡 RECOMMENDED PROJECT VIEWS:"
echo "============================"
echo "1. DOR Compliance View - Filter by Status field"
echo "2. Type Breakdown View - Group by Type field"
echo "3. Milestone Progress View - Group by Milestone field"
echo "4. Sprint Board with DOR - Kanban grouped by Status"
echo ""

echo "🎉 Your $PROJECT_NAME project now has enhanced tracking capabilities!"
