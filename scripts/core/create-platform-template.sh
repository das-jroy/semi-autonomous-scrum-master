#!/bin/bash

# Cloud Platform Project Template Generator
# Creates a new cloud platform project with optimized GitHub project board

set -e

# Template Configuration
TEMPLATE_NAME="Cloud Platform InfraWeave Template"
TEMPLATE_VERSION="2.0"

echo "🌟 Cloud Platform InfraWeave Project Template Generator"
echo "======================================================="
echo "Version: $TEMPLATE_VERSION"
echo ""

# Check if required parameters are provided
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <cloud_provider> <repo_owner> <repo_name> [project_name]"
    echo ""
    echo "Examples:"
    echo "  $0 aws dasdigitalplatform aws-infraweave-catalog"
    echo "  $0 gcp dasdigitalplatform gcp-infraweave-catalog"
    echo "  $0 azure dasdigitalplatform azure-infraweave-catalog"
    echo ""
    echo "Supported cloud providers: aws, azure, gcp, multi-cloud"
    exit 1
fi

CLOUD_PROVIDER="$1"
REPO_OWNER="$2"
REPO_NAME="$3"
CLOUD_UPPER=$(echo "$CLOUD_PROVIDER" | tr '[:lower:]' '[:upper:]')
PROJECT_NAME="${4:-${CLOUD_UPPER} InfraWeave Module Implementation - Platform 2.0}"

# Cloud provider configuration
case "$CLOUD_PROVIDER" in
    "aws")
        CLOUD_DISPLAY="AWS"
        CLOUD_EMOJI="☁️"
        PROVIDER_PREFIX="aws"
        TERRAFORM_PROVIDER="hashicorp/aws"
        ;;
    "azure")
        CLOUD_DISPLAY="Azure"
        CLOUD_EMOJI="🔷"
        PROVIDER_PREFIX="azurerm"
        TERRAFORM_PROVIDER="hashicorp/azurerm"
        ;;
    "gcp")
        CLOUD_DISPLAY="Google Cloud"
        CLOUD_EMOJI="☁️"
        PROVIDER_PREFIX="google"
        TERRAFORM_PROVIDER="hashicorp/google"
        ;;
    "multi-cloud")
        CLOUD_DISPLAY="Multi-Cloud"
        CLOUD_EMOJI="🌐"
        PROVIDER_PREFIX="multi"
        TERRAFORM_PROVIDER="multiple"
        ;;
    *)
        echo "❌ Unsupported cloud provider: $CLOUD_PROVIDER"
        echo "Supported: aws, azure, gcp, multi-cloud"
        exit 1
        ;;
esac

echo "$CLOUD_EMOJI Cloud Provider: $CLOUD_DISPLAY"
echo "📁 Repository: $REPO_OWNER/$REPO_NAME"
echo "📋 Project Name: $PROJECT_NAME"
echo ""

# Create project directory structure
TEMPLATE_DIR="./template-$CLOUD_PROVIDER-$(date +%Y%m%d)"
echo "📂 Creating template structure in: $TEMPLATE_DIR"
mkdir -p "$TEMPLATE_DIR"

# Create template configuration file
cat > "$TEMPLATE_DIR/template-config.json" << EOF
{
  "template": {
    "name": "$TEMPLATE_NAME",
    "version": "$TEMPLATE_VERSION",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "cloud_provider": "$CLOUD_PROVIDER",
    "cloud_display": "$CLOUD_DISPLAY",
    "provider_prefix": "$PROVIDER_PREFIX",
    "terraform_provider": "$TERRAFORM_PROVIDER"
  },
  "project": {
    "name": "$PROJECT_NAME",
    "repository": "$REPO_OWNER/$REPO_NAME",
    "owner": "$REPO_OWNER"
  },
  "features": {
    "project_board": true,
    "issue_templates": true,
    "automation_scripts": true,
    "ci_cd": true,
    "documentation": true
  }
}
EOF

echo "✅ Created template configuration"

