#!/bin/bash
# Quick Project View Switcher

echo "🎯 Azure InfraWeave Project Views"
echo "================================="
echo ""
echo "Select a view to open:"
echo "1. Priority View - Daily priority management"
echo "2. Category View - Phase-based organization"  
echo "3. Security Review - Security compliance tracking"
echo "4. Sprint Board - Active sprint management"
echo "5. Roadmap View - Timeline and roadmap planning"
echo ""

read -p "Choose view (1-5): " choice

case $choice in
    1) echo "Opening Priority View..."; open "https://github.com/orgs/dasdigitalplatform/projects/3/views/1" ;;
    2) echo "Opening Category View..."; open "https://github.com/orgs/dasdigitalplatform/projects/3/views/2" ;;
    3) echo "Opening Security Review..."; open "https://github.com/orgs/dasdigitalplatform/projects/3/views/3" ;;
    4) echo "Opening Sprint Board..."; open "https://github.com/orgs/dasdigitalplatform/projects/3/views/4" ;;
    5) echo "Opening Roadmap View..."; open "https://github.com/orgs/dasdigitalplatform/projects/3/views/5" ;;
    *) echo "Invalid choice. Opening main project board..."; open "https://github.com/orgs/dasdigitalplatform/projects/3" ;;
esac
