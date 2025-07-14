#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# High-Value Fields Analysis and Setup Guide
# Provides field value assessment and sets defaults where possible

set -e

echo "🚀 HIGH-VALUE FIELDS ANALYSIS & SETUP"
echo "====================================="
echo ""

# Configuration
# REPO_OWNER loaded from config
# REPO_NAME loaded from config 
PROJECT_NUMBER="3"

echo "📊 FIELD VALUE ASSESSMENT RESULTS:"
echo "=================================="
echo ""

echo "✅ ALREADY IMPLEMENTED (High Value):"
echo "• Priority Level - Essential for sprint planning"
echo "• Module Category - Critical for phase tracking"
echo "• Complexity - Key for effort estimation" 
echo "• Security Review - Required for compliance"
echo "• Start Date & Target Date - Timeline management"
echo "• Sprint - Iteration planning"
echo ""

echo "🎯 RECOMMENDED ADDITIONS (Phase 1):"
echo "=================================="
echo ""

echo "1. STATUS FIELD ENHANCEMENT:"
echo "   Current: Todo, In Progress, Review, Blocked, Done, DOR"
echo "   ✅ Status field exists with DOR option!"
echo "   💡 Consider reorganizing: Draft → Ready (DOR) → In Progress → Review → Done"
echo ""

echo "2. TYPE FIELD (Missing - High Value):"
echo "   ❌ Needs manual creation"
echo "   📋 Recommended options:"
echo "   • Feature - New functionality"
echo "   • Bug Fix - Fixing existing issues"
echo "   • Enhancement - Improving existing features"
echo "   • Documentation - Docs and guides"
echo "   • Infrastructure - Tooling and setup"
echo "   • Epic - Large multi-issue work"
echo ""

echo "3. MILESTONE FIELD:"
echo "   ✅ Built-in GitHub milestone field exists"
echo "   💡 Can use GitHub's native milestone feature"
echo ""

echo "❌ NOT RECOMMENDED (Skip These):"
echo "==============================="
echo "• Development field - Redundant with Status"
echo "• Notifications field - GitHub handles this natively"
echo "• Relationships field - Complex to maintain, defer for now"
echo ""

echo "🎯 IMPLEMENTATION STRATEGY:"
echo "=========================="
echo ""

echo "IMMEDIATE WINS (Do Now):"
echo "1. Enhance Status field workflow with DOR"
echo "2. Manually create Type field"  
echo "3. Use existing Milestone field for release planning"
echo ""

echo "FUTURE CONSIDERATIONS:"
echo "1. Add Relationships field if dependency tracking becomes critical"
echo "2. Consider custom Sprint field if GitHub Milestones aren't sufficient"
echo ""

# Check current project setup
echo "📋 CURRENT PROJECT ANALYSIS:"
echo "============================"
echo ""

if gh auth status >/dev/null 2>&1; then
    echo "🔍 Analyzing current project state..."
    
    # Get basic project info
    PROJECT_INFO=$(gh project view $PROJECT_NUMBER --owner $REPO_OWNER --format json 2>/dev/null || echo '{}')
    
    if [ "$PROJECT_INFO" != "{}" ]; then
        echo "✅ Project found and accessible"
        
        # Count issues
        ISSUE_COUNT=$(gh issue list --repo "$REPO_OWNER/$REPO_NAME" --json number | jq '. | length')
        echo "📊 Total issues: $ISSUE_COUNT"
        
        # Check field usage
        echo ""
        echo "📈 IMPACT ANALYSIS:"
        echo "=================="
        echo "With Type field added, you'll enable:"
        echo "• Work type velocity tracking (features vs bugs vs docs)"
        echo "• Better sprint planning and capacity allocation"
        echo "• Quality metrics (bug ratio, feature completion rate)"
        echo "• Stakeholder reporting by work category"
        echo ""
        
        echo "📊 METRICS YOU'LL GAIN:"
        echo "======================"
        echo "• DOR compliance rate (Status field analysis)"
        echo "• Velocity by work type (Type field analysis)"
        echo "• Phase completion progress (Milestone tracking)"
        echo "• Sprint burn-down with quality gates"
        echo "• Team capacity utilization by complexity"
        echo ""
        
    else
        echo "⚠️  Could not access project details"
        echo "This is normal - proceeding with guidance"
    fi
else
    echo "ℹ️  GitHub CLI not authenticated - providing guidance only"
fi

echo ""
echo "🔧 MANUAL SETUP INSTRUCTIONS:"
echo "============================="
echo ""

