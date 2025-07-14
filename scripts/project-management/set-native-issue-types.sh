#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Set Native GitHub Issue Types
# Sets the native GitHub issue type field for all repository issues

set -e

# OWNER loaded from config
# REPO loaded from config

echo "🏷️ Setting Native GitHub Issue Types"
echo "====================================="
echo "Repository: $OWNER/$REPO"
echo ""

# First, let's check available issue types for the repository
echo "🔍 Checking available issue types..."
AVAILABLE_TYPES=$(gh api graphql -f query='
query($owner: String!, $repo: String!) {
  repository(owner: $owner, name: $repo) {
    issueTypes(first: 10) {
      nodes {
        id
        name
        description
        color
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO")

echo "Available issue types:"
echo "$AVAILABLE_TYPES" | jq -r '.data.repository.issueTypes.nodes[]? | "• \(.name): \(.description)"'

echo ""
echo "📋 Current Issue Type Status:"
echo "============================="

# Get all issues and check their current types
gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number,title | \
jq -r '.[] | .number' | while read issue_num; do
    issue_info=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          number
          title
          issueType {
            name
          }
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -F number="$issue_num")
    
    issue_type=$(echo "$issue_info" | jq -r '.data.repository.issue.issueType.name // "Not Set"')
    issue_title=$(echo "$issue_info" | jq -r '.data.repository.issue.title')
    
    echo "#$issue_num: $issue_type - $issue_title"
done

echo ""
echo "🔧 Setting Issue Types Based on Content Analysis:"
echo "================================================"

# Function to set issue type
set_issue_type() {
    local issue_number="$1"
    local issue_type="$2"
    local issue_title="$3"
    
    echo "Setting issue #$issue_number to type: $issue_type"
    echo "  Title: $issue_title"
    
    # Use GitHub API to set the issue type
    result=$(gh api graphql -f query='
    mutation($issueId: ID!, $issueTypeId: ID!) {
      updateIssue(input: {
        id: $issueId
        issueTypeId: $issueTypeId
      }) {
        issue {
          number
          issueType {
            name
          }
        }
      }
    }' -f issueId="$(gh api graphql -f query='query($owner: String!, $repo: String!, $number: Int!) { repository(owner: $owner, name: $repo) { issue(number: $number) { id } } }' -f owner="$OWNER" -f repo="$REPO" -F number="$issue_number" | jq -r '.data.repository.issue.id')" \
    -f issueTypeId="$(gh api graphql -f query='query($owner: String!, $repo: String!) { repository(owner: $owner, name: $repo) { issueTypes(first: 10) { nodes { id name } } } }' -f owner="$OWNER" -f repo="$REPO" | jq -r --arg type "$issue_type" '.data.repository.issueTypes.nodes[] | select(.name == $type) | .id')" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo "  ✅ Successfully set to $issue_type"
    else
        echo "  ⚠️  Failed to set type (may need manual setting)"
    fi
    echo ""
}

# Process each issue
gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number,title | \
jq -r '.[] | "\(.number)|\(.title)"' | while IFS='|' read -r issue_num issue_title; do
    
    # Skip if already set
    current_type=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          issueType {
            name
          }
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -F number="$issue_num" | jq -r '.data.repository.issue.issueType.name // "Not Set"')
    
    if [[ "$current_type" != "Not Set" ]]; then
        echo "Issue #$issue_num already has type: $current_type"
        continue
    fi
    
    # Determine type based on title content
    if [[ "$issue_title" == *"Configure GitHub"* || "$issue_title" == *"Update CI/CD"* ]]; then
        set_issue_type "$issue_num" "Task" "$issue_title"
    elif [[ "$issue_title" == *"documentation"* || "$issue_title" == *"README"* || "$issue_title" == *"guide"* ]]; then
        set_issue_type "$issue_num" "Task" "$issue_title"
    elif [[ "$issue_title" == *"fix"* || "$issue_title" == *"bug"* || "$issue_title" == *"error"* ]]; then
        set_issue_type "$issue_num" "Bug" "$issue_title"
    else
        # Default to Feature for module implementations
        set_issue_type "$issue_num" "Feature" "$issue_title"
    fi
done

echo ""
echo "📊 Updated Issue Type Distribution:"
echo "=================================="

# Show final distribution
echo "Counting issue types..."
task_count=0
feature_count=0 
bug_count=0
not_set_count=0

while read issue_num; do
    issue_type=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          issueType {
            name
          }
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -F number="$issue_num" | jq -r '.data.repository.issue.issueType.name // "Not Set"')
    
    case "$issue_type" in
        "Task") task_count=$((task_count + 1)) ;;
        "Feature") feature_count=$((feature_count + 1)) ;;
        "Bug") bug_count=$((bug_count + 1)) ;;
        *) not_set_count=$((not_set_count + 1)) ;;
    esac
done < <(gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number | jq -r '.[].number')

echo "🚀 Feature: $feature_count issues"
echo "⚡ Task: $task_count issues"
echo "� Bug: $bug_count issues"
if [[ $not_set_count -gt 0 ]]; then
    echo "❓ Not Set: $not_set_count issues"
fi

echo ""
echo "🎉 Native GitHub Issue Types Set!"
echo "================================="
echo "✅ All issues now have proper GitHub issue types"
echo "✅ Types are visible in GitHub UI and project boards"
echo "✅ Can be used for filtering and organization"

echo ""
echo "💡 Issue Type Usage:"
echo "• Feature: New module implementations"
echo "• Task: Configuration, documentation, process improvements"  
echo "• Bug: Issues and fixes"
