#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# GitHub Project Template Manager
# Creates and applies GitHub project templates using the GitHub API

set -e

echo "🎯 GitHub Project Template Manager for InfraWeave Catalogs"
echo "=========================================================="

# Check if required parameters are provided
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <action> [cloud_provider] [repo_owner] [repo_name]"
    echo ""
    echo "Actions:"
    echo "  create-template <cloud_provider>           - Create a project template"
    echo "  apply-template <cloud_provider> <owner> <repo> - Apply template to repository"
    echo "  list-templates                              - List available templates"
    echo ""
    echo "Examples:"
    echo "  $0 create-template azure"
    echo "  $0 apply-template aws $REPO_OWNER aws-infraweave-catalog"
    echo "  $0 list-templates"
    echo ""
    echo "Supported cloud providers: aws, azure, gcp, multi-cloud"
    exit 1
fi

ACTION="$1"
CLOUD_PROVIDER="${2:-}"
# REPO_OWNER loaded from config
# REPO_NAME loaded from config

# Cloud provider configuration
configure_cloud_provider() {
    case "$1" in
        "aws")
            CLOUD_DISPLAY="AWS"
            CLOUD_EMOJI="☁️"
            PROVIDER_PREFIX="aws"
            ;;
        "azure")
            CLOUD_DISPLAY="Azure"
            CLOUD_EMOJI="🔷"
            PROVIDER_PREFIX="azurerm"
            ;;
        "gcp")
            CLOUD_DISPLAY="Google Cloud"
            CLOUD_EMOJI="🌀"
            PROVIDER_PREFIX="google"
            ;;
        "multi-cloud")
            CLOUD_DISPLAY="Multi-Cloud"
            CLOUD_EMOJI="🌐"
            PROVIDER_PREFIX="multi"
            ;;
        *)
            echo "❌ Unsupported cloud provider: $1"
            echo "Supported: aws, azure, gcp, multi-cloud"
            exit 1
            ;;
    esac
}