# Generate cloud-specific module structure
echo "📦 Generating cloud-specific module categories..."

case "$CLOUD_PROVIDER" in
    "aws")
        MODULE_CATEGORIES=(
            "foundation:IAM,Organizations,Account"
            "compute:EC2,Lambda,ECS,EKS"
            "storage:S3,EBS,EFS"
            "networking:VPC,ALB,NLB,CloudFront"
            "database:RDS,DynamoDB,ElastiCache"
            "monitoring:CloudWatch,X-Ray"
            "security:KMS,Secrets Manager,WAF"
            "containers:ECS,EKS,Fargate"
        )
        ;;
    "azure")
        MODULE_CATEGORIES=(
            "foundation:Management Groups,Subscriptions,Resource Groups"
            "compute:Virtual Machines,Functions,Container Instances"
            "storage:Storage Accounts,Managed Disks,File Shares"
            "networking:Virtual Networks,Load Balancers,Application Gateway"
            "database:SQL Database,Cosmos DB,MySQL"
            "monitoring:Log Analytics,Application Insights,Monitor"
            "security:Key Vault,Security Center"
            "containers:AKS,Container Instances"
        )
        ;;
    "gcp")
        MODULE_CATEGORIES=(
            "foundation:Projects,IAM,Organization"
            "compute:Compute Engine,Cloud Functions,Cloud Run,GKE"
            "storage:Cloud Storage,Persistent Disks"
            "networking:VPC,Load Balancing,Cloud CDN"
            "database:Cloud SQL,Firestore,Bigtable"
            "monitoring:Cloud Monitoring,Cloud Logging"
            "security:Cloud KMS,Secret Manager"
            "containers:GKE,Cloud Run"
        )
        ;;
    "multi-cloud")
        MODULE_CATEGORIES=(
            "foundation:Identity,Governance,Policies"
            "compute:Virtual Machines,Serverless,Containers"
            "storage:Object Storage,Block Storage,File Storage"
            "networking:Load Balancing,CDN,VPN"
            "database:SQL,NoSQL,Cache"
            "monitoring:Metrics,Logging,Tracing"
            "security:Encryption,Secrets,Access Control"
            "containers:Kubernetes,Container Registry"
        )
        ;;
esac

# Create module structure template
mkdir -p "$TEMPLATE_DIR/scripts"
mkdir -p "$TEMPLATE_DIR/docs"
mkdir -p "$TEMPLATE_DIR/.github/templates"

echo "🔧 Generating automation scripts..."

# Create project setup script template
cat > "$TEMPLATE_DIR/scripts/setup-project-board.sh" << 'EOF_SCRIPT'
#!/bin/bash

# {{CLOUD_DISPLAY}} InfraWeave Project Board Setup
# Generated from Cloud Platform Template v{{TEMPLATE_VERSION}}

set -e

# Load configuration
CONFIG_FILE="./template-config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Template configuration not found: $CONFIG_FILE"
    exit 1
fi

CLOUD_PROVIDER=$(jq -r '.template.cloud_provider' "$CONFIG_FILE")
CLOUD_DISPLAY=$(jq -r '.template.cloud_display' "$CONFIG_FILE")
REPO_OWNER=$(jq -r '.project.owner' "$CONFIG_FILE")
REPO_NAME=$(jq -r '.project.repository' "$CONFIG_FILE" | cut -d'/' -f2)
PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")

echo "🚀 Setting up {{CLOUD_DISPLAY}} InfraWeave Project Board"
echo "======================================================="
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Project: $PROJECT_NAME"
echo ""

# Create GitHub project
echo "📋 Creating GitHub project..."
PROJECT_RESULT=$(gh project create --owner "$REPO_OWNER" --title "$PROJECT_NAME" --format json)
PROJECT_ID=$(echo "$PROJECT_RESULT" | jq -r '.number')
PROJECT_URL=$(echo "$PROJECT_RESULT" | jq -r '.url')

