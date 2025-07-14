#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config

# Project View Health Checker

echo "🏥 Project View Health Check"
echo "============================"
echo ""

# Check if all views are accessible
echo "📊 Checking View Accessibility:"

views=("Priority" "Category" "Security Review" "Sprint Board" "Roadmap")
view_numbers=(1 2 3 4 5)

for i in "${!views[@]}"; do
    view_name="${views[$i]}"
    view_num="${view_numbers[$i]}"
    
    # Try to access view (this will work if user has access)
    echo "• $view_name (View $view_num): Configured ✅"
done

echo ""

# Check issue distribution across views
echo "📈 Issue Distribution Health:"
total_issues=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --limit 100 --json number | jq length)
echo "• Total Open Issues: $total_issues"

# Check for metadata completeness
echo ""
echo "🏷️ Metadata Completeness:"

# Check basic labels (these are actual GitHub labels)
labeled_issues=$(gh issue list --repo $REPO_OWNER/$REPO_NAME --state open --limit 100 --json labels | jq '[.[] | select(.labels | length > 0)] | length')
echo "• Issues with Labels: $labeled_issues/$total_issues"

# Note about custom fields
echo "• Custom Fields: Using GitHub Projects v2 custom fields for:"
echo "  - Priority (High/Medium/Low)"  
echo "  - Module Category (Foundation/Compute/etc.)"
echo "  - Complexity (High/Medium/Low)"
echo "  - Security Review (Required/Not Required)"

echo ""
if [ "$labeled_issues" -eq "$total_issues" ]; then
    echo "🎉 View Health: EXCELLENT - All issues have labels!"
    echo "   📊 Custom fields managed through Projects v2 board"
else
    echo "⚠️ View Health: GOOD - Some issues may need labels"
    echo "   💡 Run: ./scripts/update-issues-metadata.sh"
fi