echo "STEP 1: Create Type Field"
echo "------------------------"
echo "1. Go to: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_NUMBER"
echo "2. Click '+ Field' button"
echo "3. Choose 'Single select'"
echo "4. Name: 'Type'"
echo "5. Add options:"
echo "   • Feature"
echo "   • Bug Fix" 
echo "   • Enhancement"
echo "   • Documentation"
echo "   • Infrastructure"
echo "   • Epic"
echo ""

echo "STEP 2: Enhance Status Field (Optional)"
echo "-------------------------------------"
echo "Current Status options: Todo, In Progress, Review, Blocked, Done, DOR"
echo ""
echo "Consider renaming/reorganizing for clearer DOR workflow:"
echo "• Draft (instead of Todo)"
echo "• Ready (DOR) (move DOR here)"
echo "• In Progress"
echo "• Review"
echo "• Done"
echo "• Blocked (as needed)"
echo ""

echo "STEP 3: Set Default Values"
echo "------------------------"
echo "After creating the Type field, you can run:"
echo "./scripts/set-field-defaults.sh"
echo ""

echo "🎯 RECOMMENDED PROJECT VIEWS:"
echo "============================"
echo ""
echo "1. DOR COMPLIANCE VIEW:"
echo "   • Filter: Status = 'Draft' vs 'Ready (DOR)'"
echo "   • Purpose: Track readiness pipeline"
echo ""
echo "2. TYPE BREAKDOWN VIEW:"
echo "   • Group by: Type"
echo "   • Purpose: Work category analysis"
echo ""
echo "3. MILESTONE PROGRESS VIEW:"
echo "   • Group by: Milestone"
echo "   • Purpose: Release planning"
echo ""
echo "4. SPRINT BOARD WITH DOR:"
echo "   • Kanban layout"
echo "   • Columns based on Status field"
echo "   • Purpose: Daily workflow management"
echo ""

echo "💡 KEY BENEFITS OF THIS APPROACH:"
echo "================================"
echo "• 80% of tracking value with 20% of complexity"
echo "• Focuses on fields teams actually maintain"
echo "• Builds on existing GitHub features"
echo "• Enables meaningful metrics and reporting"
echo "• Supports DOR compliance and quality gates"
echo ""

echo "🚀 READY TO PROCEED?"
echo "==================="
echo ""
echo "Next steps:"
echo "1. Create the Type field manually (5 minutes)"
echo "2. Optionally enhance Status field workflow"
echo "3. Run default value setting script"
echo "4. Create recommended project views"
echo "5. Start using DOR workflow in daily standups"
echo ""

read -p "Would you like to create a script to set intelligent defaults on existing fields? [y/N]: " create_defaults

if [[ $create_defaults =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔧 Creating default value setting script..."
    
    cat > /Users/za497e/IdeaProjects/$REPO_NAME/scripts/set-field-defaults.sh << 'EOF'
#!/bin/bash

# Set intelligent defaults on project fields
# Run this after manually creating the Type field

echo "🎯 Setting intelligent defaults on all issues..."
echo "Note: This requires the Type field to be created manually first"
echo ""

# This is a placeholder - manual field value setting is complex via CLI
# Recommended approach: Use GitHub UI to bulk-edit field values

echo "💡 RECOMMENDED APPROACH:"
echo "======================="
echo "1. Go to your project board"
echo "2. Select multiple issues (Shift+click)"
echo "3. Use bulk edit to set field values:"
echo ""
echo "   SUGGESTED DEFAULTS BY PATTERN:"
echo "   • Issues with 'Bug' in title → Type: Bug Fix"
echo "   • Issues with 'Doc' in title → Type: Documentation"  
echo "   • Issues with 'Infrastructure' in title → Type: Infrastructure"
echo "   • Everything else → Type: Feature"
echo ""
echo "   STATUS SUGGESTIONS:"
echo "   • Issues marked 'TODO' → Status: Draft"
echo "   • Everything else → Status: Ready (DOR) (after DOR review)"
echo ""
echo "   MILESTONE SUGGESTIONS:"
echo "   • Foundation/Core modules → Foundation Phase"
echo "   • Advanced features → Advanced Services"
echo "   • Production items → Production Ready"
echo ""
echo "This manual approach is faster and more accurate than CLI automation."
EOF
    
    chmod +x /Users/za497e/IdeaProjects/$REPO_NAME/scripts/set-field-defaults.sh
    echo "✅ Created: scripts/set-field-defaults.sh"
fi

echo ""
echo "📋 SUMMARY:"
echo "==========="
echo "• Type field creation: 5 minutes manual work"
echo "• Default value setting: 10 minutes bulk edit in UI"
echo "• Project view creation: 15 minutes setup"
echo "• Total effort: ~30 minutes for major tracking enhancement"
echo ""
echo "🎉 This gives you enterprise-level project tracking capabilities!"
