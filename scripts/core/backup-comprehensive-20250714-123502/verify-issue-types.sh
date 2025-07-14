#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Quick verification of Issue Type field status

# PROJECT_ID loaded from config
# OWNER loaded from config

echo "🔍 Issue Type Field Verification"
echo "================================"

echo ""
echo "📊 Current Issue Type Distribution:"
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | .["issue Type"] // "Not Set"' | sort | uniq -c | sort -nr

echo ""
echo "📋 Sample Issues with Types:"
echo "=========================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | "• \(.title): \(.["issue Type"] // "Not Set")"' | head -10

echo ""
echo "🎯 Sprint 1 Items (DOR Status) with Types:"
echo "=========================================="
gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json | \
jq -r '.items[] | select(.status == "DOR") | "✅ \(.title): \(.["issue Type"] // "Not Set")"'
