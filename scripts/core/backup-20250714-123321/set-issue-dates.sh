#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Set Dates on Issues for Roadmap Timeline
# Uses the same API pattern as priority/category/complexity setting

set -e

echo "🗓️ Setting Dates on Issues for Roadmap Timeline"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
# REPO_OWNER loaded from config
PROJECT_NUMBER="3"

echo -e "${BLUE}🔍 Getting Project and Field Information${NC}"

# Get project ID
PROJECT_ID=$(gh api graphql -f query='
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
    }
  }
}' -f org="$REPO_OWNER" -F number="$PROJECT_NUMBER" --jq '.data.organization.projectV2.id')

echo "Project ID: $PROJECT_ID"

# Get date field IDs
DATE_FIELDS=$(gh api graphql -f query='
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
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
}' -f org="$REPO_OWNER" -F number="$PROJECT_NUMBER")

START_DATE_ID=$(echo "$DATE_FIELDS" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Start Date") | .id')
TARGET_DATE_ID=$(echo "$DATE_FIELDS" | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name == "Target Date") | .id')

echo "Start Date Field ID: $START_DATE_ID"
echo "Target Date Field ID: $TARGET_DATE_ID"
echo ""

if [ "$START_DATE_ID" = "null" ] || [ "$TARGET_DATE_ID" = "null" ]; then
    echo "❌ Date fields not found. Please run setup-roadmap-dates.sh first."
    exit 1
fi

echo -e "${YELLOW}📋 Getting All Issues and Their Project Items${NC}"

# Get all issues and their project item IDs
ISSUES_DATA=$(gh api graphql -f query='
query($org: String!, $repo: String!) {
  repository(owner: $org, name: $repo) {
    issues(first: 100, states: OPEN) {
      nodes {
        id
        number
        title
        labels(first: 10) {
          nodes {
            name
          }
        }
        projectItems(first: 5) {
          nodes {
            id
            project {
              number
            }
          }
        }
      }
    }
  }
}' -f org="$REPO_OWNER" -f repo="$REPO_NAME")

echo -e "${GREEN}🗓️ Setting Dates Based on Priority and Phase${NC}"
echo "============================================"

# Process each issue and set appropriate dates
echo "$ISSUES_DATA" | jq -r '.data.repository.issues.nodes[] | 
  select(.projectItems.nodes[] | select(.project.number == 3)) |
  {
    number: .number,
    title: .title,
    itemId: (.projectItems.nodes[] | select(.project.number == 3) | .id),
    labels: [.labels.nodes[].name]
  } | @base64' | while read -r encoded_issue; do
    
    # Decode issue data
    issue_data=$(echo "$encoded_issue" | base64 -d)
    issue_number=$(echo "$issue_data" | jq -r '.number')
    issue_title=$(echo "$issue_data" | jq -r '.title')
    item_id=$(echo "$issue_data" | jq -r '.itemId')
    labels=$(echo "$issue_data" | jq -r '.labels[]' | tr '\n' ' ')
    
    echo ""
    echo "📝 Setting dates for Issue #${issue_number}: ${issue_title}"
    
    # Determine dates based on issue type and priority
    start_date=""
    target_date=""
    
    # Foundation modules (highest priority, start immediately)
    if echo "$labels" | grep -q "foundation"; then
        if [ "$issue_number" -eq 17 ]; then
            start_date="2025-07-15"
            target_date="2025-07-29"
        elif [ "$issue_number" -eq 16 ]; then
            start_date="2025-07-22"
            target_date="2025-08-05"
        fi
    # Compute modules (Phase 2)
    elif echo "$labels" | grep -q "compute"; then
        if [ "$issue_number" -eq 5 ]; then
            start_date="2025-08-01"
            target_date="2025-08-15"
        elif [ "$issue_number" -eq 13 ]; then
            start_date="2025-08-15"
            target_date="2025-08-29"
        fi
    # Container modules
    elif echo "$labels" | grep -q "containers"; then
        if [ "$issue_number" -eq 7 ]; then
            start_date="2025-08-05"
            target_date="2025-08-19"
        elif [ "$issue_number" -eq 14 ]; then
            start_date="2025-08-20"
            target_date="2025-09-03"
        fi
    # Database modules
    elif echo "$labels" | grep -q "database"; then
        start_date="2025-08-25"
        target_date="2025-09-08"
    # Networking modules
    elif echo "$labels" | grep -q "networking"; then
        case $issue_number in
            8) start_date="2025-08-10"; target_date="2025-08-24" ;;
            9) start_date="2025-08-15"; target_date="2025-08-29" ;;
            10) start_date="2025-09-01"; target_date="2025-09-15" ;;
            11) start_date="2025-09-05"; target_date="2025-09-19" ;;
        esac
    # Security modules
    elif echo "$labels" | grep -q "security"; then
        start_date="2025-09-10"
        target_date="2025-09-24"
    # Storage modules
    elif echo "$labels" | grep -q "storage"; then
        start_date="2025-08-20"
        target_date="2025-09-03"
    # Monitoring modules
    elif echo "$labels" | grep -q "monitoring"; then
        if [ "$issue_number" -eq 18 ]; then
            start_date="2025-09-15"
            target_date="2025-09-29"
        elif [ "$issue_number" -eq 19 ]; then
            start_date="2025-09-20"
            target_date="2025-10-04"
        fi
    # Infrastructure and documentation (later phases)
    else
        start_date="2025-10-01"
        target_date="2025-10-15"
    fi
    
    # Set the dates if we determined them
    if [ -n "$start_date" ] && [ -n "$target_date" ]; then
        echo "   📅 Setting: $start_date → $target_date"
        
        # Set start date
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Date!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {date: $value}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$START_DATE_ID" -f value="$start_date" >/dev/null 2>&1
        
        # Set target date
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Date!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {date: $value}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$TARGET_DATE_ID" -f value="$target_date" >/dev/null 2>&1
        
        echo "   ✅ Dates set successfully"
    else
        echo "   ⚠️  No specific dates assigned (using defaults)"
        # Set default dates for unassigned items
        start_date="2025-10-01"
        target_date="2025-10-15"
        
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Date!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {date: $value}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$START_DATE_ID" -f value="$start_date" >/dev/null 2>&1
        
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Date!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {date: $value}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$TARGET_DATE_ID" -f value="$target_date" >/dev/null 2>&1
        
        echo "   ✅ Default dates set: $start_date → $target_date"
    fi
done

echo ""
echo -e "${GREEN}🎉 Date Setting Complete!${NC}"
echo "========================="
echo ""
echo "✅ All issues now have start and target dates"
echo "✅ Foundation modules scheduled for July 2025"
echo "✅ Core infrastructure scheduled for August-September 2025"
echo "✅ Advanced services scheduled for September-October 2025"
echo ""
echo "🗺️ Your roadmap timeline should now display properly!"
echo ""
echo "🔗 Visit your roadmap view:"
echo "   https://github.com/orgs/$REPO_OWNER/projects/3/views/5"
echo ""
echo "💡 If the timeline doesn't appear automatically:"
echo "   1. Click view settings (⚙️ or ⋯ menu)"
echo "   2. Set 'Start field' to 'Start Date'"
echo "   3. Set 'Target field' to 'Target Date'"
echo "   4. Choose timeline scale (Weeks/Months)"
echo ""
echo "🚀 Your roadmap timeline is now ready for development planning!"
