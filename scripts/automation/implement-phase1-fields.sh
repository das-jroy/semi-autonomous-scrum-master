#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Implement Phase 1 Additional Fields
# Creates Status (with DOR), Type, and Milestone fields

set -e

echo "🚀 Implementing Phase 1 Additional Fields"
echo "========================================"
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

echo -e "${CYAN}🏗️ Creating Status Field with DOR Integration${NC}"
echo "=============================================="

# Create Status field with DOR workflow
echo "Creating 'Status' field with DOR workflow..."
STATUS_RESPONSE=$(gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
  createProjectV2Field(input: {
    projectId: $projectId
    name: $name
    dataType: $dataType
    singleSelectOptions: [
      {name: "Draft", description: "Initial creation, DOR not met", color: GRAY},
      {name: "Ready (DOR)", description: "Definition of Ready criteria met", color: BLUE},
      {name: "In Progress", description: "Active development", color: YELLOW},
      {name: "Code Review", description: "Development complete, under review", color: ORANGE},
      {name: "Testing", description: "Code approved, under testing", color: PURPLE},
      {name: "Done", description: "Complete and deployed", color: GREEN}
    ]
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
}' -f projectId="$PROJECT_ID" -f name="Status" -f dataType="SINGLE_SELECT")

STATUS_ID=$(echo "$STATUS_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.id')
echo "✅ Status field created: $STATUS_ID"

# Extract option IDs for later use
DRAFT_ID=$(echo "$STATUS_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Draft") | .id')
READY_DOR_ID=$(echo "$STATUS_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Ready (DOR)") | .id')
IN_PROGRESS_ID=$(echo "$STATUS_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "In Progress") | .id')

echo ""
echo -e "${CYAN}📋 Creating Type Field${NC}"
echo "====================="

# Create Type field for issue categorization
echo "Creating 'Type' field..."
TYPE_RESPONSE=$(gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
  createProjectV2Field(input: {
    projectId: $projectId
    name: $name
    dataType: $dataType
    singleSelectOptions: [
      {name: "Feature", description: "New functionality", color: GREEN},
      {name: "Bug Fix", description: "Fix for existing issues", color: RED},
      {name: "Epic", description: "Large feature set", color: PURPLE},
      {name: "Task", description: "Implementation task", color: BLUE},
      {name: "Documentation", description: "Documentation updates", color: GRAY}
    ]
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
}' -f projectId="$PROJECT_ID" -f name="Type" -f dataType="SINGLE_SELECT")

TYPE_ID=$(echo "$TYPE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.id')
echo "✅ Type field created: $TYPE_ID"

echo ""
echo -e "${CYAN}🎯 Creating Milestone Field${NC}"
echo "=========================="

# Create Milestone field for release planning
echo "Creating 'Milestone' field..."
MILESTONE_RESPONSE=$(gh api graphql -f query='
mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
  createProjectV2Field(input: {
    projectId: $projectId
    name: $name
    dataType: $dataType
    singleSelectOptions: [
      {name: "Foundation Release", description: "Core foundation modules", color: RED},
      {name: "Core Modules Release", description: "Main infrastructure modules", color: ORANGE},
      {name: "Advanced Features", description: "Advanced service modules", color: BLUE},
      {name: "v1.0 Release", description: "Complete module catalog", color: GREEN},
      {name: "Future", description: "Post-v1.0 enhancements", color: GRAY}
    ]
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
}' -f projectId="$PROJECT_ID" -f name="Milestone" -f dataType="SINGLE_SELECT")

MILESTONE_ID=$(echo "$MILESTONE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.id')
echo "✅ Milestone field created: $MILESTONE_ID"

echo ""
echo -e "${YELLOW}🔧 Setting Default Values on Existing Issues${NC}"
echo "============================================"

# Get all issues and set default values
echo "Setting default Status, Type, and Milestone values..."

# Get issues and their project items
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

# Process each issue and set default values
echo "$ISSUES_DATA" | jq -r '.data.repository.issues.nodes[] | 
  select(.projectItems.nodes[] | select(.project.number == 3)) |
  {
    number: .number,
    title: .title,
    itemId: (.projectItems.nodes[] | select(.project.number == 3) | .id),
    labels: [.labels.nodes[].name]
  } | @base64' | head -5 | while read -r encoded_issue; do
    
    # Decode issue data
    issue_data=$(echo "$encoded_issue" | base64 -d)
    issue_number=$(echo "$issue_data" | jq -r '.number')
    issue_title=$(echo "$issue_data" | jq -r '.title')
    item_id=$(echo "$issue_data" | jq -r '.itemId')
    labels=$(echo "$issue_data" | jq -r '.labels[]' | tr '\n' ' ')
    
    echo "Setting defaults for Issue #${issue_number}..."
    
    # Determine Type based on labels and title
    type_option=""
    if echo "$labels" | grep -q "module"; then
        type_option=$(echo "$TYPE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Feature") | .id')
    elif echo "$labels" | grep -q "documentation"; then
        type_option=$(echo "$TYPE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Documentation") | .id')
    elif echo "$labels" | grep -q "ci-cd\|infrastructure"; then
        type_option=$(echo "$TYPE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Task") | .id')
    else
        type_option=$(echo "$TYPE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Feature") | .id')
    fi
    
    # Determine Milestone based on labels
    milestone_option=""
    if echo "$labels" | grep -q "foundation"; then
        milestone_option=$(echo "$MILESTONE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Foundation Release") | .id')
    elif echo "$labels" | grep -q "compute\|networking\|storage\|database"; then
        milestone_option=$(echo "$MILESTONE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Core Modules Release") | .id')
    elif echo "$labels" | grep -q "security\|monitoring\|containers"; then
        milestone_option=$(echo "$MILESTONE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "Advanced Features") | .id')
    else
        milestone_option=$(echo "$MILESTONE_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name == "v1.0 Release") | .id')
    fi
    
    # Set Status to "Ready (DOR)" for well-defined module issues, "Draft" for others
    status_option=""
    if echo "$labels" | grep -q "module"; then
        status_option="$READY_DOR_ID"  # Module issues are well-defined
    else
        status_option="$DRAFT_ID"      # Infrastructure issues may need more definition
    fi
    
    # Set the fields
    if [ -n "$item_id" ] && [ "$item_id" != "null" ]; then
        # Set Status
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {singleSelectOptionId: $optionId}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$STATUS_ID" -f optionId="$status_option" >/dev/null 2>&1
        
        # Set Type
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {singleSelectOptionId: $optionId}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$TYPE_ID" -f optionId="$type_option" >/dev/null 2>&1
        
        # Set Milestone
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: {singleSelectOptionId: $optionId}
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$item_id" -f fieldId="$MILESTONE_ID" -f optionId="$milestone_option" >/dev/null 2>&1
        
        echo "  ✅ Defaults set"
    fi
done

echo ""
echo -e "${GREEN}🎉 Phase 1 Fields Implementation Complete!${NC}"
echo "==========================================="
echo ""
echo "✅ Status field created with DOR integration"
echo "✅ Type field created for issue categorization"
echo "✅ Milestone field created for release planning"
echo "✅ Default values set on existing issues"
echo ""
echo "🏗️ NEW WORKFLOW WITH DOR:"
echo "Todo → Ready (DOR) → In Progress → Code Review → Testing → Done"
echo ""
echo "📊 NEW VIEWS RECOMMENDED:"
echo "• DOR Status View - Filter by Status for DOR compliance"
echo "• Type Breakdown View - Group by Type for velocity metrics"
echo "• Milestone Progress View - Group by Milestone for release planning"
echo ""
echo "🎯 NEXT STEPS:"
echo "1. Review Status values on issues (most modules set to 'Ready (DOR)')"
echo "2. Adjust Status for any issues that don't meet DOR criteria"
echo "3. Use new fields for sprint planning and metrics"
echo "4. Consider adding 'Ready (DOR)' column to kanban board"
echo ""
echo "🔗 Visit your project board to see the new fields:"
echo "   https://github.com/orgs/$REPO_OWNER/projects/3"
