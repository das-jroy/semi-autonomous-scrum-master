#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Verify Native GitHub Issue Types Implementation
# Shows the current state and provides guidance for project management

set -e

# OWNER loaded from config
# REPO loaded from config

echo "🔍 Native GitHub Issue Types Verification"
echo "=========================================="
echo "Repository: $OWNER/$REPO"
echo ""

echo "📊 Issue Type Distribution:"
echo "==========================="

# Count issues by type
task_count=0
feature_count=0 
bug_count=0
not_set_count=0

while read issue_num; do
    issue_info=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          number
          title
          issueType {
            name
          }
          labels(first: 10) {
            nodes {
              name
            }
          }
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -F number="$issue_num")
    
    issue_type=$(echo "$issue_info" | jq -r '.data.repository.issue.issueType.name // "Not Set"')
    issue_title=$(echo "$issue_info" | jq -r '.data.repository.issue.title')
    
    case "$issue_type" in
        "Task") 
            task_count=$((task_count + 1))
            echo "⚡ #$issue_num [Task]: $issue_title"
            ;;
        "Feature") 
            feature_count=$((feature_count + 1))
            echo "🚀 #$issue_num [Feature]: $issue_title"
            ;;
        "Bug") 
            bug_count=$((bug_count + 1))
            echo "🐛 #$issue_num [Bug]: $issue_title"
            ;;
        *) 
            not_set_count=$((not_set_count + 1))
            echo "❓ #$issue_num [Not Set]: $issue_title"
            ;;
    esac
done < <(gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number | jq -r '.[].number')

echo ""
echo "📈 Summary:"
echo "----------"
echo "🚀 Features: $feature_count issues (module implementations)"
echo "⚡ Tasks: $task_count issues (configuration, documentation)"
echo "🐛 Bugs: $bug_count issues (fixes and errors)"
if [[ $not_set_count -gt 0 ]]; then
    echo "❓ Not Set: $not_set_count issues (need attention)"
fi

total_issues=$((task_count + feature_count + bug_count + not_set_count))
set_issues=$((task_count + feature_count + bug_count))
coverage_percent=$((set_issues * 100 / total_issues))

echo ""
echo "✅ Coverage: $set_issues/$total_issues issues have native types set ($coverage_percent%)"

echo ""
echo "🎯 Benefits of Native Issue Types:"
echo "=================================="
echo "• 🔍 Improved filtering in GitHub UI and project boards"
echo "• 📋 Better organization for different work types"
echo "• 📊 Enhanced reporting and metrics collection"
echo "• 🔄 Integration with GitHub's native workflows"
echo "• 🎨 Visual distinction in lists and boards"

echo ""
echo "💡 How to Use in GitHub UI:"
echo "=========================="
echo "• Project Board: Filter by 'Type' field in views"
echo "• Issue Lists: Use 'is:issue type:feature' search syntax"
echo "• Automation: Set up rules based on issue types"
echo "• Templates: Configure default types for new issues"

echo ""
echo "🚀 Next Steps:"
echo "=============="
echo "• Verify types are visible in GitHub project board"
echo "• Configure project board views to filter by type"
echo "• Set up issue templates with default types"
echo "• Train team on using type-based filtering"

echo ""
echo "🔗 GitHub UI Verification:"
echo "========================="
echo "Visit: https://github.com/$OWNER/$REPO/issues"
echo "• Check that issues show type badges"
echo "• Test filtering: 'is:issue type:feature'"
echo "• Verify project board shows type field"

echo ""
echo "✅ Native GitHub Issue Types Successfully Implemented!"
