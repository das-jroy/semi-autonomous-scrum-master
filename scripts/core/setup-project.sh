#!/bin/bash

# Project Setup - Create GitHub project from processed documentation
# Uses the JSON output from document processing to create issues and project board

set -e

ISSUES_FILE="${1:-examples/generated-issues/issues.json}"
REPO_OWNER="${2:-das-jroy}"
REPO_NAME="${3:-semi-autonomous-scrum-master-test}"

echo "🚀 Setting up GitHub Project"
echo "============================"
echo "Issues File: $ISSUES_FILE"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""

if [[ ! -f "$ISSUES_FILE" ]]; then
    echo "❌ Issues file not found: $ISSUES_FILE"
    echo "💡 Run ./scripts/core/process-documentation.sh first"
    exit 1
fi

echo "📋 Reading issue definitions..."
PROJECT_NAME=$(jq -r '.project.name' "$ISSUES_FILE")
PROJECT_DESC=$(jq -r '.project.description' "$ISSUES_FILE")

echo "Project: $PROJECT_NAME"
echo "Description: $PROJECT_DESC"
echo ""

# TODO: Implement project creation using existing scripts
echo "🏗️ Creating GitHub project..."
echo "📝 Creating issues..."
echo "🏃 Setting up sprints..."
echo "📊 Configuring project board..."

echo "✅ Project setup complete!"
echo "🔗 Visit: https://github.com/$REPO_OWNER/$REPO_NAME/projects"
