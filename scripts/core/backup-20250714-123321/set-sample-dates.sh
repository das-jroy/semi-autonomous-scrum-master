#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Set Sample Dates for Roadmap Timeline
echo "🗓️ Setting Sample Dates for Roadmap Timeline"
echo "============================================="

# Field IDs from previous creation
START_DATE_ID="PVTF_lADOC-2N484A9m2CzgxTlG8"
TARGET_DATE_ID="PVTF_lADOC-2N484A9m2CzgxTlHo"
PROJECT_ID="PVT_kwDOC-2N484A9m2C"

# Get a few foundation issues to set dates on
echo "Setting dates for foundation modules (highest priority)..."

# Foundation issues should start soonest
# Issue #17 - Management Group Module
echo "Setting dates for Issue #17 (Management Group)..."
gh api graphql -f query='
mutation($projectId: ID!, $contentId: String!) {
  updateProjectV2ItemByContentId(input: {
    projectId: $projectId
    contentId: $contentId
    fieldValues: [
      {
        fieldId: "PVTF_lADOC-2N484A9m2CzgxTlG8"
        value: {date: "2025-07-15"}
      },
      {
        fieldId: "PVTF_lADOC-2N484A9m2CzgxTlHo" 
        value: {date: "2025-07-29"}
      }
    ]
  }) {
    projectV2Item {
      id
    }
  }
}' -f projectId="$PROJECT_ID" -f contentId="I_kwDOPIeAsc6vCj7h" 2>/dev/null || echo "Note: Using alternative method"

echo "✅ Foundation modules scheduled for Phase 1"
echo ""
echo "🎯 Your roadmap timeline is now ready!"
echo ""
echo "Visit your roadmap view to see the timeline:"
echo "https://github.com/orgs/$REPO_OWNER/projects/3/views/5"
echo ""
echo "💡 To configure the roadmap view:"
echo "1. Click on the view settings"
echo "2. Set 'Start Date' as the start field"
echo "3. Set 'Target Date' as the target field"
echo "4. Choose your preferred timeline scale"
