#!/bin/bash

# GitHub Issue Generator for Project Documentation
# This script converts documentation TODOs into structured GitHub issues

set -e

echo "🎫 Generic GitHub Issue Generator"
echo "================================="

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Parse command line arguments
CUSTOM_# REPO_OWNER loaded from config
CUSTOM_# REPO_NAME loaded from config
PROJECT_TYPE="${3:-web-application}"

# Load project configuration
load_config

# Override with command line arguments if provided
if [[ -n "$CUSTOM_REPO_OWNER" ]]; then
    # REPO_OWNER loaded from config
fi

if [[ -n "$CUSTOM_REPO_NAME" ]]; then
    # REPO_NAME loaded from config
fi

echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Project Type: $PROJECT_TYPE"
echo ""

# Function to check if GitHub CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) is not installed. Please install it first.${NC}"
        echo "Install with: brew install gh"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Please authenticate with GitHub CLI first${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI is ready${NC}"
}

# Function to load project type configuration
load_project_type_config() {
    local project_type="$1"
    local config_file="configs/project-types/${project_type}.json"
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${YELLOW}⚠️  Project type config not found: $config_file${NC}"
        echo "Using default configuration..."
        return 1
    fi
    
    echo -e "${BLUE}📋 Loading project type: $project_type${NC}"
    return 0
}

