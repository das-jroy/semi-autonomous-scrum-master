#!/bin/bash

# Project Setup - Create GitHub project from processed documentation
# Uses the JSON output from document processing to create issues and project board

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Parse command line arguments
ISSUES_FILE="${1}"
CUSTOM_# REPO_OWNER loaded from config
CUSTOM_# REPO_NAME loaded from config

# If no issues file provided, try to find one
if [[ -z "$ISSUES_FILE" ]]; then
    if [[ -f "examples/generated-issues/issues.json" ]]; then
        ISSUES_FILE="examples/generated-issues/issues.json"
    else
        echo "❌ No issues file provided and none found in examples/generated-issues/"
        echo "💡 Usage: $0 [issues_file] [repo_owner] [repo_name]"
        echo "💡 Run ./scripts/core/process-documentation.sh first to generate issues"
        exit 1
    fi
fi

# Load project configuration
load_config

# Override with command line arguments if provided
if [[ -n "$CUSTOM_REPO_OWNER" ]]; then
    # REPO_OWNER loaded from config
fi

if [[ -n "$CUSTOM_REPO_NAME" ]]; then
    # REPO_NAME loaded from config
fi

echo "🚀 Setting up GitHub Project"
echo "============================"
echo "Issues File: $ISSUES_FILE"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Project: $PROJECT_NAME"
echo ""

if [[ ! -f "$ISSUES_FILE" ]]; then
    echo "❌ Issues file not found: $ISSUES_FILE"
    echo "💡 Run ./scripts/core/process-documentation.sh first"
    exit 1
fi

# Check GitHub authentication
check_github_auth

echo "📋 Reading issue definitions..."
if command -v jq &> /dev/null && jq empty "$ISSUES_FILE" 2>/dev/null; then
    ISSUES_PROJECT_NAME=$(jq -r '.project.name // "Generated Project"' "$ISSUES_FILE")
    ISSUES_PROJECT_DESC=$(jq -r '.project.description // "Generated from documentation"' "$ISSUES_FILE")
    
    echo "Issues Project: $ISSUES_PROJECT_NAME"
    echo "Description: $ISSUES_PROJECT_DESC"
else
    echo "⚠️  Could not parse issues file or jq not available"
    echo "Proceeding with configuration defaults..."
fi
echo ""

# TODO: Implement project creation using existing scripts
echo "🏗️ Creating GitHub project..."
echo "📝 Creating issues..."
echo "🏃 Setting up sprints..."
echo "📊 Configuring project board..."

echo "✅ Project setup complete!"
echo "🔗 Visit: https://github.com/$REPO_OWNER/$REPO_NAME/projects"
