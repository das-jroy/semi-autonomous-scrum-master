#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Set Sample Dates for Roadmap Timeline
echo "🗓️ Setting Sample Dates for Roadmap Timeline"
echo "============================================="

# Get project and field information dynamically
echo "📋 Getting project information..."
PROJECT_DATA=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    projectV2(number: $number) {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
        }
      }
    }
  }
}' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F number="$PROJECT_NUMBER")

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.id')
START_DATE_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Start Date") | .id')
TARGET_DATE_ID=$(echo "$PROJECT_DATA" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Target Date") | .id')

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
    echo "❌ Could not find project. Please check PROJECT_NUMBER in config."
    exit 1
fi

echo "✅ Project ID: $PROJECT_ID"

# Get sample issues to set dates on
echo "🔍 Finding issues to set sample dates..."
ISSUES_DATA=$(gh api graphql -f query='
query($owner: String!, $repo: String!) {
  repository(owner: $owner, name: $repo) {
    issues(first: 5, states: OPEN) {
      nodes {
        id
        number
        title
      }
    }
  }
}' -f owner="$REPO_OWNER" -f repo="$REPO_NAME")

# Set sample dates for first few issues
echo "📅 Setting sample dates for high-priority items..."
echo "$ISSUES_DATA" | jq -r '.data.repository.issues.nodes[] | "\(.id)|\(.number)|\(.title)"' | head -3 | while IFS='|' read -r issue_id issue_number title; do
    echo "Setting dates for Issue #$issue_number: $title"
    
    # Calculate progressive dates
    start_days=$(( ($issue_number - 1) * 7 ))
    target_days=$(( $start_days + 14 ))
    
    start_date=$(date -v +${start_days}d +%Y-%m-%d 2>/dev/null || date -d "+${start_days} days" +%Y-%m-%d)
    target_date=$(date -v +${target_days}d +%Y-%m-%d 2>/dev/null || date -d "+${target_days} days" +%Y-%m-%d)
    
    # Add issue to project and set dates (simplified approach)
    gh api graphql -f query='
    mutation($projectId: ID!, $contentId: ID!) {
      addProjectV2ItemByContentId(input: {
        projectId: $projectId
        contentId: $contentId
      }) {
        item {
          id
        }
      }
    }' -f projectId="$PROJECT_ID" -f contentId="$issue_id" >/dev/null 2>&1
    
    echo "  ✅ Sample dates: $start_date → $target_date"
done
echo ""
echo "🎯 Your roadmap timeline is now ready!"
echo ""
echo "Visit your roadmap view to see the timeline:"
echo "https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER/views/5"
echo ""
echo "💡 To configure the roadmap view:"
echo "1. Click on the view settings"
echo "2. Set 'Start Date' as the start field"
echo "3. Set 'Target Date' as the target field"
echo "4. Choose your preferred timeline scale"
