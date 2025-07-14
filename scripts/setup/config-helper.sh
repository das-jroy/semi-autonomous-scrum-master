#!/bin/bash

# Configuration Helper - Load project configuration
# Source this script to load configuration variables

set -e

# Default configuration file
CONFIG_FILE="${CONFIG_FILE:-configs/project-config.json}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
        echo "💡 Run: cp configs/project-config.json.template configs/project-config.json"
        echo "   Then edit the configuration file with your project details"
        exit 1
    fi
    
    echo -e "${BLUE}📋 Loading configuration from: $CONFIG_FILE${NC}"
    
    # Load project configuration
    PROJECT_NAME=$(jq -r '.project.name // ""' "$CONFIG_FILE")
    PROJECT_DESC=$(jq -r '.project.description // ""' "$CONFIG_FILE")
    REPO_OWNER=$(jq -r '.project.owner // ""' "$CONFIG_FILE")
    REPO_NAME=$(jq -r '.project.repository // ""' "$CONFIG_FILE")
    PROJECT_ID=$(jq -r '.project.project_id // ""' "$CONFIG_FILE")
    
    # If PROJECT_NAME is empty, use the repository name as fallback
    if [[ -z "$PROJECT_NAME" && -n "$REPO_NAME" ]]; then
        PROJECT_NAME="$REPO_NAME"
    elif [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="Unnamed Project"
    fi
    
    # If PROJECT_DESC is empty, generate a default based on project name
    if [[ -z "$PROJECT_DESC" && -n "$PROJECT_NAME" ]]; then
        PROJECT_DESC="Development project for $PROJECT_NAME"
    fi
    
    # Load defaults
    SPRINT_DURATION=$(jq -r '.defaults.sprint_duration_weeks // 2' "$CONFIG_FILE")
    TEAM_CAPACITY=$(jq -r '.defaults.team_capacity_points // 40' "$CONFIG_FILE")
    DEFAULT_ASSIGNEE=$(jq -r '.defaults.default_assignee // ""' "$CONFIG_FILE")
    
    # Validation
    if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
        echo -e "${YELLOW}⚠️  Missing required configuration:${NC}"
        [[ -z "$REPO_OWNER" ]] && echo "  - project.owner"
        [[ -z "$REPO_NAME" ]] && echo "  - project.repository"
        echo ""
        echo "Please update $CONFIG_FILE with your project details"
        return 1
    fi
    
    echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
    echo "   Project: $PROJECT_NAME"
    echo "   Repository: $REPO_OWNER/$REPO_NAME"
    if [[ -n "$PROJECT_ID" ]]; then
        echo "   Project ID: $PROJECT_ID"
    fi
    echo ""
}

# Function to get configuration value
get_config() {
    local key="$1"
    local default="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$default"
        return
    fi
    
    jq -r ".$key // \"$default\"" "$CONFIG_FILE"
}

# Function to update configuration value
update_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
        return 1
    fi
    
    # Create backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Update value
    jq ".$key = \"$value\"" "$CONFIG_FILE.backup" > "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Updated $key = $value${NC}"
}

# Function to validate GitHub authentication
check_github_auth() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
        echo "Install with: brew install gh"
        return 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Please authenticate with GitHub CLI${NC}"
        echo "Run: gh auth login"
        return 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
}

# Function to display help
show_config_help() {
    echo "Configuration Helper Usage:"
    echo ""
    echo "Source this script to load configuration:"
    echo "  source scripts/core/config-helper.sh"
    echo ""
    echo "Available functions:"
    echo "  load_config              - Load project configuration"
    echo "  get_config KEY DEFAULT   - Get configuration value"
    echo "  update_config KEY VALUE  - Update configuration value"
    echo "  check_github_auth        - Validate GitHub authentication"
    echo ""
    echo "Environment variables:"
    echo "  CONFIG_FILE              - Path to configuration file (default: configs/project-config.json)"
    echo ""
}

# If script is run directly (not sourced), show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_config_help
fi