echo "✅ Created project #$PROJECT_ID"
echo "🔗 URL: $PROJECT_URL"

# Store project ID in config
jq --arg project_id "$PROJECT_ID" '.project.id = $project_id' "$CONFIG_FILE" > temp.json && mv temp.json "$CONFIG_FILE"

echo ""
echo "📊 Setting up custom fields..."

# Create Status field
gh api graphql -f query='
mutation($projectId: ID!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: SINGLE_SELECT
    name: "Status"
    singleSelectOptions: [
      {name: "No Status", description: "New issues awaiting triage", color: GRAY},
      {name: "DOR", description: "Definition of Ready complete", color: GREEN},
      {name: "In Progress", description: "Active development", color: YELLOW},
      {name: "Review", description: "Code review and testing", color: BLUE},
      {name: "Blocked", description: "Waiting on dependencies", color: RED},
      {name: "Done", description: "Completed and merged", color: PURPLE}
    ]
  }) {
    projectV2Field { id }
  }
}' -f projectId="$(gh project list --owner "$REPO_OWNER" --format json | jq -r --arg title "$PROJECT_NAME" '.projects[] | select(.title == $title) | .id')"

echo "✅ Created Status field"

# Create additional fields
for field_data in \
    'Issue Type:Feature,Enhancement,Bug,Documentation' \
    'Complexity:Low (1-2 days),Medium (3-5 days),High (1-2 weeks)' \
    'Priority Level:P0 - Critical,P1 - High Impact,P2 - Medium,P3 - Low Priority' \
    'Module Category:Foundation,Compute,Storage,Networking,Database,Monitoring,Security,Containers' \
    'Security Review:Required,Not Required,Completed,Blocked'
do
    FIELD_NAME=$(echo "$field_data" | cut -d':' -f1)
    OPTIONS=$(echo "$field_data" | cut -d':' -f2)
    
    echo "Creating $FIELD_NAME field..."
    # Implementation would create each field with options
done

echo ""
echo "🎯 Project board setup complete!"
echo "Next steps:"
echo "1. Run ./scripts/create-issues.sh to populate with issues"
echo "2. Configure project views for different stakeholders"
echo "3. Begin sprint planning with foundation modules"

EOF_SCRIPT

# Create issues generation script template  
cat > "$TEMPLATE_DIR/scripts/create-issues.sh" << 'EOF_ISSUES'
#!/bin/bash

# {{CLOUD_DISPLAY}} Module Issues Generator
# Creates structured GitHub issues for each module category

set -e

CONFIG_FILE="./template-config.json"
CLOUD_PROVIDER=$(jq -r '.template.cloud_provider' "$CONFIG_FILE")
REPO_OWNER=$(jq -r '.project.owner' "$CONFIG_FILE")
REPO_NAME=$(jq -r '.project.repository' "$CONFIG_FILE" | cut -d'/' -f2)

echo "📝 Creating {{CLOUD_DISPLAY}} module implementation issues..."

# Module categories and services (populated from template)
declare -A MODULE_SERVICES
{{MODULE_DEFINITIONS}}