# Create project template
create_project_template() {
    local cloud_provider="$1"
    configure_cloud_provider "$cloud_provider"
    
    echo "$CLOUD_EMOJI Creating GitHub Project Template for $CLOUD_DISPLAY"
    echo "=================================================="
    
    # Template configuration file
    TEMPLATE_CONFIG="./github-project-templates/${cloud_provider}-infraweave-template.json"
    mkdir -p "./github-project-templates"
    
    echo "📝 Generating template configuration..."
    
    # Generate cloud-specific field configurations
    case "$cloud_provider" in
        "aws")
            MODULE_CATEGORIES='["Foundation","Compute","Storage","Networking","Database","Monitoring","Security","Containers"]'
            TEMPLATE_DESCRIPTION="AWS InfraWeave Module Catalog - Production-ready Terraform modules for AWS infrastructure with Platform 2.0 security"
            ;;
        "azure")
            MODULE_CATEGORIES='["Foundation","Compute","Storage","Networking","Database","Monitoring","Security","Containers"]'
            TEMPLATE_DESCRIPTION="$PROJECT_NAME"
            ;;
        "gcp")
            MODULE_CATEGORIES='["Foundation","Compute","Storage","Networking","Database","Monitoring","Security","Containers"]'
            TEMPLATE_DESCRIPTION="Google Cloud InfraWeave Module Catalog - Production-ready Terraform modules for GCP infrastructure with Platform 2.0 security"
            ;;
        "multi-cloud")
            MODULE_CATEGORIES='["Foundation","Compute","Storage","Networking","Database","Monitoring","Security","Containers","Cross-Cloud"]'
            TEMPLATE_DESCRIPTION="Multi-Cloud InfraWeave Module Catalog - Production-ready Terraform modules for multi-cloud infrastructure with Platform 2.0 security"
            ;;
    esac
    
    # Create the project template JSON
    cat > "$TEMPLATE_CONFIG" << EOF
{
  "name": "$CLOUD_DISPLAY InfraWeave Template",
  "description": "$TEMPLATE_DESCRIPTION",
  "body": "Enterprise-ready project template for $CLOUD_DISPLAY infrastructure module development with optimized GitHub project board, automation scripts, and best practices.",
  "public": true,
  "fields": [
    {
      "name": "Status",
      "data_type": "SINGLE_SELECT",
      "options": [
        {"name": "No Status", "description": "New issues awaiting triage", "color": "GRAY"},
        {"name": "DOR", "description": "Definition of Ready complete", "color": "GREEN"},
        {"name": "In Progress", "description": "Active development", "color": "YELLOW"},
        {"name": "Review", "description": "Code review and testing", "color": "BLUE"},
        {"name": "Blocked", "description": "Waiting on dependencies", "color": "RED"},
        {"name": "Done", "description": "Completed and merged", "color": "PURPLE"}
      ]
    },
    {
      "name": "Issue Type",
      "data_type": "SINGLE_SELECT",
      "options": [
        {"name": "Feature", "description": "New module implementations", "color": "GREEN"},
        {"name": "Enhancement", "description": "Improvements to existing functionality", "color": "BLUE"},
        {"name": "Bug", "description": "Issues and fixes", "color": "RED"},
        {"name": "Documentation", "description": "README, guides, examples", "color": "PURPLE"}
      ]
    },
    {
      "name": "Complexity",
      "data_type": "SINGLE_SELECT",
      "options": [
        {"name": "Low (1-2 days)", "description": "Simple modules", "color": "GREEN"},
        {"name": "Medium (3-5 days)", "description": "Standard modules", "color": "YELLOW"},
        {"name": "High (1-2 weeks)", "description": "Complex modules", "color": "RED"}
      ]
    },
    {
      "name": "Priority Level",
      "data_type": "SINGLE_SELECT",
      "options": [
        {"name": "P0 - Critical", "description": "Blocking issues", "color": "RED"},
        {"name": "P1 - High Impact", "description": "Foundation modules", "color": "YELLOW"},
        {"name": "P2 - Medium", "description": "Core modules", "color": "BLUE"},
        {"name": "P3 - Low Priority", "description": "Nice to have", "color": "GRAY"}
      ]
    },
    {
      "name": "Module Category",
      "data_type": "SINGLE_SELECT",
      "options": $(echo "$MODULE_CATEGORIES" | jq -c 'map({name: ., description: (. + " modules"), color: "BLUE"})')
    },
    {
      "name": "Security Review",
      "data_type": "SINGLE_SELECT",
      "options": [
        {"name": "Required", "description": "Security review needed", "color": "RED"},
        {"name": "Not Required", "description": "No security review needed", "color": "GRAY"},
        {"name": "In Progress", "description": "Security review in progress", "color": "YELLOW"},
        {"name": "Completed", "description": "Security review passed", "color": "GREEN"},
        {"name": "Blocked", "description": "Security issues found", "color": "RED"}
      ]
    },
    {
      "name": "Start Date",
      "data_type": "DATE"
    },
    {
      "name": "Target Date",
      "data_type": "DATE"
    },
    {
      "name": "Sprint",
      "data_type": "SINGLE_SELECT",
      "options": [
        {"name": "Sprint 1", "description": "Foundation modules", "color": "GREEN"},
        {"name": "Sprint 2", "description": "Core infrastructure", "color": "BLUE"},
        {"name": "Sprint 3", "description": "Advanced services", "color": "PURPLE"},
        {"name": "Backlog", "description": "Future sprints", "color": "GRAY"}
      ]
    }
  ],
  "views": [
    {
      "name": "Sprint Board",
      "layout": "BOARD_LAYOUT",
      "group_by": "Status",
      "description": "Kanban view for sprint management"
    },
    {
      "name": "Priority View",
      "layout": "TABLE_LAYOUT",
      "sort_by": [{"field": "Priority Level", "direction": "ASC"}],
      "description": "Issues sorted by priority level"
    },
    {
      "name": "Category View",
      "layout": "TABLE_LAYOUT",
      "group_by": "Module Category",
      "description": "Issues grouped by module category"
    },
    {
      "name": "Security Review",
      "layout": "TABLE_LAYOUT",
      "filter": {"field": "Security Review", "values": ["Required", "In Progress", "Blocked"]},
      "description": "Security-focused view"
    },
    {
      "name": "Roadmap",
      "layout": "ROADMAP_LAYOUT",
      "group_by": "Sprint",
      "description": "Timeline view for release planning"
    }
  ],
  "automation": {
    "workflows": [
      {
        "name": "Auto-assign Issue Type",
        "trigger": "issue.opened",
        "actions": [
          "Set Issue Type to Feature if title contains 'Implement'"
        ]
      },
      {
        "name": "Foundation Priority",
        "trigger": "issue.labeled",
        "condition": "label == 'foundation'",
        "actions": [
          "Set Priority Level to P1 - High Impact",
          "Set Security Review to Required"
        ]
      }
    ]
  }
}
EOF
    
    echo "✅ Created template configuration: $TEMPLATE_CONFIG"
    
    # Create the template setup script
    SETUP_SCRIPT="./github-project-templates/setup-${cloud_provider}-project.sh"
    
    cat > "$SETUP_SCRIPT" << 'EOF_SETUP'
#!/bin/bash

# {{CLOUD_DISPLAY}} InfraWeave Project Setup
# Applies the GitHub project template to a repository

set -e

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <repo_owner> <repo_name>"
    exit 1
fi

# REPO_OWNER loaded from config
# REPO_NAME loaded from config
CLOUD_PROVIDER="{{CLOUD_PROVIDER}}"
CLOUD_DISPLAY="{{CLOUD_DISPLAY}}"

echo "🚀 Setting up $CLOUD_DISPLAY InfraWeave Project for $REPO_OWNER/$REPO_NAME"
echo "================================================================="

