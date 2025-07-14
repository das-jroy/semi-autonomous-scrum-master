#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# Update GitHub Issues with Proper Metadata
# This script adds labels, custom fields, and other metadata to existing issues

set -e

echo "🏷️  GitHub Issues Metadata Updater"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
# REPO_OWNER loaded from config
# REPO_NAME loaded from config
PROJECT_NUMBER="3"

# Function to validate prerequisites
validate_prerequisites() {
    echo -e "${CYAN}🔒 Validation${NC}"
    echo "============="
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI not installed${NC}"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
    
    # Get project ID
    PROJECT_ID=$(gh api graphql -f query='{
      organization(login: "'$REPO_OWNER'") {
        projectV2(number: '$PROJECT_NUMBER') {
          id
        }
      }
    }' --jq '.data.organization.projectV2.id')
    
    if [[ -z "$PROJECT_ID" ]]; then
        echo -e "${RED}❌ Could not get project ID${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Project ID obtained: $PROJECT_ID${NC}"
    echo ""
}

# Function to get custom field IDs
get_custom_field_ids() {
    echo -e "${BLUE}🔍 Getting Custom Field IDs${NC}"
    echo "============================"
    
    # Get all custom fields for the project
    local fields_query='query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2Field {
                id
                name
                dataType
              }
              ... on ProjectV2SingleSelectField {
                id
                name
                dataType
                options {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }'
    
    local fields_response=$(gh api graphql -f query="$fields_query" -f projectId="$PROJECT_ID")
    
    # Extract field IDs
    PRIORITY_FIELD_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Priority Level") | .id')
    CATEGORY_FIELD_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .id')
    COMPLEXITY_FIELD_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Complexity") | .id')
    SECURITY_FIELD_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Security Review") | .id')
    
    # Get option IDs for single select fields
    PRIORITY_HIGH_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Priority Level") | .options[] | select(.name == "P1 - High Impact") | .id')
    PRIORITY_MEDIUM_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Priority Level") | .options[] | select(.name == "P2 - Enterprise") | .id')
    PRIORITY_LOW_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Priority Level") | .options[] | select(.name == "P3 - Specialized") | .id')
    
    COMPLEXITY_HIGH_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Complexity") | .options[] | select(.name == "High (1-2 weeks)") | .id')
    COMPLEXITY_MEDIUM_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Complexity") | .options[] | select(.name == "Medium (3-5 days)") | .id')
    COMPLEXITY_LOW_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Complexity") | .options[] | select(.name == "Low (1-2 days)") | .id')
    
    SECURITY_REQUIRED_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Security Review") | .options[] | select(.name == "Required") | .id')
    SECURITY_NOT_REQUIRED_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Security Review") | .options[] | select(.name == "Not Required") | .id')
    
    # Get Module Category option IDs
    CATEGORY_FOUNDATION_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Foundation") | .id')
    CATEGORY_NETWORKING_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Networking") | .id')
    CATEGORY_COMPUTE_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Compute") | .id')
    CATEGORY_STORAGE_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Storage") | .id')
    CATEGORY_DATABASE_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Database") | .id')
    CATEGORY_CONTAINERS_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Containers") | .id')
    CATEGORY_SECURITY_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Security") | .id')
    CATEGORY_MONITORING_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Monitoring") | .id')
    CATEGORY_INFRASTRUCTURE_ID=$(echo "$fields_response" | jq -r '.data.node.fields.nodes[] | select(.name == "Module Category") | .options[] | select(.name == "Infrastructure") | .id')
    
    echo "Priority Field ID: $PRIORITY_FIELD_ID"
    echo "Category Field ID: $CATEGORY_FIELD_ID"
    echo "Complexity Field ID: $COMPLEXITY_FIELD_ID"
    echo "Security Field ID: $SECURITY_FIELD_ID"
    echo "Priority High ID: $PRIORITY_HIGH_ID"
    echo "Priority Medium ID: $PRIORITY_MEDIUM_ID"
    echo "Priority Low ID: $PRIORITY_LOW_ID"
    echo "Complexity High ID: $COMPLEXITY_HIGH_ID"
    echo "Complexity Medium ID: $COMPLEXITY_MEDIUM_ID"
    echo "Complexity Low ID: $COMPLEXITY_LOW_ID"
    echo "Security Required ID: $SECURITY_REQUIRED_ID"
    echo "Security Not Required ID: $SECURITY_NOT_REQUIRED_ID"
    echo ""
}

