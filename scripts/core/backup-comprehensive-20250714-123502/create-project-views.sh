#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config


# GitHub Project Board View Creator
# This script uses GitHub's internal API to create project board views
# Based on reverse-engineered browser API calls
#
# AUTHENTICATION NOTE:
# This internal API requires browser-based authentication with cookies.
# If the script fails with "Cookies must be enabled", you can:
#
# 1. Extract cookies from your browser session:
#    - Open Developer Tools in your browser while logged into GitHub
#    - Go to Application/Storage → Cookies → https://github.com
#    - Copy the values for: _gh_sess, user_session, and __Host-user_session_same_site
#    - Add them to the curl command below like:
#      -H "Cookie: _gh_sess=VALUE; user_session=VALUE; __Host-user_session_same_site=VALUE"
#
# 2. Or run the curl commands manually in your browser's developer console
#    where the cookies are automatically available.

set -e

echo "🎯 GitHub Project Board View Creator"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
# REPO_OWNER loaded from config
PROJECT_NUMBER="3"

# Function to get GitHub session information
get_github_session() {
    echo -e "${CYAN}🔒 GitHub Session Information${NC}"
    echo "============================="
    
    # Check if user is logged into GitHub CLI
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
        echo "Please run: gh auth login"
        exit 1
    fi
    
    local current_user=$(gh api user --jq .login)
    echo -e "${GREEN}✅ Authenticated as: ${current_user}${NC}"
    
    # Get GitHub token for API calls
    GITHUB_TOKEN=$(gh auth token)
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo -e "${RED}❌ Unable to get GitHub token${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub token available${NC}"
    
    # Check if we can access the project via regular GitHub API
    echo -e "${BLUE}🔍 Testing GitHub API access...${NC}"
    local api_test=$(gh api "orgs/$REPO_OWNER/projects" --jq '.[] | select(.number == '$PROJECT_NUMBER') | .id' 2>/dev/null || echo "")
    
    if [[ -n "$api_test" ]]; then
        echo -e "${GREEN}✅ GitHub API access confirmed${NC}"
    else
        echo -e "${YELLOW}⚠️  Limited GitHub API access - internal API may require browser session${NC}"
    fi
    
    echo ""
}

# Function to get project ID from the HTML page
get_project_id() {
    echo -e "${BLUE}🔍 Getting Project ID${NC}"
    echo "===================="
    
    # Use GitHub CLI to get project details
    local project_info=$(gh api graphql -f query="
    {
      organization(login: \"$REPO_OWNER\") {
        projectV2(number: $PROJECT_NUMBER) {
          id
          databaseId
          title
        }
      }
    }")
    
    PROJECT_ID=$(echo "$project_info" | jq -r '.data.organization.projectV2.databaseId')
    PROJECT_NODE_ID=$(echo "$project_info" | jq -r '.data.organization.projectV2.id')
    PROJECT_TITLE=$(echo "$project_info" | jq -r '.data.organization.projectV2.title')
    
    if [[ -z "$PROJECT_ID" ]] || [[ "$PROJECT_ID" == "null" ]]; then
        echo -e "${RED}❌ Could not get project ID${NC}"
        exit 1
    fi
    
    echo "Project: $PROJECT_TITLE"
    echo "Database ID: $PROJECT_ID"
    echo "Node ID: $PROJECT_NODE_ID"
    echo ""
}

# Function to create a view using GitHub's internal API
create_view() {
    local view_name="$1"
    local layout="$2"
    local description="$3"
    
    echo -e "${PURPLE}📋 Creating View: $view_name${NC}"
    echo "================================="
    
    # Prepare the API payload (based on GitHub's internal API format)
    local payload
    case "$layout" in
        "table")
            payload='{"view":{"layout":"table_layout","name":"'"$view_name"'","description":"'"$description"'"}}'
            ;;
        "board")
            payload='{"view":{"layout":"board_layout","name":"'"$view_name"'","description":"'"$description"'"}}'
            ;;
        "roadmap")
            payload='{"view":{"layout":"roadmap_layout","name":"'"$view_name"'","description":"'"$description"'"}}'
            ;;
        *)
            echo -e "${RED}❌ Unknown layout: $layout${NC}"
            return 1
            ;;
    esac
    
    echo "Layout: $layout"
    echo "Payload: $payload"
    
    # Make the API call using curl with GitHub token authentication
    local response=$(curl -s -X POST \
        "https://github.com/orgs/$REPO_OWNER/memexes/$PROJECT_ID/views" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "User-Agent: Mozilla/5.0 (GitHub-Project-Automation)" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "X-GitHub-Media-Type: github.v3" \
        --data-raw "$payload")
    
    # Check if the request was successful
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        local view_id=$(echo "$response" | jq -r '.id')
        echo -e "${GREEN}✅ Created view '$view_name' (ID: $view_id)${NC}"
        return 0
    elif echo "$response" | grep -q "Cookies must be enabled"; then
        echo -e "${YELLOW}⚠️  Authentication failed - requires browser cookies${NC}"
        echo "Response: $response"
        return 2  # Special return code for cookie auth failure
    else
        echo -e "${YELLOW}⚠️  View creation may have failed or view already exists${NC}"
        echo "Response: $response"
        return 1
    fi
    
    echo ""
}

