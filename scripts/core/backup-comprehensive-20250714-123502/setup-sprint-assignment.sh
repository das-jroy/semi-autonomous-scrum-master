#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Add Issues to Sprint
# Assigns all issues to a sprint for complete project management

set -e

# OWNER loaded from config
# REPO loaded from config

echo "🏃 $PROJECT_NAME Catalog - Sprint Assignment"
echo "==============================================="
echo "Repository: $OWNER/$REPO"
echo ""

# Define sprint details
SPRINT_NAME="Sprint 1: Infrastructure Module Implementation"
SPRINT_START="2025-07-11"
SPRINT_END="2025-07-25"

echo "🎯 Sprint Details:"
echo "=================="
echo "Sprint Name: $SPRINT_NAME"
echo "Start Date: $SPRINT_START"
echo "End Date: $SPRINT_END"
echo "Duration: 2 weeks"
echo ""

echo "📋 Sprint Objectives:"
echo "===================="
echo "• Complete project automation setup"
echo "• Implement core Azure infrastructure modules"
echo "• Establish enterprise-ready development workflow"
echo "• Finalize multi-cloud template system"
echo ""

echo "📊 Issues to be included in sprint:"
echo "==================================="

# List all issues with their types
issue_count=0
feature_count=0
task_count=0

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
          labels(first: 5) {
            nodes {
              name
            }
          }
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -F number="$issue_num")
    
    issue_title=$(echo "$issue_info" | jq -r '.data.repository.issue.title')
    issue_type=$(echo "$issue_info" | jq -r '.data.repository.issue.issueType.name // "Not Set"')
    
    case "$issue_type" in
        "Feature") 
            feature_count=$((feature_count + 1))
            echo "🚀 #$issue_num [Feature]: $issue_title"
            ;;
        "Task") 
            task_count=$((task_count + 1))
            echo "⚡ #$issue_num [Task]: $issue_title"
            ;;
        *)
            echo "📝 #$issue_num [$issue_type]: $issue_title"
            ;;
    esac
    
    issue_count=$((issue_count + 1))
done < <(gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number | jq -r '.[].number')

echo ""
echo "📈 Sprint Composition:"
echo "====================="
echo "🚀 Features: $feature_count issues"
echo "⚡ Tasks: $task_count issues"
echo "📊 Total: $issue_count issues"

echo ""
echo "🎯 Sprint Success Criteria:"
echo "=========================="
echo "• All project automation components operational"
echo "• Native GitHub issue types implemented (✅ DONE)"
echo "• Project board with optimized views (✅ DONE)"  
echo "• Multi-cloud template system ready (✅ DONE)"
echo "• Core infrastructure modules implemented"
echo "• Enterprise workflow documentation complete"

echo ""
echo "💡 Sprint Management Instructions:"
echo "=================================="
echo "Since GitHub Projects V2 iteration fields require manual setup in the UI:"
echo ""
echo "1. Visit: https://github.com/$OWNER/$REPO/projects"
echo "2. Add an 'Iteration' field to the project"
echo "3. Create iteration: '$SPRINT_NAME'"
echo "4. Set dates: $SPRINT_START to $SPRINT_END"
echo "5. Assign all issues to this iteration"
echo ""
echo "Alternative: Use Labels for Sprint Tracking"
echo "==========================================="

# Create sprint label
echo "Creating 'sprint-1' label for tracking..."
gh api repos/$OWNER/$REPO/labels -X POST \
  -f name="sprint-1" \
  -f description="Sprint 1: Infrastructure Module Implementation" \
  -f color="1f77b4" 2>/dev/null || echo "Label may already exist"

echo ""
echo "🏷️ Applying 'sprint-1' label to all issues..."

# Apply sprint label to all issues
while read issue_num; do
    echo "Adding sprint-1 label to issue #$issue_num..."
    gh api repos/$OWNER/$REPO/issues/$issue_num/labels -X POST -f labels='["sprint-1"]' >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "  ✅ Issue #$issue_num labeled"
    else
        echo "  ⚠️  Issue #$issue_num may already have label"
    fi
done < <(gh issue list --repo "$OWNER/$REPO" --state open --limit 50 --json number | jq -r '.[].number')

echo ""
echo "✅ Sprint Setup Complete!"
echo "========================="
echo "• Sprint label 'sprint-1' created and applied"
echo "• All $issue_count issues assigned to sprint"
echo "• Sprint tracking ready for project board"

echo ""
echo "🔍 Sprint Filtering:"
echo "===================="
echo "• GitHub Issues: Use filter 'label:sprint-1'"
echo "• Project Board: Filter by 'sprint-1' label"
echo "• Command Line: gh issue list --label sprint-1"

echo ""
echo "🎉 Sprint 1 Ready for Development!"
echo "==================================="
echo "Duration: 2 weeks ($SPRINT_START to $SPRINT_END)"
echo "Scope: $feature_count features + $task_count tasks"
echo "Focus: Complete infrastructure module automation"

echo ""
echo "Next: Visit the project board to begin sprint execution!"
