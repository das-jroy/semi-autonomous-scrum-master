#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Validate required configuration
if [[ -z "$PROJECT_ID" ]]; then
    echo "❌ PROJECT_ID is not set. Please check your configuration."
    echo "Set project.project_id in configs/project-config.json"
    exit 1
fi

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
    echo "❌ Repository configuration missing."
    echo "Set project.owner and project.repository in configs/project-config.json"
    exit 1
fi

# Add GitHub Issues to Project Board
# This script adds all created issues to the project board

echo "🎯 Adding GitHub Issues to Project Board"
echo "========================================"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Project ID: $PROJECT_ID"
echo ""

# Function to get all open issues from the repository
get_all_issues() {
    echo "🔍 Discovering open issues in repository..."
    
    # Get all open issues (limit to first 100)
    gh api repos/$REPO_OWNER/$REPO_NAME/issues \
        --paginate \
        --jq '.[] | select(.state == "open") | .number' \
        | head -100
}

# Function to check if issue is already in project
is_issue_in_project() {
    local issue_node_id="$1"
    
    # Check if issue is already in the project
    local existing_item=$(gh api graphql -f query="
    query {
      node(id: \"$PROJECT_ID\") {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              content {
                ... on Issue {
                  id
                }
              }
            }
          }
        }
      }
    }" --jq ".data.node.items.nodes[] | select(.content.id == \"$issue_node_id\") | .content.id" 2>/dev/null)
    
    [[ -n "$existing_item" ]]
}
# Function to add issue to project
add_issue_to_project() {
    local issue_num="$1"
    
    echo "  Processing issue #$issue_num..."
    
    # Get the issue node ID
    local issue_node_id=$(gh api repos/$REPO_OWNER/$REPO_NAME/issues/$issue_num --jq '.node_id' 2>/dev/null)
    
    if [[ -z "$issue_node_id" ]] || [[ "$issue_node_id" == "null" ]]; then
        echo "    ❌ Could not find issue #$issue_num"
        return 1
    fi
    
    # Check if already in project
    if is_issue_in_project "$issue_node_id"; then
        echo "    ⏭️  Issue #$issue_num already in project"
        return 0
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
        echo "    ✅ Added issue #$issue_num to project"
        return 0
    else
        echo "    ❌ Failed to add issue #$issue_num"
        return 1
    fi
}

# Parse command line arguments
SPECIFIC_ISSUES=()
AUTO_DISCOVER=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --issues)
            IFS=',' read -ra SPECIFIC_ISSUES <<< "$2"
            AUTO_DISCOVER=false
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--issues ISSUE_NUMBERS]"
            echo ""
            echo "Options:"
            echo "  --issues N1,N2,N3    Add specific issue numbers to project"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Add all open issues"
            echo "  $0 --issues 1,2,3          # Add specific issues"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get issues to process
if [[ "$AUTO_DISCOVER" == "true" ]]; then
    echo "📋 Auto-discovering all open issues..."
    mapfile -t ISSUES_TO_ADD < <(get_all_issues)
    
    if [[ ${#ISSUES_TO_ADD[@]} -eq 0 ]]; then
        echo "❌ No open issues found in repository"
        echo "💡 Create some issues first or use --issues to specify issue numbers"
        exit 1
    fi
    
    echo "Found ${#ISSUES_TO_ADD[@]} open issues to process"
else
    ISSUES_TO_ADD=("${SPECIFIC_ISSUES[@]}")
    echo "📋 Processing ${#ISSUES_TO_ADD[@]} specified issues: ${ISSUES_TO_ADD[*]}"
fi

echo ""

# Process all issues
added_count=0
skipped_count=0
failed_count=0

for issue_num in "${ISSUES_TO_ADD[@]}"; do
    if add_issue_to_project "$issue_num"; then
        if [[ $? -eq 0 ]]; then
            ((added_count++))
        fi
    else
        ((failed_count++))
    fi
done

echo ""
echo "📊 Summary:"
echo "  ✅ Added: $added_count issues"
echo "  ⏭️  Skipped: $skipped_count issues (already in project)"
echo "  ❌ Failed: $failed_count issues"
echo ""

if [[ $added_count -gt 0 ]]; then
    echo "🎉 Successfully added $added_count issues to project!"
else
    echo "ℹ️  No new issues were added to the project"
fi

if [[ $failed_count -gt 0 ]]; then
    echo "⚠️  Some issues failed to be added. Check the output above for details."
    exit 1
fi

echo ""
if [[ -z "$REPO_OWNER" ]]; then
  echo "❌ REPO_OWNER is not set. Please check your configuration."
elif [[ -z "$PROJECT_ID" ]]; then
  echo "❌ PROJECT_ID is not set. Please check your configuration."
else
  # Get the project number and owner from the GraphQL node ID for URL construction  
  local project_info=$(gh api graphql -f query="
  query {
    node(id: \"$PROJECT_ID\") {
      ... on ProjectV2 {
        number
        owner {
          __typename
          login
        }
      }
    }
  }" --jq '.data.node | {project_number: .number, owner_type: .owner.__typename, owner_login: .owner.login}' 2>/dev/null)
  
  if [[ -n "$project_info" && "$project_info" != "null" ]]; then
    local project_number=$(echo "$project_info" | jq -r '.project_number // empty')
    local owner_type=$(echo "$project_info" | jq -r '.owner_type // empty')  
    local owner_login=$(echo "$project_info" | jq -r '.owner_login // empty')
    
    if [[ -n "$project_number" && -n "$owner_type" && -n "$owner_login" ]]; then
      if [[ "$owner_type" == "Organization" ]]; then
        echo "🔗 Visit your project: https://github.com/orgs/$owner_login/projects/$project_number"
      elif [[ "$owner_type" == "User" ]]; then
        echo "🔗 Visit your project: https://github.com/users/$owner_login/projects/$project_number"
      else
        echo "💡 Project ID: $PROJECT_ID - visit GitHub Projects to access"
      fi
    else
      echo "💡 Project ID: $PROJECT_ID - visit GitHub Projects to access"
    fi
  else
    echo "💡 Project ID: $PROJECT_ID - visit GitHub Projects to access"
  fi
fi

echo "✅ Operation completed successfully!"
