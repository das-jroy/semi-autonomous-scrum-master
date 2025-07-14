#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Add Date Fields for Roadmap Timeline
# Creates the necessary date and iteration fields for roadmap functionality

set -e

echo "🗓️ Setting Up Roadmap Timeline Fields"
echo "====================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
# REPO_OWNER loaded from config
PROJECT_NUMBER="3"

echo -e "${BLUE}📊 Getting Project Information${NC}"
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
echo ""

echo -e "${CYAN}🗓️ Creating Date Fields for Roadmap${NC}"
echo "=================================="

# Create Start Date field
echo "Creating 'Start Date' field..."
START_DATE_RESPONSE=$(gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
  createProjectV2Field(input: {
    projectId: $projectId
    name: $name
    dataType: $dataType
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}' -f projectId="$PROJECT_ID" -f name="Start Date" -f dataType="DATE")

START_DATE_ID=$(echo "$START_DATE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.id')
echo "✅ Start Date field created: $START_DATE_ID"

# Create Target Date field  
echo "Creating 'Target Date' field..."
TARGET_DATE_RESPONSE=$(gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
  createProjectV2Field(input: {
    projectId: $projectId
    name: $name
    dataType: $dataType
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}' -f projectId="$PROJECT_ID" -f name="Target Date" -f dataType="DATE")

TARGET_DATE_ID=$(echo "$TARGET_DATE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.id')
echo "✅ Target Date field created: $TARGET_DATE_ID"

# Create Sprint/Iteration field
echo "Creating 'Sprint' field..."
SPRINT_RESPONSE=$(gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!, $options: [ProjectV2SingleSelectFieldOptionInput!]!) {
  createProjectV2Field(input: {
    projectId: $projectId
    name: $name
    dataType: $dataType
    singleSelectOptions: $options
  }) {
    projectV2Field {
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
}' -f projectId="$PROJECT_ID" -f name="Sprint" -f dataType="SINGLE_SELECT" -f options='[
  {"name": "Sprint 1 (Jul 2025)", "color": "BLUE"},
  {"name": "Sprint 2 (Aug 2025)", "color": "GREEN"}, 
  {"name": "Sprint 3 (Sep 2025)", "color": "YELLOW"},
  {"name": "Sprint 4 (Oct 2025)", "color": "ORANGE"},
  {"name": "Backlog", "color": "GRAY"}
]')

SPRINT_ID=$(echo "$SPRINT_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.id')
echo "✅ Sprint field created: $SPRINT_ID"

echo ""
echo -e "${GREEN}🎯 Setting Up Sample Dates for Issues${NC}"
echo "===================================="

# Get some issues to set dates on
echo "Getting issues to set sample dates..."
ISSUES=$(gh api graphql -f query='
query($org: String!, $repo: String!) {
  repository(owner: $org, name: $repo) {
    issues(first: 5, states: OPEN) {
      nodes {
        id
        number
        title
      }
    }
  }
}' -f org="$REPO_OWNER" -f repo="$REPO_NAME")

# Set sample dates for the first few issues
echo "$ISSUES" | jq -r '.data.repository.issues.nodes[] | select(.number <= 20) | "\(.id)|\(.number)|\(.title)"' | head -5 | while IFS='|' read -r issue_id issue_number issue_title; do
    echo "Setting dates for Issue #$issue_number..."
    
    # Calculate dates based on issue number for variety
    start_days=$((($issue_number - 1) * 7))  # Week intervals
    target_days=$(($start_days + 14))        # 2 week sprints
    
    start_date=$(date -v +${start_days}d +%Y-%m-%d 2>/dev/null || date -d "+${start_days} days" +%Y-%m-%d)
    target_date=$(date -v +${target_days}d +%Y-%m-%d 2>/dev/null || date -d "+${target_days} days" +%Y-%m-%d)
    
    # Add issue to project and set dates
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
    
    # Get the project item ID
    ITEM_ID=$(gh api graphql -f query='
    query($projectId: ID!, $contentId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              content {
                ... on Issue {
                  id
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" -f contentId="$issue_id" | jq -r --arg contentId "$issue_id" '.data.node.items.nodes[] | select(.content.id == $contentId) | .id')
    
    if [ -n "$ITEM_ID" ] && [ "$ITEM_ID" != "null" ]; then
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
        }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$START_DATE_ID" -f value="$start_date" >/dev/null 2>&1
        
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
        }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$TARGET_DATE_ID" -f value="$target_date" >/dev/null 2>&1
        
        echo "  ✅ Set dates: $start_date → $target_date"
    else
        echo "  ⚠️ Could not set dates for issue #$issue_number"
    fi
done

echo ""
echo -e "${GREEN}🎉 Roadmap Timeline Setup Complete!${NC}"
echo "=================================="
echo ""
echo "✅ Created Fields:"
echo "   • Start Date - Track when work begins"
echo "   • Target Date - Track completion targets" 
echo "   • Sprint - Iteration/sprint assignment"
echo ""
echo "✅ Sample dates set for several issues"
echo ""
echo "🗺️ Your roadmap view should now work!"
echo "   Visit: https://github.com/orgs/$REPO_OWNER/projects/3/views/5"
echo ""
echo "💡 Next Steps:"
echo "   1. Refresh your roadmap view"
echo "   2. Configure timeline settings (Start Date → Target Date)"
echo "   3. Set dates for remaining issues as needed"
echo "   4. Enjoy your fully functional roadmap timeline! 🚀"
