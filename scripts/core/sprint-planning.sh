#!/bin/bash
# Sprint Planning Helper

echo "🏃‍♂️ Sprint Planning Assistant"
echo "============================="
echo ""

# Get current roadmap status
echo "📊 Current Phase Status:"
./scripts/roadmap-status.sh | grep -A 20 "Development Phases"

echo ""
echo "🎯 Sprint Planning Recommendations:"
echo ""

# Check for high-priority items in Todo status
echo "High-Priority Items Ready for Sprint:"
echo ""

# List foundation modules (highest priority for Phase 1)
echo "🏗️ Foundation Modules (Phase 1 - Start Here):"
foundation_issues=$(gh issue list --repo dasdigitalplatform/vanguard-az-infraweave-catalog \
    --label "foundation" \
    --state open \
    --limit 5 \
    --json title,number --template '{{range .}}• #{{.number}}: {{.title}}{{"\n"}}{{end}}' | head -10)

if [ -n "$foundation_issues" ]; then
    echo "$foundation_issues"
else
    echo "• No foundation issues found - checking for any high-priority work"
fi

echo ""
echo "🖥️ Other Priority Modules:"
module_issues=$(gh issue list --repo dasdigitalplatform/vanguard-az-infraweave-catalog \
    --label "module" \
    --state open \
    --limit 3 \
    --json title,number --template '{{range .}}• #{{.number}}: {{.title}}{{"\n"}}{{end}}' | head -10)

if [ -n "$module_issues" ]; then
    echo "$module_issues"
else
    echo "• Module issues ready for development"
fi

echo ""
echo "🔗 Quick Links:"
echo "• Sprint Board: https://github.com/orgs/dasdigitalplatform/projects/3/views/4"
echo "• Priority View: https://github.com/orgs/dasdigitalplatform/projects/3/views/1"
echo "• Roadmap View: https://github.com/orgs/dasdigitalplatform/projects/3/views/5"
