#!/bin/bash

# Set Sprint Field for All Issues - Proper Implementation
# Uses the actual Sprint field in the GitHub project

set -e

OWNER="dasdigitalplatform"
REPO="vanguard-az-infraweave-catalog"

echo "🏃 Setting Sprint Field for All Issues"
echo "====================================="
echo "Repository: $OWNER/$REPO"
echo ""

# Project and field IDs (from investigation)
PROJECT_ID="PVT_kwDOC-2N484A9m2C"
SPRINT_FIELD_ID="PVTSSF_lADOC-2N484A9m2CzgxTlLE"
SPRINT_1_OPTION_ID="5b619217"

echo "✅ Project ID: $PROJECT_ID"
echo "✅ Sprint Field ID: $SPRINT_FIELD_ID"
echo "✅ Sprint 1 Option ID: $SPRINT_1_OPTION_ID"
echo ""

echo "🔄 Assigning all issues to Sprint 1..."

# Get all issues and set their sprint field
issue_count=0
success_count=0
failed_count=0

while read issue_num; do
    echo "Processing issue #$issue_num..."
    issue_count=$((issue_count + 1))
    
    # Get the project item ID for this issue
    ITEM_INFO=$(gh api graphql -f query="
    {
      repository(owner: \"$OWNER\", name: \"$REPO\") {
        issue(number: $issue_num) {
          id
          title
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
    
    ISSUE_TITLE=$(echo "$ITEM_INFO" | jq -r '.data.repository.issue.title')
    PROJECT_ITEM_ID=$(echo "$ITEM_INFO" | jq -r --arg project_id "$PROJECT_ID" '.data.repository.issue.projectItems.nodes[] | select(.project.id == $project_id) | .id')
    
    if [[ -n "$PROJECT_ITEM_ID" ]]; then
        echo "  📋 Issue: $ISSUE_TITLE"
        echo "  🔗 Project Item ID: $PROJECT_ITEM_ID"
        
        # Update the Sprint field for this project item
        UPDATE_RESULT=$(gh api graphql -f query="
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: \"$PROJECT_ID\"
            itemId: \"$PROJECT_ITEM_ID\"
            fieldId: \"$SPRINT_FIELD_ID\"
            value: {
              singleSelectOptionId: \"$SPRINT_1_OPTION_ID\"
            }
          }) {
            projectV2Item {
              id
            }
          }
        }" 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            echo "  ✅ Successfully assigned to Sprint 1"
            success_count=$((success_count + 1))
        else
            echo "  ❌ Failed to assign to Sprint 1"
            failed_count=$((failed_count + 1))
        fi
    else
        echo "  ⚠️  Issue not found in project"
        failed_count=$((failed_count + 1))
    fi
    
    echo ""
done < <(gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number | jq -r '.[].number')

echo "🎯 Sprint Assignment Results:"
echo "============================"
echo "📊 Total Issues: $issue_count"
echo "✅ Successfully Assigned: $success_count"
echo "❌ Failed: $failed_count"

if [[ $success_count -eq $issue_count ]]; then
    echo ""
    echo "🎉 All issues successfully assigned to Sprint 1!"
    echo "✅ Sprint field properly set in project board"
    echo "✅ Issues will now appear in Sprint 1 views"
else
    echo ""
    echo "⚠️  Some issues may need manual assignment"
    echo "💡 Check project board for any missing assignments"
fi

echo ""
echo "🔗 Project Resources:"
echo "===================="
echo "📋 Project Board: https://github.com/$OWNER/$REPO/projects"
echo "🏃 Sprint Filter: Filter by 'Sprint 1 (Jul 2025)' in project views"
echo "📊 Sprint View: Create view filtered by Sprint field = Sprint 1"

echo ""
echo "🎯 Sprint 1 Details:"
echo "==================="
echo "📅 Duration: Sprint 1 (Jul 2025)"
echo "🎯 Goal: Infrastructure Module Implementation"
echo "📋 Scope: $issue_count issues assigned"
echo "🚀 Status: Ready for development"

echo ""
echo "✅ Sprint field assignment complete!"