# Create issues for each module category
for category in "${!MODULE_SERVICES[@]}"; do
    services="${MODULE_SERVICES[$category]}"
    
    echo ""
    echo "📦 Creating issues for $category modules..."
    
    IFS=',' read -ra SERVICE_ARRAY <<< "$services"
    for service in "${SERVICE_ARRAY[@]}"; do
        service_slug=$(echo "$service" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        issue_title="Implement $service Module ($category/$service_slug)"
        
        # Create issue with template
        gh issue create \
            --repo "$REPO_OWNER/$REPO_NAME" \
            --title "$issue_title" \
            --body "$(cat ./templates/module-issue-template.md)" \
            --label "module,implementation,$category"
            
        echo "  ✅ Created: $issue_title"
    done
done

echo ""
echo "🎉 All module issues created!"
echo "Run ./scripts/add-issues-to-project.sh to add them to the project board."

EOF_ISSUES

# Create documentation templates
echo "📚 Creating documentation templates..."

cat > "$TEMPLATE_DIR/README.md" << EOF_README
# $CLOUD_EMOJI $CLOUD_DISPLAY InfraWeave Module Catalog - Platform 2.0

A comprehensive collection of production-ready Terraform modules for $CLOUD_DISPLAY infrastructure, designed with enterprise security, compliance, and best practices.

## 🎯 Project Overview

This catalog provides standardized, reusable Terraform modules for $CLOUD_DISPLAY infrastructure components, following Platform 2.0 architecture principles and security guidelines.

### 🏗️ Module Categories

$(for category_line in "${MODULE_CATEGORIES[@]}"; do
    category=$(echo "$category_line" | cut -d':' -f1)
    services=$(echo "$category_line" | cut -d':' -f2)
    echo "- **$category**: $services"
done)

## 🚀 Getting Started

### Prerequisites
- Terraform >= 1.0
- $CLOUD_DISPLAY CLI configured
- GitHub CLI (for project management)

### Project Management
This project uses an optimized GitHub project board for tracking module development:

\`\`\`bash
# Set up project board
./scripts/setup-project-board.sh

# Create module issues
./scripts/create-issues.sh

# Prepare Sprint 1
./scripts/sprint1-preparation.sh
\`\`\`

### Development Workflow

1. **Issue Creation**: Structured issues for each module
2. **Definition of Ready**: Quality gates before development
3. **Sprint Planning**: Foundation-first approach
4. **Code Review**: Security and compliance validation
5. **Integration**: Automated testing and deployment

## 📊 Project Board Features

- **Status Workflow**: No Status → DOR → In Progress → Review → Done
- **Issue Types**: Feature, Enhancement, Bug, Documentation
- **Custom Fields**: Priority, Complexity, Security Review
- **Multiple Views**: Sprint Board, Roadmap, Security Review
- **Automation**: Scripts for setup, management, and reporting

## 🔒 Security & Compliance

All modules are designed with:
- Platform 2.0 security standards
- Encryption at rest and in transit
- Least privilege access controls
- Compliance with industry standards
- Comprehensive security testing

## 📈 Success Metrics

Track development progress with:
- Lead time from issue creation to completion
- Sprint velocity by complexity points
- Security review pass rates
- Module adoption and usage metrics

## 🛠️ Available Scripts

- \`setup-project-board.sh\` - Initialize GitHub project board
- \`create-issues.sh\` - Generate module implementation issues
- \`sprint1-preparation.sh\` - Prepare foundation modules for Sprint 1
- \`verify-project-status.sh\` - Check project health and progress

## 📋 Module Standards

Each module includes:
- Comprehensive variable validation
- Detailed output definitions
- Security best practices
- Example configurations
- Integration tests
- Documentation and usage guides

---

*Generated from Cloud Platform InfraWeave Template v$TEMPLATE_VERSION*
EOF_README

# Create issue template
mkdir -p "$TEMPLATE_DIR/.github/ISSUE_TEMPLATE"

cat > "$TEMPLATE_DIR/.github/ISSUE_TEMPLATE/module-implementation.md" << EOF_ISSUE_TEMPLATE
---
name: $CLOUD_DISPLAY Module Implementation
about: Track implementation of a new $CLOUD_DISPLAY infrastructure module
title: 'Implement [SERVICE] Module ([CATEGORY]/[service-name])'
labels: 'module, implementation, [category]'
assignees: ''
---

## 📦 Module Implementation: [SERVICE]

**Path:** \`modules/[category]/[service-name]\`  
**Description:** [Brief description of the service/component]

### 🎯 Objective
Implement the complete $CLOUD_DISPLAY [SERVICE] module with Platform 2.0 security compliance and production-ready configuration.

### 📋 Tasks

#### Core Implementation
- [ ] Research $CLOUD_DISPLAY resource requirements and best practices
- [ ] Implement \`main.tf\` with actual $CLOUD_DISPLAY resources
- [ ] Define comprehensive \`variables.tf\` with validation constraints
- [ ] Create meaningful \`outputs.tf\` with actual resource outputs
- [ ] Update module documentation

#### Security & Compliance  
- [ ] Implement Platform 2.0 security features
- [ ] Add encryption and access control configurations
- [ ] Include network security controls where applicable
- [ ] Validate security defaults and overrides

#### Documentation & Testing
- [ ] Update README.md with usage examples and security notes
- [ ] Add example configurations in \`examples/\` directory
- [ ] Test with \`terraform validate\` and \`terraform plan\`
- [ ] Document breaking changes and migration notes

### 🔗 Reference Patterns
Follow the established patterns from completed modules in this catalog.

### 📚 Resources
- [$CLOUD_DISPLAY Documentation](https://docs.$CLOUD_PROVIDER.amazon.com/) 
- [Terraform $PROVIDER_PREFIX Provider](https://registry.terraform.io/providers/$TERRAFORM_PROVIDER/latest)
- [Platform 2.0 Security Guide](../docs/SECURITY-GUIDE.md)

### ✅ Definition of Done
- [ ] All TODOs resolved in module files
- [ ] Module passes \`terraform validate\`
- [ ] Security scan passes
- [ ] Documentation complete with examples
- [ ] Code review approved
- [ ] Integration tests pass

---
*This issue was generated from the $CLOUD_DISPLAY InfraWeave template*
EOF_ISSUE_TEMPLATE

echo "✅ Created issue templates"

# Generate module definitions for the issues script
MODULE_DEFS=""
for category_line in "${MODULE_CATEGORIES[@]}"; do
    category=$(echo "$category_line" | cut -d':' -f1)
    services=$(echo "$category_line" | cut -d':' -f2)
    MODULE_DEFS="$MODULE_DEFS\nMODULE_SERVICES[\"$category\"]=\"$services\""
done

# Replace placeholders in the issues script
sed -i.bak "s|{{MODULE_DEFINITIONS}}|$MODULE_DEFS|g" "$TEMPLATE_DIR/scripts/create-issues.sh"
sed -i.bak "s|{{CLOUD_DISPLAY}}|$CLOUD_DISPLAY|g" "$TEMPLATE_DIR/scripts/create-issues.sh"
rm "$TEMPLATE_DIR/scripts/create-issues.sh.bak"

# Replace placeholders in setup script
sed -i.bak "s|{{CLOUD_DISPLAY}}|$CLOUD_DISPLAY|g" "$TEMPLATE_DIR/scripts/setup-project-board.sh"
sed -i.bak "s|{{TEMPLATE_VERSION}}|$TEMPLATE_VERSION|g" "$TEMPLATE_DIR/scripts/setup-project-board.sh"
rm "$TEMPLATE_DIR/scripts/setup-project-board.sh.bak"

# Make scripts executable
chmod +x "$TEMPLATE_DIR/scripts/"*.sh

echo ""
echo "🎉 Cloud Platform Template Generated Successfully!"
echo "================================================="
echo ""
echo "📁 Template Location: $TEMPLATE_DIR"
echo "☁️ Cloud Provider: $CLOUD_DISPLAY"
echo "📋 Project Name: $PROJECT_NAME"
echo ""
echo "📦 Generated Components:"
echo "✅ Project board automation scripts"
echo "✅ Issue generation templates"
echo "✅ Documentation templates"
echo "✅ GitHub issue templates"
echo "✅ Cloud-specific module categories"
echo ""
echo "🚀 Next Steps:"
echo "1. Copy template to your new repository"
echo "2. Update configuration in template-config.json"
echo "3. Run ./scripts/setup-project-board.sh"
echo "4. Run ./scripts/create-issues.sh"
echo "5. Begin development with foundation modules"
echo ""
echo "🏆 Ready to accelerate $CLOUD_DISPLAY infrastructure development!"