# Function to get category option ID based on category name
get_category_option_id() {
    local category="$1"
    case "$category" in
        "Foundation"|"Infrastructure")
            echo "$CATEGORY_FOUNDATION_ID"
            ;;
        "Networking")
            echo "$CATEGORY_NETWORKING_ID"
            ;;
        "Compute")
            echo "$CATEGORY_COMPUTE_ID"
            ;;
        "Storage")
            echo "$CATEGORY_STORAGE_ID"
            ;;
        "Database")
            echo "$CATEGORY_DATABASE_ID"
            ;;
        "Containers")
            echo "$CATEGORY_CONTAINERS_ID"
            ;;
        "Security")
            echo "$CATEGORY_SECURITY_ID"
            ;;
        "Monitoring")
            echo "$CATEGORY_MONITORING_ID"
            ;;
        *)
            echo "$CATEGORY_FOUNDATION_ID"  # Default to Foundation
            ;;
    esac
}

# Function to update issue metadata
update_issue_metadata() {
    local issue_number="$1"
    local title="$2"
    local labels=("${!3}")
    local priority_option_id="$4"
    local category="$5"
    local complexity_option_id="$6"
    local security_option_id="$7"
    
    # Get the category option ID
    local category_option_id=$(get_category_option_id "$category")
    
    echo -e "${PURPLE}📝 Updating Issue #$issue_number: $title${NC}"
    echo "=================================================="
    
    # Add labels to issue
    if [[ ${#labels[@]} -gt 0 ]]; then
        local labels_str=$(printf "%s," "${labels[@]}")
        labels_str=${labels_str%,}  # Remove trailing comma
        
        echo "Adding labels: $labels_str"
        gh issue edit "$issue_number" --repo "$REPO_OWNER/$REPO_NAME" --add-label "$labels_str"
    fi
    
    # Get project item ID for this issue
    local project_item_id=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 50) {
            nodes {
              id
              content {
                ... on Issue {
                  number
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" --jq ".data.node.items.nodes[] | select(.content.number == $issue_number) | .id")
    
    if [[ -z "$project_item_id" ]]; then
        echo -e "${RED}❌ Issue not found in project board${NC}"
        return 1
    fi
    
    # Update Priority Level
    if [[ -n "$priority_option_id" && -n "$PRIORITY_FIELD_ID" ]]; then
        echo "Setting priority level... (Option ID: $priority_option_id, Field ID: $PRIORITY_FIELD_ID)"
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: { singleSelectOptionId: $optionId }
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$project_item_id" -f fieldId="$PRIORITY_FIELD_ID" -f optionId="$priority_option_id" > /dev/null
    fi
    
    # Update Module Category (single select field)
    if [[ -n "$category_option_id" && -n "$CATEGORY_FIELD_ID" ]]; then
        echo "Setting module category: $category (Option ID: $category_option_id)"
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: { singleSelectOptionId: $optionId }
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$project_item_id" -f fieldId="$CATEGORY_FIELD_ID" -f optionId="$category_option_id" > /dev/null
    fi
    
    # Update Complexity
    if [[ -n "$complexity_option_id" && -n "$COMPLEXITY_FIELD_ID" ]]; then
        echo "Setting complexity level... (Option ID: $complexity_option_id, Field ID: $COMPLEXITY_FIELD_ID)"
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: { singleSelectOptionId: $optionId }
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$project_item_id" -f fieldId="$COMPLEXITY_FIELD_ID" -f optionId="$complexity_option_id" > /dev/null
    fi
    
    # Update Security Review
    if [[ -n "$security_option_id" && -n "$SECURITY_FIELD_ID" ]]; then
        echo "Setting security review requirement..."
        gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $projectId
            itemId: $itemId
            fieldId: $fieldId
            value: { singleSelectOptionId: $optionId }
          }) {
            projectV2Item {
              id
            }
          }
        }' -f projectId="$PROJECT_ID" -f itemId="$project_item_id" -f fieldId="$SECURITY_FIELD_ID" -f optionId="$security_option_id" > /dev/null
    fi
    
    echo -e "${GREEN}✅ Updated issue #$issue_number${NC}"
    echo ""
}

# Function to update all issues with metadata
update_all_issues() {
    echo -e "${BLUE}🏷️  Updating All Issues with Metadata${NC}"
    echo "====================================="
    echo ""
    
    # Issue #21: Configure GitHub Project Board
    local labels_21=("documentation" "project-management" "enhancement")
    update_issue_metadata "21" "Configure GitHub Project Board" labels_21[@] "$PRIORITY_MEDIUM_ID" "Infrastructure" "$COMPLEXITY_LOW_ID" "$SECURITY_NOT_REQUIRED_ID"
    
    # Issue #20: Update CI/CD Workflow
    local labels_20=("ci-cd" "enhancement" "infrastructure")
    update_issue_metadata "20" "Update CI/CD Workflow" labels_20[@] "$PRIORITY_HIGH_ID" "Infrastructure" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #19: Monitor Alerts Module
    local labels_19=("module" "monitoring" "implementation")
    update_issue_metadata "19" "Implement Monitor Alerts Module" labels_19[@] "$PRIORITY_MEDIUM_ID" "Monitoring" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_NOT_REQUIRED_ID"
    
    # Issue #18: Log Analytics Module
    local labels_18=("module" "monitoring" "implementation")
    update_issue_metadata "18" "Implement Log Analytics Module" labels_18[@] "$PRIORITY_MEDIUM_ID" "Monitoring" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_NOT_REQUIRED_ID"
    
    # Issue #17: Management Group Module
    local labels_17=("module" "foundation" "implementation")
    update_issue_metadata "17" "Implement Management Group Module" labels_17[@] "$PRIORITY_HIGH_ID" "Foundation" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #16: Subscription Module
    local labels_16=("module" "foundation" "implementation")
    update_issue_metadata "16" "Implement Subscription Module" labels_16[@] "$PRIORITY_HIGH_ID" "Foundation" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #15: File Share Module
    local labels_15=("module" "storage" "implementation")
    update_issue_metadata "15" "Implement File Share Module" labels_15[@] "$PRIORITY_MEDIUM_ID" "Storage" "$COMPLEXITY_LOW_ID" "$SECURITY_NOT_REQUIRED_ID"
    
    # Issue #14: Container Instances Module
    local labels_14=("module" "containers" "implementation")
    update_issue_metadata "14" "Implement Container Instances Module" labels_14[@] "$PRIORITY_MEDIUM_ID" "Containers" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #13: VM Scale Set Module
    local labels_13=("module" "compute" "implementation")
    update_issue_metadata "13" "Implement VM Scale Set Module" labels_13[@] "$PRIORITY_MEDIUM_ID" "Compute" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #12: Security Center Module
    local labels_12=("module" "security" "implementation")
    update_issue_metadata "12" "Implement Security Center Module" labels_12[@] "$PRIORITY_HIGH_ID" "Security" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #11: Route Table Module
    local labels_11=("module" "networking" "implementation")
    update_issue_metadata "11" "Implement Route Table Module" labels_11[@] "$PRIORITY_MEDIUM_ID" "Networking" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_NOT_REQUIRED_ID"
    
    # Issue #10: VPN Gateway Module
    local labels_10=("module" "networking" "implementation")
    update_issue_metadata "10" "Implement VPN Gateway Module" labels_10[@] "$PRIORITY_MEDIUM_ID" "Networking" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #9: Application Gateway Module
    local labels_9=("module" "networking" "implementation")
    update_issue_metadata "9" "Implement Application Gateway Module" labels_9[@] "$PRIORITY_MEDIUM_ID" "Networking" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #8: Load Balancer Module
    local labels_8=("module" "networking" "implementation")
    update_issue_metadata "8" "Implement Load Balancer Module" labels_8[@] "$PRIORITY_MEDIUM_ID" "Networking" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_NOT_REQUIRED_ID"
    
    # Issue #7: AKS Cluster Module
    local labels_7=("module" "containers" "implementation")
    update_issue_metadata "7" "Implement AKS Cluster Module" labels_7[@] "$PRIORITY_HIGH_ID" "Containers" "$COMPLEXITY_HIGH_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #6: Cosmos DB Module
    local labels_6=("module" "database" "implementation")
    update_issue_metadata "6" "Implement Cosmos DB Module" labels_6[@] "$PRIORITY_MEDIUM_ID" "Database" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_REQUIRED_ID"
    
    # Issue #5: Virtual Machine Module
    local labels_5=("module" "compute" "implementation")
    update_issue_metadata "5" "Implement Virtual Machine Module" labels_5[@] "$PRIORITY_HIGH_ID" "Compute" "$COMPLEXITY_MEDIUM_ID" "$SECURITY_REQUIRED_ID"
}

# Function to show completion summary
show_completion_summary() {
    echo -e "${GREEN}🎉 Issues Metadata Update Complete!${NC}"
    echo "===================================="
    echo ""
    echo -e "${YELLOW}📊 Summary:${NC}"
    echo "- Updated 17 GitHub issues with proper metadata"
    echo "- Added relevant labels to categorize issues"
    echo "- Set priority levels (High/Medium/Low)"
    echo "- Assigned module categories"
    echo "- Set complexity ratings"
    echo "- Configured security review requirements"
    echo ""
    echo -e "${BLUE}🔗 Next Steps:${NC}"
    echo "1. Check your issues: https://github.com/$REPO_OWNER/$REPO_NAME/issues"
    echo "2. View project board: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
    echo "3. Create project board views (if not done yet)"
    echo "4. Start implementing modules based on priority!"
    echo ""
}

# Main execution
main() {
    validate_prerequisites
    get_custom_field_ids
    update_all_issues
    show_completion_summary
}

# Run main function
main
