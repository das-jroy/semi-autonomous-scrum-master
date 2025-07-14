#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config

# Implementation Checklist for High-Value Fields
# Quick verification and guidance script

echo "🎯 HIGH-VALUE FIELDS IMPLEMENTATION CHECKLIST"
echo "============================================="
echo ""

# Configuration
# REPO_OWNER loaded from config
# REPO_NAME loaded from config
PROJECT_NUMBER="3"
# Construct project URL dynamically
if [[ -n "$PROJECT_ID" ]]; then
    PROJECT_URL="https://github.com/orgs/$REPO_OWNER/projects/${PROJECT_ID}"
else
    PROJECT_URL="https://github.com/$REPO_OWNER/$REPO_NAME/projects"
fi

echo "📋 PROJECT: $PROJECT_NAME"
echo "🔗 URL: $PROJECT_URL"
echo ""

echo "✅ PHASE 1 IMPLEMENTATION CHECKLIST:"
echo "===================================="
echo ""

# Check if we can access the project
if gh auth status >/dev/null 2>&1; then
    echo "🔍 Checking current project status..."
    
    # Try to get field information
    FIELD_CHECK=$(gh api graphql -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        projectV2(number: $number) {
          fields(first: 20) {
            nodes {
              ... on ProjectV2Field {
                name
                dataType
              }
              ... on ProjectV2SingleSelectField {
                name
                dataType
                options {
                  name
                }
              }
            }
          }
        }
      }
    }' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F number="$PROJECT_NUMBER" 2>/dev/null || echo "null")
    
    if [ "$FIELD_CHECK" != "null" ]; then
        # Check for Type field
        TYPE_EXISTS=$(echo "$FIELD_CHECK" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Type") | .name' 2>/dev/null)
        
        if [ "$TYPE_EXISTS" = "Type" ]; then
            echo "✅ 1. Type field created"
            TYPE_OPTIONS=$(echo "$FIELD_CHECK" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Type") | .options[]?.name // empty' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
            if [ -n "$TYPE_OPTIONS" ]; then
                echo "   Options: $TYPE_OPTIONS"
            fi
        else
            echo "❌ 1. Type field needs creation"
            echo "   📝 Action: Go to $PROJECT_URL and add Type field"
        fi
        
        # Check Status field options
        STATUS_OPTIONS=$(echo "$FIELD_CHECK" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Status") | .options[]?.name // empty' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
        if [[ "$STATUS_OPTIONS" == *"DOR"* ]]; then
            echo "✅ 2. Status field has DOR option"
            echo "   Options: $STATUS_OPTIONS"
        else
            echo "⚠️  2. Status field exists but may need DOR integration"
            echo "   Current: $STATUS_OPTIONS"
        fi
        
        # Check Milestone
        MILESTONE_EXISTS=$(echo "$FIELD_CHECK" | jq -r '.data.repository.projectV2.fields.nodes[] | select(.name == "Milestone") | .name' 2>/dev/null)
        if [ "$MILESTONE_EXISTS" = "Milestone" ]; then
            echo "✅ 3. Milestone field available"
        else
            echo "❌ 3. Milestone field missing"
        fi
        
    else
        echo "ℹ️  Unable to check field status automatically"
    fi
else
    echo "ℹ️  GitHub CLI not authenticated - showing manual checklist"
fi

echo ""
echo "📝 MANUAL IMPLEMENTATION STEPS:"
echo "==============================="
echo ""

echo "□ Step 1: Create Type Field"
echo "  1. Go to $PROJECT_URL"
echo "  2. Click '+ Field' button"
echo "  3. Choose 'Single select'"
echo "  4. Name: 'Type'"
echo "  5. Add options:"
echo "     • Feature"
echo "     • Bug Fix"
echo "     • Enhancement"
echo "     • Documentation"
echo "     • Infrastructure"
echo "     • Epic"
echo ""

echo "□ Step 2: Verify Status Field for DOR"
echo "  1. Check existing Status field options"
echo "  2. Ensure 'DOR' or 'Ready (DOR)' option exists"
echo "  3. Consider workflow: Draft → Ready (DOR) → In Progress → Review → Done"
echo ""

echo "□ Step 3: Set Default Values (Bulk Edit)"
echo "  1. Select multiple issues in project view"
echo "  2. Use bulk edit to set Type field:"
echo "     • Issues with 'Bug' → Bug Fix"
echo "     • Issues with 'Doc' → Documentation"
echo "     • Issues with 'Infrastructure' → Infrastructure"
echo "     • Everything else → Feature"
echo "  3. Review Status values for DOR compliance"
echo ""

echo "□ Step 4: Create Enhanced Views"
echo "  1. DOR Compliance View (filter by Status)"
echo "  2. Type Breakdown View (group by Type)"
echo "  3. Milestone Progress View (group by Milestone)"
echo "  4. Sprint Board with DOR workflow"
echo ""

echo "□ Step 5: Team Training on DOR Process"
echo "  Before moving to 'Ready (DOR)', ensure:"
echo "  • Requirements clearly defined"
echo "  • Acceptance criteria specified"
echo "  • Dependencies identified"
echo "  • Technical approach outlined"
echo "  • Test scenarios defined"
echo "  • Security requirements reviewed"
echo ""

echo "🎯 EXPECTED OUTCOMES:"
echo "===================="
echo "• Better sprint planning with Type categorization"
echo "• Improved quality with DOR compliance"
echo "• Enhanced metrics and reporting capabilities"
echo "• Clearer workflow visibility for stakeholders"
echo "• Foundation for continuous improvement"
echo ""

echo "📊 SUCCESS METRICS TO TRACK:"
echo "==========================="
echo "• % of issues meeting DOR before sprint start"
echo "• Velocity by work type (features vs bugs)"
echo "• Sprint predictability improvement"
echo "• Reduction in mid-sprint scope changes"
echo "• Time to resolve by issue type"
echo ""

echo "🎉 COMPLETION:"
echo "=============="
echo "Once all steps are complete, you'll have:"
echo "• Enterprise-level project tracking"
echo "• Data-driven sprint planning"
echo "• Quality gates with DOR enforcement"
echo "• Comprehensive project visibility"
echo ""

echo "💡 Remember: Focus on the high-value fields first!"
echo "Type field creation will give you the biggest immediate impact."
echo ""

read -p "Would you like to open the project in your browser to start implementation? [y/N]: " open_browser

if [[ $open_browser =~ ^[Yy]$ ]]; then
    echo "🌐 Opening project in browser..."
    if command -v open >/dev/null 2>&1; then
        open "$PROJECT_URL"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$PROJECT_URL"
    else
        echo "Please manually navigate to: $PROJECT_URL"
    fi
fi

echo ""
echo "✅ Implementation checklist ready!"
echo "📁 See also: FIELD-VALUE-ASSESSMENT.md for detailed analysis"
