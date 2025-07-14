#!/bin/bash

# Add GitHub Issues to Project Board
# This script adds all created issues to the project board

echo "🎯 Adding GitHub Issues to Project Board"
echo "========================================"

PROJECT_ID="PVT_kwDOC-2N484A9m2C"
REPO_OWNER="dasdigitalplatform"
REPO_NAME="vanguard-az-infraweave-catalog"

# Function to add issue to project
add_issue_to_project() {
    local issue_num="$1"
    
    echo "Adding issue #$issue_num to project..."
    
    # Get the issue node ID
    local issue_node_id=$(gh api repos/$REPO_OWNER/$REPO_NAME/issues/$issue_num --jq '.node_id')
    
    if [[ -z "$issue_node_id" ]]; then
        echo "  ❌ Could not find issue #$issue_num"
        return 1
    fi
    
    # Add to project
    local item_id=$(gh api graphql -f query="
    mutation {
      addProjectV2ItemById(input: {
        projectId: \"$PROJECT_ID\"
        contentId: \"$issue_node_id\"
      }) {
        item {
          id
        }
      }
    }" --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null)
    
    if [[ -n "$item_id" ]] && [[ "$item_id" != "null" ]]; then
        echo "  ✅ Added issue #$issue_num to project"
    else
        echo "  ⚠️  Failed to add issue #$issue_num (may already be in project)"
    fi
}

# Add issues 5-21 to the project
echo "Adding all created issues to the project board..."
echo ""

for issue_num in {5..21}; do
    add_issue_to_project $issue_num
done

echo ""
echo "🎉 Finished adding issues to project board!"
echo ""
echo "Visit your project: https://github.com/orgs/dasdigitalplatform/projects/3"
echo ""
