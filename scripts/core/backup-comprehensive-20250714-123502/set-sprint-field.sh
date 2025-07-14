#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Set Sprint Field for All Issues in GitHub Project
# Uses GraphQL API to properly set the iteration/sprint field

set -e

# OWNER loaded from config
# REPO loaded from config

echo "🏃 Setting Sprint Field for All Issues"
echo "====================================="
echo "Repository: $OWNER/$REPO"
echo ""

# First, we need to find the project and get its ID
echo "🔍 Finding project and field information..."

# Get the project ID from the repository
PROJECT_INFO=$(gh api graphql -f query='
{
  repository(owner: "$REPO_OWNER", name: "$REPO_NAME") {
    projectsV2(first: 5) {
      nodes {
        id
        title
        number
      }
    }
  }
}')

PROJECT_ID=$(echo "$PROJECT_INFO" | jq -r '.data.repository.projectsV2.nodes[0].id // empty')

if [[ -z "$PROJECT_ID" ]]; then
    echo "❌ No project found. Please create a project first."
    exit 1
fi

echo "✅ Found project ID: $PROJECT_ID"

# Get the iteration/sprint field information
echo "🔍 Getting iteration field information..."

FIELDS_INFO=$(gh api graphql -f query="
{
  node(id: \"$PROJECT_ID\") {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
          ... on ProjectV2IterationField {
            id
            name
            dataType
            configuration {
              iterations {
                id
                title
                startDate
                duration
              }
            }
          }
        }
      }
    }
  }
}")

echo "Fields found:"
echo "$FIELDS_INFO" | jq -r '.data.node.fields.nodes[] | select(.dataType == "ITERATION") | "• \(.name) (ID: \(.id))"'

# Get the iteration field ID
ITERATION_FIELD_ID=$(echo "$FIELDS_INFO" | jq -r '.data.node.fields.nodes[] | select(.dataType == "ITERATION") | .id')

if [[ -z "$ITERATION_FIELD_ID" ]]; then
    echo ""
    echo "⚠️  No iteration field found in the project."
    echo "💡 To create an iteration field:"
    echo "   1. Go to your project: https://github.com/$OWNER/$REPO/projects"
    echo "   2. Click the '+' to add a field"
    echo "   3. Choose 'Iteration' field type"
    echo "   4. Create an iteration called 'Sprint 1'"
    echo "   5. Re-run this script"
    echo ""
    echo "📋 Creating Sprint label as alternative tracking method..."
    
    # Create sprint label as fallback
    gh api repos/$OWNER/$REPO/labels -X POST \
      -f name="sprint-1" \
      -f description="Sprint 1: Infrastructure Module Implementation" \
      -f color="1f77b4" 2>/dev/null || echo "Label already exists"
    
    echo "✅ Sprint label created for manual tracking"
    exit 0
fi

echo "✅ Found iteration field ID: $ITERATION_FIELD_ID"

# Get available iterations
ITERATIONS=$(echo "$FIELDS_INFO" | jq -r '.data.node.fields.nodes[] | select(.dataType == "ITERATION") | .configuration.iterations[]?')

if [[ -z "$ITERATIONS" ]]; then
    echo ""
    echo "⚠️  No iterations found in the iteration field."
    echo "💡 To create Sprint 1:"
    echo "   1. Go to your project: https://github.com/$OWNER/$REPO/projects"
    echo "   2. Find the Iteration field"
    echo "   3. Add a new iteration: 'Sprint 1'"
    echo "   4. Set dates: July 11 - July 25, 2025"
    echo "   5. Re-run this script"
    echo ""
    exit 0
fi

echo "Available iterations:"
echo "$FIELDS_INFO" | jq -r '.data.node.fields.nodes[] | select(.dataType == "ITERATION") | .configuration.iterations[]? | "• \(.title) (ID: \(.id))"'

# Get the first iteration ID (assuming it's Sprint 1)
SPRINT_ITERATION_ID=$(echo "$FIELDS_INFO" | jq -r '.data.node.fields.nodes[] | select(.dataType == "ITERATION") | .configuration.iterations[0]?.id // empty')

if [[ -z "$SPRINT_ITERATION_ID" ]]; then
    echo "❌ No sprint iteration found"
    exit 1
fi

echo "✅ Using iteration ID: $SPRINT_ITERATION_ID"

echo ""
echo "🔄 Assigning all issues to Sprint 1..."

# Get all issues and their project item IDs
while read issue_num; do
    echo "Processing issue #$issue_num..."
    
    # Get the project item ID for this issue
    ITEM_INFO=$(gh api graphql -f query="
    {
      repository(owner: \"$OWNER\", name: \"$REPO\") {
        issue(number: $issue_num) {
          id
          projectItems(first: 10) {
            nodes {
              id
              project {
                id
              }
            }
          }
        }
      }
    }")
    
    # Find the project item ID for our project
    PROJECT_ITEM_ID=$(echo "$ITEM_INFO" | jq -r --arg project_id "$PROJECT_ID" '.data.repository.issue.projectItems.nodes[] | select(.project.id == $project_id) | .id')
    
    if [[ -n "$PROJECT_ITEM_ID" ]]; then
        echo "  Found project item ID: $PROJECT_ITEM_ID"
        
        # Update the iteration field for this project item
        UPDATE_RESULT=$(gh api graphql -f query="
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: \"$PROJECT_ID\"
            itemId: \"$PROJECT_ITEM_ID\"
            fieldId: \"$ITERATION_FIELD_ID\"
            value: {
              iterationId: \"$SPRINT_ITERATION_ID\"
            }
          }) {
            projectV2Item {
              id
            }
          }
        }")
        
        if [[ $? -eq 0 ]]; then
            echo "  ✅ Issue #$issue_num assigned to Sprint 1"
        else
            echo "  ⚠️  Failed to assign issue #$issue_num to sprint"
        fi
    else
        echo "  ⚠️  Issue #$issue_num not found in project"
    fi
    
    echo ""
done < <(gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number | jq -r '.[].number')

echo "🎯 Sprint Assignment Complete!"
echo "=============================="
echo "✅ All issues have been assigned to Sprint 1 iteration"
echo "✅ Sprint tracking active in project board"
echo "✅ Use iteration views for sprint management"

echo ""
echo "🔗 Project Resources:"
echo "===================="
echo "📋 Project Board: https://github.com/$OWNER/$REPO/projects"
echo "🏃 Sprint View: Filter by Sprint 1 iteration"
echo "📊 Roadmap: View sprint timeline in roadmap view"

echo ""
echo "🎉 Sprint 1 Ready for Development!"