# Check if template exists
TEMPLATE_FILE="./{{CLOUD_PROVIDER}}-infraweave-template.json"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Create GitHub project from template
echo "📋 Creating GitHub project from template..."
PROJECT_NAME="$CLOUD_DISPLAY InfraWeave Module Implementation - Platform 2.0"

# Use GitHub CLI to create project with template
gh project create \
    --owner "$REPO_OWNER" \
    --title "$PROJECT_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --format json > project-creation-result.json

PROJECT_ID=$(jq -r '.number' project-creation-result.json)
PROJECT_URL=$(jq -r '.url' project-creation-result.json)

echo "✅ Created project #$PROJECT_ID"
echo "🔗 URL: $PROJECT_URL"

# Link repository to project
echo "🔗 Linking repository to project..."
gh project link "$PROJECT_ID" --repo "$REPO_OWNER/$REPO_NAME"

echo "✅ Repository linked to project"

echo ""
echo "🎯 Project setup complete!"
echo "========================="
echo "📋 Project: $PROJECT_NAME"
echo "🔗 URL: $PROJECT_URL"
echo "📁 Repository: $REPO_OWNER/$REPO_NAME"
echo ""
echo "Next steps:"
echo "1. Create issues using the module templates"
echo "2. Configure automation workflows"
echo "3. Begin sprint planning with foundation modules"

EOF_SETUP

    # Replace placeholders in setup script
    sed -i.bak "s/{{CLOUD_PROVIDER}}/$cloud_provider/g" "$SETUP_SCRIPT"
    sed -i.bak "s/{{CLOUD_DISPLAY}}/$CLOUD_DISPLAY/g" "$SETUP_SCRIPT"
    rm "$SETUP_SCRIPT.bak"
    chmod +x "$SETUP_SCRIPT"
    
    echo "✅ Created setup script: $SETUP_SCRIPT"
    
    echo ""
    echo "🎉 Project Template Created Successfully!"
    echo "========================================"
    echo "📁 Template: $TEMPLATE_CONFIG"
    echo "🔧 Setup Script: $SETUP_SCRIPT"
    echo ""
    echo "🚀 To apply this template to a new repository:"
    echo "   $0 apply-template $cloud_provider <owner> <repo>"
}

# Apply project template to repository
apply_project_template() {
    local cloud_provider="$1"
    local repo_owner="$2"
    local repo_name="$3"
    
    configure_cloud_provider "$cloud_provider"
    
    echo "$CLOUD_EMOJI Applying $CLOUD_DISPLAY Project Template"
    echo "=============================================="
    echo "📁 Repository: $repo_owner/$repo_name"
    
    TEMPLATE_DIR="./github-project-templates"
    SETUP_SCRIPT="$TEMPLATE_DIR/setup-${cloud_provider}-project.sh"
    
    if [[ ! -f "$SETUP_SCRIPT" ]]; then
        echo "❌ Template setup script not found: $SETUP_SCRIPT"
        echo "💡 Run: $0 create-template $cloud_provider"
        exit 1
    fi
    
    echo "🚀 Executing template setup..."
    cd "$TEMPLATE_DIR"
    ./setup-${cloud_provider}-project.sh "$repo_owner" "$repo_name"
    cd ..
    
    echo ""
    echo "✅ Template applied successfully!"
    echo "📋 $CLOUD_DISPLAY InfraWeave project is ready for development"
}

# List available templates
list_templates() {
    echo "📋 Available GitHub Project Templates"
    echo "===================================="
    
    TEMPLATE_DIR="./github-project-templates"
    
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
        echo "❌ No templates found. Create templates first."
        echo "💡 Run: $0 create-template <cloud_provider>"
        return
    fi
    
    echo ""
    for template_file in "$TEMPLATE_DIR"/*-infraweave-template.json; do
        if [[ -f "$template_file" ]]; then
            cloud_provider=$(basename "$template_file" | cut -d'-' -f1)
            configure_cloud_provider "$cloud_provider"
            
            echo "$CLOUD_EMOJI $CLOUD_DISPLAY InfraWeave Template"
            echo "   Template: $(basename "$template_file")"
            echo "   Setup: setup-${cloud_provider}-project.sh"
            echo ""
        fi
    done
}

# Main execution
case "$ACTION" in
    "create-template")
        if [[ -z "$CLOUD_PROVIDER" ]]; then
            echo "❌ Cloud provider required for create-template"
            exit 1
        fi
        create_project_template "$CLOUD_PROVIDER"
        ;;
    "apply-template")
        if [[ -z "$CLOUD_PROVIDER" || -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
            echo "❌ Cloud provider, repo owner, and repo name required for apply-template"
            exit 1
        fi
        apply_project_template "$CLOUD_PROVIDER" "$REPO_OWNER" "$REPO_NAME"
        ;;
    "list-templates")
        list_templates
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Available actions: create-template, apply-template, list-templates"
        exit 1
        ;;
esac