# Function to create project implementation issues
create_project_issues() {
    echo -e "${BLUE}📦 Creating Project Implementation Issues...${NC}"
    echo ""
    
    # Load project type configuration if available
    local project_config="configs/project-types/${PROJECT_TYPE}.json"
    if [[ -f "$project_config" ]]; then
        echo -e "${GREEN}✅ Using project type configuration: ${PROJECT_TYPE}${NC}"
        
        # Get issues from project type configuration
        local high_priority_issues=($(jq -r '.issues.high_priority[]?' "$project_config" 2>/dev/null || echo ""))
        local medium_priority_issues=($(jq -r '.issues.medium_priority[]?' "$project_config" 2>/dev/null || echo ""))
        local low_priority_issues=($(jq -r '.issues.low_priority[]?' "$project_config" 2>/dev/null || echo ""))
        
        # Create issues if they exist in config
        if [[ ${#high_priority_issues[@]} -gt 0 ]]; then
            create_priority_issues "High Priority" high_priority_issues[@] "high-priority" "P1"
        fi
        
        if [[ ${#medium_priority_issues[@]} -gt 0 ]]; then
            create_priority_issues "Medium Priority" medium_priority_issues[@] "medium-priority" "P2"
        fi
        
        if [[ ${#low_priority_issues[@]} -gt 0 ]]; then
            create_priority_issues "Low Priority" low_priority_issues[@] "low-priority" "P3"
        fi
        
        # If no issues in config, create default project structure issues
        if [[ ${#high_priority_issues[@]} -eq 0 && ${#medium_priority_issues[@]} -eq 0 && ${#low_priority_issues[@]} -eq 0 ]]; then
            create_default_project_issues
        fi
    else
        echo -e "${YELLOW}⚠️  No project type configuration found, creating default project structure issues${NC}"
        create_default_project_issues
    fi
}

# Function to create default project structure issues
create_default_project_issues() {
    # Default high priority issues for any project
    local high_priority_issues=(
        "setup:Project Setup:Initialize project structure and development environment"
        "architecture:System Architecture:Design and document system architecture"
        "core:Core Implementation:Implement main application functionality"
        "testing:Testing Framework:Set up testing infrastructure and write tests"
    )
    
    # Default medium priority issues
    local medium_priority_issues=(
        "documentation:Documentation:Write comprehensive project documentation"
        "ci-cd:CI/CD Pipeline:Set up continuous integration and deployment"
        "security:Security Review:Implement security best practices"
        "monitoring:Monitoring Setup:Add logging and monitoring capabilities"
    )
    
    # Default low priority issues
    local low_priority_issues=(
        "optimization:Performance Optimization:Optimize application performance"
        "deployment:Production Deployment:Deploy to production environment"
        "maintenance:Maintenance Tasks:Set up maintenance and update procedures"
    )
    
    # Create issues for each priority level
    create_priority_issues "High Priority" high_priority_issues[@] "high-priority" "P1"
    create_priority_issues "Medium Priority" medium_priority_issues[@] "medium-priority" "P2"  
    create_priority_issues "Low Priority" low_priority_issues[@] "low-priority" "P3"
}

# Function to create issues for a priority group
create_priority_issues() {
    local priority_name="$1"
    local modules_ref="$2"
    local labels="$3"
    local priority_label="$4"
    
    eval "local modules=(\"\${$modules_ref}\")"
    
    echo -e "${PURPLE}Creating $priority_name issues...${NC}"
    
    for module_info in "${modules[@]}"; do
        IFS=':' read -r module_path display_name description <<< "$module_info"
        
        # Generate issue content
        local issue_title="$display_name"
        local issue_body=$(generate_project_issue_body "$module_path" "$display_name" "$description")
        
        # Create the issue
        echo "  📝 Creating issue: $display_name"
        if command -v gh &> /dev/null; then
            gh issue create \
                --title "$issue_title" \
                --body "$issue_body" \
                --label "implementation,$labels,$priority_label" \
                --assignee "@me" || echo "    ⚠️  Failed to create issue for $display_name"
        else
            echo "    📄 Would create issue: $issue_title"
        fi
    done
    echo ""
}

# Function to generate issue body for project implementation
generate_project_issue_body() {
    local issue_path="$1"
    local display_name="$2" 
    local description="$3"
    
    cat << EOF
## � Implementation Task: $display_name

**Component:** \`$issue_path\`  
**Description:** $description

### 🎯 Objective
$description

### 📋 Tasks

#### Core Implementation
- [ ] Research requirements and best practices
- [ ] Design and plan implementation approach
- [ ] Implement core functionality
- [ ] Add comprehensive error handling
- [ ] Write unit and integration tests

#### Documentation & Quality
- [ ] Update documentation with implementation details
- [ ] Add usage examples and guides
- [ ] Validate implementation meets requirements
- [ ] Conduct code review
- [ ] Update project documentation

#### Testing & Validation
- [ ] Test functionality thoroughly
- [ ] Validate performance requirements
- [ ] Check security considerations
- [ ] Verify integration with other components

### 📚 Resources
- Project documentation
- Technical specifications
- Best practices guides
- Relevant external documentation

### ✅ Definition of Done
- [ ] All requirements implemented
- [ ] Tests pass
- [ ] Documentation complete
- [ ] Code review approved
- [ ] Integration tests pass

---
*This issue was auto-generated from project requirements*
EOF
}

# Function to create general infrastructure/workflow issues
create_infrastructure_issues() {
    echo -e "${BLUE}⚙️ Creating Infrastructure Issues...${NC}"
    echo ""
    
    # Generic CI/CD Workflow improvements
    local workflow_title="Set up CI/CD Pipeline"
    local workflow_body=$(cat << 'EOF'
## 🔧 CI/CD Pipeline Setup

**Objective:** Set up continuous integration and deployment pipeline for the project.

### 📋 Tasks

#### Pipeline Setup
- [ ] Configure build automation
- [ ] Set up automated testing
- [ ] Configure deployment automation
- [ ] Add proper authentication and configuration
- [ ] Test pipeline with sample deployments

#### Quality Gates
- [ ] Add code quality checks
- [ ] Implement automated security scanning
- [ ] Add dependency vulnerability scanning
- [ ] Configure automated deployment validation

#### Testing Integration
- [ ] Add unit test automation
- [ ] Implement integration tests
- [ ] Add end-to-end testing
- [ ] Create test reporting

### 🔗 Resources
- CI/CD Best Practices
- Platform-specific deployment guides
- Security scanning tools

### ✅ Definition of Done
- [ ] All pipeline stages configured
- [ ] Automated testing working
- [ ] Deployment automation functional
- [ ] Documentation updated

---
*Priority: High - Required for production deployment*
EOF
    )
    
    echo "  📝 Creating workflow issue..."
    if command -v gh &> /dev/null; then
        gh issue create \
            --title "$workflow_title" \
            --body "$workflow_body" \
            --label "infrastructure,workflow,ci-cd,high-priority" \
            --assignee "@me" || echo "    ⚠️  Failed to create workflow issue"
    fi
}

# Function to create project setup issue
create_project_setup_issue() {
    echo -e "${BLUE}📋 Creating Project Setup Issue...${NC}"
    
    local project_title="Set up GitHub Project for $PROJECT_NAME Module Implementation"
    local project_body=$(cat << EOF
## 🎯 GitHub Project Configuration

**Objective:** Configure the GitHub project board for tracking ${PROJECT_NAME} implementation progress.

### 📋 Recommended Project Setup

#### Project Details
- **Name:** "${PROJECT_NAME}"
- **Description:** "Track implementation progress for ${PROJECT_NAME} project"
- **Visibility:** Private (organization internal)

#### Custom Fields
1. **Component Category** (Select)
   - Frontend
   - Backend  
   - Database
   - API
   - Testing
   - Documentation
   - Infrastructure
   - Security

2. **Priority Level** (Select)
   - P1 - High Priority (Critical Features)
   - P2 - Medium Priority (Important Features)
   - P3 - Low Priority (Nice to Have)

3. **Implementation Status** (Status)
   - 📋 Backlog
   - 🚧 In Progress
   - 👁️ Review
   - ✅ Complete
   - 🚫 Blocked

4. **Complexity** (Select)
   - Low (1-2 days)
   - Medium (3-5 days)
   - High (1-2 weeks)

#### Views to Create
1. **By Priority** - Group by Priority Level
2. **By Component** - Group by Component Category  
3. **Sprint Board** - Filter by current iteration
4. **Completion Progress** - Track overall progress

#### Automation Rules
- Auto-move to "In Progress" when assigned
- Auto-move to "Review" when PR opened
- Auto-move to "Complete" when PR merged

### 📊 Success Metrics
- Track completion rate by component category
- Monitor velocity (tasks completed per sprint)
- Identify blockers and dependencies

---
*This setup will provide excellent visibility into implementation progress*
EOF
    )
    
    echo "  📝 Creating project setup issue..."
    if command -v gh &> /dev/null; then
        gh issue create \
            --title "$project_title" \
            --body "$project_body" \
            --label "project-management,setup,documentation" \
            --assignee "@me" || echo "    ⚠️  Failed to create project setup issue"
    fi
}

# Function to show summary
show_summary() {
    echo -e "${GREEN}📊 Issue Creation Summary${NC}"
    echo "================================"
    echo ""
    
    # Count actual issues created
    local total_issues=$(gh issue list --repo "$REPO_OWNER/$REPO_NAME" --json number | jq length 2>/dev/null || echo "multiple")
    
    echo "Created issues for ${PROJECT_NAME}:"
    echo "  🚀 High priority implementation tasks"
    echo "  🔧 Medium priority features"
    echo "  📋 Low priority enhancements"
    echo "  ⚙️ Infrastructure and workflow setup"
    echo "  📋 Project management setup"
    echo ""
    echo "Total: $total_issues issues in repository"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Configure your GitHub project with the recommended fields"
    echo "2. Assign issues to team members or sprints"
    echo "3. Start with high priority tasks for maximum impact"
    echo "4. Use the project board to track progress"
    echo ""
    echo -e "${GREEN}🎯 Ready to start implementing! View issues at:${NC}"
    echo "https://github.com/$REPO_OWNER/$REPO_NAME/issues"
}

# Main execution
check_gh_cli

echo -e "${YELLOW}This will create GitHub issues for project implementation tasks.${NC}"
echo -e "${YELLOW}Continue? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    create_project_issues
    create_infrastructure_issues  
    create_project_setup_issue
    show_summary
else
    echo "Cancelled."
    exit 0
fi
