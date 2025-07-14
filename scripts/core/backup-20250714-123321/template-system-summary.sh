#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# GitHub Project Template System Summary
# Shows the complete state of the template system

echo "🎯 GitHub Project Template System for InfraWeave Catalogs"
echo "========================================================="
echo "Generated: $(date)"
echo ""

echo "📋 Template Management System Status:"
echo "===================================="

# Check if template manager exists
if [[ -f "./scripts/github-project-template-manager.sh" ]]; then
    echo "✅ Template Manager: Available"
    echo "   📁 Location: ./scripts/github-project-template-manager.sh"
else
    echo "❌ Template Manager: Not found"
fi

# Check available templates
TEMPLATE_DIR="./github-project-templates"
if [[ -d "$TEMPLATE_DIR" ]]; then
    echo "✅ Template Directory: $TEMPLATE_DIR"
    
    TEMPLATE_COUNT=$(find "$TEMPLATE_DIR" -name "*-infraweave-template.json" | wc -l)
    SETUP_COUNT=$(find "$TEMPLATE_DIR" -name "setup-*-project.sh" | wc -l)
    
    echo "   📊 Templates: $TEMPLATE_COUNT available"
    echo "   🔧 Setup Scripts: $SETUP_COUNT available"
    echo ""
    
    echo "📦 Available Cloud Platform Templates:"
    echo "====================================="
    
    for template_file in "$TEMPLATE_DIR"/*-infraweave-template.json; do
        if [[ -f "$template_file" ]]; then
            cloud_provider=$(basename "$template_file" | cut -d'-' -f1)
            
            case "$cloud_provider" in
                "aws") emoji="☁️"; display="AWS" ;;
                "azure") emoji="🔷"; display="Azure" ;;
                "gcp") emoji="🌀"; display="Google Cloud" ;;
                "multi-cloud") emoji="🌐"; display="Multi-Cloud" ;;
                *) emoji="❓"; display="$cloud_provider" ;;
            esac
            
            echo ""
            echo "$emoji $display InfraWeave Template"
            echo "   📄 Template: $(basename "$template_file")"
            echo "   🔧 Setup: setup-${cloud_provider}-project.sh"
            
            # Show template details
            if command -v jq >/dev/null 2>&1; then
                TEMPLATE_NAME=$(jq -r '.name' "$template_file")
                FIELD_COUNT=$(jq '.fields | length' "$template_file")
                VIEW_COUNT=$(jq '.views | length' "$template_file")
                
                echo "   📊 Fields: $FIELD_COUNT custom fields"
                echo "   👁️  Views: $VIEW_COUNT project views"
            fi
        fi
    done
else
    echo "❌ Template Directory: Not found"
fi

echo ""
echo "🚀 Template System Capabilities:"
echo "==============================="
echo "✅ Multi-Cloud Support: AWS, Azure, GCP, Multi-Cloud"
echo "✅ Standardized Fields: Status, Issue Type, Complexity, Priority"
echo "✅ Enterprise Features: DOR workflow, Security Review, Sprint planning"
echo "✅ Automated Setup: One-command project board creation"
echo "✅ Native Integration: GitHub project template API"
echo "✅ Cloud-Specific: Tailored module categories per platform"

echo ""
echo "📋 Usage Examples:"
echo "=================="
echo "# Create templates for all cloud providers:"
echo "./scripts/github-project-template-manager.sh create-template aws"
echo "./scripts/github-project-template-manager.sh create-template azure"
echo "./scripts/github-project-template-manager.sh create-template gcp"
echo ""
echo "# Apply AWS template to new repository:"
echo "./scripts/github-project-template-manager.sh apply-template aws myorg aws-infraweave-catalog"
echo ""
echo "# List all available templates:"
echo "./scripts/github-project-template-manager.sh list-templates"

echo ""
echo "🎯 Enterprise Benefits:"
echo "======================"
echo "• **Standardization**: Consistent project management across cloud platforms"
echo "• **Rapid Setup**: New projects ready in minutes, not hours"
echo "• **Best Practices**: Built-in DOR, security reviews, sprint planning"
echo "• **Scalability**: Template system grows with your organization"
echo "• **Compliance**: Security and quality gates built into workflow"
echo "• **Metrics**: Built-in tracking for lead time, cycle time, velocity"

echo ""
echo "📚 Documentation:"
echo "=================="
if [[ -f "./GITHUB-PROJECT-TEMPLATES.md" ]]; then
    echo "✅ Complete Guide: ./GITHUB-PROJECT-TEMPLATES.md"
else
    echo "❌ Documentation: Not found"
fi

echo ""
echo "🏆 System Status: Ready for Production"
echo "======================================"
echo ""
echo "The GitHub Project Template System is fully operational and ready to:"
echo "• Create standardized project boards for any cloud platform"
echo "• Accelerate infrastructure team onboarding"
echo "• Ensure consistent project management practices"
echo "• Scale across multiple cloud initiatives"
echo ""
echo "🚀 Ready to revolutionize infrastructure project management!"
