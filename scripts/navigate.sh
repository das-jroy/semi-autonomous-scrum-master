#!/bin/bash

# Semi-Autonomous Scrum Master - Script Navigation
# Interactive script to help navigate the reorganized directory structure

echo "🎯 Semi-Autonomous Scrum Master - Script Navigation"
echo "=================================================="
echo ""

echo "📁 Available Script Categories:"
echo ""
echo "1. 🚀 Setup & Configuration"
echo "   └── scripts/setup/"
echo "   • Initial project setup and configuration"
echo "   • Config management and setup wizard"
echo ""
echo "2. 📋 Project Management"
echo "   └── scripts/project-management/"
echo "   • Issue creation and management"
echo "   • Sprint planning and roadmap setup"
echo "   • GitHub Projects integration"
echo ""
echo "3. 🤖 Automation"
echo "   └── scripts/automation/"
echo "   • Kanban board automation"
echo "   • Workflow automation"
echo "   • Quick view switching"
echo ""
echo "4. ✅ Validation & Health Checks"
echo "   └── scripts/validation/"
echo "   • System health monitoring"
echo "   • Workflow validation"
echo "   • Field analysis"
echo ""
echo "5. 📊 Reporting"
echo "   └── scripts/reporting/"
echo "   • Progress reports"
echo "   • Status summaries"
echo "   • Before/after comparisons"
echo ""
echo "6. 🛠️ Utilities"
echo "   └── scripts/utilities/"
echo "   • Helper tools"
echo "   • Documentation generators"
echo "   • Implementation checklists"
echo ""

echo "Select a category to explore (1-6) or 'q' to quit:"
read -r choice

case $choice in
    1)
        echo ""
        echo "🚀 Setup Scripts:"
        ls -la scripts/setup/
        echo ""
        echo "Start here: ./scripts/setup/setup-wizard.sh"
        ;;
    2)
        echo ""
        echo "📋 Project Management Scripts:"
        ls -la scripts/project-management/
        echo ""
        echo "Common: ./scripts/project-management/create-github-issues.sh"
        ;;
    3)
        echo ""
        echo "🤖 Automation Scripts:"
        ls -la scripts/automation/
        echo ""
        echo "Popular: ./scripts/automation/automated-kanban-setup.sh"
        ;;
    4)
        echo ""
        echo "✅ Validation Scripts:"
        ls -la scripts/validation/
        echo ""
        echo "Recommended: ./scripts/validation/health-check.sh"
        ;;
    5)
        echo ""
        echo "📊 Reporting Scripts:"
        ls -la scripts/reporting/
        echo ""
        echo "Overview: ./scripts/reporting/final-status-report.sh"
        ;;
    6)
        echo ""
        echo "🛠️ Utility Scripts:"
        ls -la scripts/utilities/
        echo ""
        echo "Helpful: ./scripts/utilities/implementation-checklist.sh"
        ;;
    q|Q)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please select 1-6 or 'q' to quit."
        ;;
esac