# Function to create all recommended views
create_all_views() {
    echo -e "${BLUE}🎨 Creating All Recommended Views${NC}"
    echo "=================================="
    echo ""
    
    local auth_failed=false
    
    # Create the 5 recommended views
    create_view "By Priority" "table" "Group issues by priority level"
    if [[ $? -eq 2 ]]; then auth_failed=true; fi
    
    if [[ "$auth_failed" != "true" ]]; then
        create_view "By Category" "table" "Group issues by module category"
        if [[ $? -eq 2 ]]; then auth_failed=true; fi
    fi
    
    if [[ "$auth_failed" != "true" ]]; then
        create_view "Security Dashboard" "table" "Track security review status"
        if [[ $? -eq 2 ]]; then auth_failed=true; fi
    fi
    
    if [[ "$auth_failed" != "true" ]]; then
        create_view "Sprint Board" "board" "Kanban board for active work"
        if [[ $? -eq 2 ]]; then auth_failed=true; fi
    fi
    
    if [[ "$auth_failed" != "true" ]]; then
        create_view "Implementation Roadmap" "roadmap" "Timeline view of module implementation"
        if [[ $? -eq 2 ]]; then auth_failed=true; fi
    fi
    
    echo ""
    
    # If authentication failed, show manual instructions
    if [[ "$auth_failed" == "true" ]]; then
        echo -e "${RED}❌ Authentication failed - browser cookies required${NC}"
        show_manual_instructions
    else
        show_next_steps
    fi
}

# Function to show next steps
show_next_steps() {
    echo -e "${GREEN}🚀 Views Created Successfully!${NC}"
    echo "============================="
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Visit your project board to configure view filters and grouping:"
    echo "   Navigate to GitHub → $REPO_OWNER → Projects → Project #3"
    echo ""
    echo "2. For each view, configure the specific settings:"
    echo "   - By Priority: Group by 'Priority Level'"
    echo "   - By Category: Group by 'Module Category'"
    echo "   - Security Dashboard: Filter 'Security Review' = Required/In Progress"
    echo "   - Sprint Board: Filter Status != Complete"
    echo "   - Implementation Roadmap: Group by Priority Level"
    echo ""
    echo "3. Your 17 GitHub issues are ready to be managed with these views!"
    echo ""
}

# Function to show manual instructions if API fails
show_manual_instructions() {
    echo -e "${YELLOW}📋 Manual View Creation Instructions${NC}"
    echo "===================================="
    echo ""
    echo "Since the internal API requires browser cookies, here are the manual steps:"
    echo ""
    echo "1. Open your browser and navigate to:"
    echo "   https://github.com/orgs/$REPO_OWNER/projects/3"
    echo ""
    echo "2. Click the '+' button to add a new view"
    echo ""
    echo "3. Create these 5 views with the following configurations:"
    echo ""
    echo -e "${BLUE}View 1: By Priority${NC}"
    echo "- Layout: Table"
    echo "- Group by: Priority Level"
    echo "- Description: Group issues by priority level"
    echo ""
    echo -e "${BLUE}View 2: By Category${NC}"
    echo "- Layout: Table"
    echo "- Group by: Module Category"
    echo "- Description: Group issues by module category"
    echo ""
    echo -e "${BLUE}View 3: Security Dashboard${NC}"
    echo "- Layout: Table"
    echo "- Filter: Security Review = Required OR In Progress"
    echo "- Description: Track security review status"
    echo ""
    echo -e "${BLUE}View 4: Sprint Board${NC}"
    echo "- Layout: Board"
    echo "- Group by: Status"
    echo "- Filter: Status != Complete"
    echo "- Description: Kanban board for active work"
    echo ""
    echo -e "${BLUE}View 5: Implementation Roadmap${NC}"
    echo "- Layout: Roadmap"
    echo "- Group by: Priority Level"
    echo "- Description: Timeline view of module implementation"
    echo ""
    echo "Alternatively, if you have browser cookies, you can extract them and"
    echo "add them to the curl commands in this script."
    echo ""
}

# Function to show warning about internal API
show_api_warning() {
    echo -e "${YELLOW}⚠️  Important Notice${NC}"
    echo "=================="
    echo ""
    echo "This script uses GitHub's internal API which requires browser cookies"
    echo "for authentication. The GitHub CLI token alone may not be sufficient."
    echo ""
    echo "If this script fails with 'Cookies must be enabled', you have two options:"
    echo ""
    echo "1. Use this script as a reference and copy the curl commands to run"
    echo "   manually in a browser's developer tools console where GitHub cookies"
    echo "   are available."
    echo ""
    echo "2. Extract cookies from your browser session and add them to the curl"
    echo "   commands (see script comments for instructions)."
    echo ""
    echo "3. Create views manually through the GitHub web interface."
    echo ""
    echo "Continue with token-based authentication attempt? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    echo ""
}

# Main execution
main() {
    show_api_warning
    get_github_session
    get_project_id
    create_all_views
}

# Run main function
main
