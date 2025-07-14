# 🚀 Central Orchestration Quick Start Guide

This guide will get you started with implementing the Central Orchestration strategy for the Semi-Autonomous Scrum Master.

## 📋 **Prerequisites Checklist**

Before starting implementation, ensure you have:

### **GitHub Access & Permissions**
- [ ] **Enterprise GitHub Token** with organization-wide access
- [ ] **GitHub Projects V2 API access** for all target repositories  
- [ ] **Repository permissions** (read/write) for target repositories
- [ ] **GitHub Actions permissions** to run workflows on target repositories

### **Copilot Integration**
- [ ] **GitHub Copilot API access token** or OpenAI API token
- [ ] **API quota/limits** confirmed for enterprise usage
- [ ] **Billing setup** for API usage across multiple projects

### **Technical Setup**
- [ ] **Node.js 20+** installed
- [ ] **TypeScript/NestJS** familiarity
- [ ] **GitHub CLI** installed and authenticated
- [ ] **Terminal access** with shell script execution permissions

## 🎯 **Phase 1: Immediate Implementation (Week 1-2)**

### **Step 1: Create Enterprise Configuration**

Create your first multi-project configuration:

```bash
# Create enterprise configuration file
mkdir -p configs
touch configs/enterprise-portfolio.yml
```

**Template configuration** (customize for your projects):

```yaml
# configs/enterprise-portfolio.yml
projects:
  your-frontend:
    repository: "your-org/frontend-app"
    projectId: "PVT_YOUR_PROJECT_ID"  # Get from GitHub Projects V2 URL
    projectType: "web-application"
    priority: "high"
    team:
      size: 4
      velocity: [20, 22, 25, 23, 24]  # Last 5 sprints (estimate if new)
      capacity: 80  # Story points per 2-week sprint
      sprintLength: 14  # Days
    copilot:
      model: "gpt-4"
      contextDepth: "deep"
    notifications:
      slack:
        webhook: ${{ secrets.FRONTEND_SLACK_WEBHOOK }}
      email: ["team-lead@yourcompany.com"]

  your-api:
    repository: "your-org/backend-api"
    projectId: "PVT_YOUR_API_PROJECT_ID"
    projectType: "api-service"
    priority: "critical"
    team:
      size: 3
      velocity: [15, 18, 17, 19, 16]
      capacity: 60
      sprintLength: 14
    copilot:
      model: "gpt-4"
      contextDepth: "deep"
    notifications:
      email: ["api-team@yourcompany.com"]

globalSettings:
  defaultSprintLength: 14
  defaultCopilotModel: "gpt-4"
  enterpriseDashboard: true
  crossProjectLearning: true
```

### **Step 2: Setup GitHub Secrets**

Add required secrets to your scrum master repository:

```bash
# Navigate to your GitHub repository → Settings → Secrets and variables → Actions
# Add these repository secrets:

GITHUB_TOKEN=ghp_your_enterprise_token
COPILOT_TOKEN=your_copilot_api_token

# Per-project tokens (optional for fine-grained access)
TOKEN_FRONTEND=ghp_frontend_specific_token
TOKEN_API=ghp_api_specific_token

# Notification webhooks (optional)
FRONTEND_SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

### **Step 3: Create Orchestration Workflow**

Create the GitHub Actions workflow:

```bash
mkdir -p .github/workflows
touch .github/workflows/enterprise-scrum-orchestration.yml
```

**Basic orchestration workflow**:

```yaml
# .github/workflows/enterprise-scrum-orchestration.yml
name: Enterprise Scrum Master Orchestration

on:
  schedule:
    - cron: '0 9 * * MON'  # Monday 9 AM - Sprint Planning
    - cron: '0 17 * * FRI'  # Friday 5 PM - Sprint Review
  workflow_dispatch:
    inputs:
      operation:
        description: 'Operation to perform'
        required: true
        type: choice
        options:
          - 'sprint-planning'
          - 'progress-check'
          - 'retrospective'
          - 'health-check'

jobs:
  orchestrate-projects:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        project: 
          - { key: "frontend", repo: "your-org/frontend-app", type: "web-application" }
          - { key: "api", repo: "your-org/backend-api", type: "api-service" }
    
    steps:
    - name: Checkout Scrum Master
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        
    - name: Run Scrum Master Orchestration
      run: |
        # Using our existing scripts with multi-project capability
        export TARGET_REPO="${{ matrix.project.repo }}"
        export PROJECT_TYPE="${{ matrix.project.type }}"
        export OPERATION="${{ github.event.inputs.operation || 'health-check' }}"
        
        # Execute appropriate script based on operation
        case "$OPERATION" in
          "sprint-planning")
            ./scripts/core/sprint-planning.sh --target-repo="$TARGET_REPO"
            ;;
          "progress-check")
            ./scripts/core/detailed-progress.sh --target-repo="$TARGET_REPO" 
            ;;
          "retrospective")
            ./scripts/core/complete-final-status.sh --target-repo="$TARGET_REPO"
            ;;
          "health-check")
            ./scripts/core/health-check.sh --target-repo="$TARGET_REPO"
            ;;
        esac
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        COPILOT_TOKEN: ${{ secrets.COPILOT_TOKEN }}
```

### **Step 4: Test Basic Orchestration**

Test your setup with a manual workflow run:

```bash
# Navigate to your repository → Actions → Enterprise Scrum Master Orchestration
# Click "Run workflow" → Select "health-check" → Run workflow

# Monitor the execution and check logs for any issues
```

## 🔧 **Quick Configuration Reference**

### **Getting GitHub Project IDs**

1. Navigate to your GitHub Project V2
2. Look at the URL: `https://github.com/orgs/your-org/projects/123`
3. The project ID will be in the format: `PVT_kwDOABCDEF123GHIJK`
4. You can also get it via GitHub CLI:

```bash
gh api graphql -f query='
{
  organization(login: "your-org") {
    projectsV2(first: 10) {
      nodes {
        id
        title
      }
    }
  }
}'
```

### **Testing Individual Scripts**

Test core scripts work with your projects:

```bash
# Test project setup
export TARGET_REPO="your-org/frontend-app"
./scripts/core/setup-project.sh --target-repo="$TARGET_REPO"

# Test health check
./scripts/core/health-check.sh --target-repo="$TARGET_REPO"

# Test progress monitoring  
./scripts/core/detailed-progress.sh --target-repo="$TARGET_REPO"
```

### **Common Issues & Solutions**

**🔴 Permission Errors**
```bash
# Check token permissions
gh auth status
gh api user  # Should return your user info

# Verify repository access
gh repo view your-org/frontend-app
```

**🔴 Script Execution Issues**
```bash
# Make scripts executable
chmod +x scripts/core/*.sh

# Check script dependencies
./scripts/core/health-check.sh --help
```

**🔴 GitHub Projects API Issues**
```bash
# Test Projects V2 access
gh api graphql -f query='{ viewer { login } }'

# List available projects
gh project list --owner your-org
```

## 📊 **Success Validation**

After basic setup, you should see:

✅ **GitHub Actions running successfully** for multiple projects  
✅ **Basic health checks** reporting project status  
✅ **No permission errors** in workflow logs  
✅ **Script outputs** showing project data  
✅ **Configuration loading** without validation errors  

## 🎯 **Next Steps**

Once basic orchestration is working:

1. **Add more projects** to your configuration
2. **Enable Copilot integration** for intelligent insights
3. **Setup notification channels** (Slack/email)
4. **Create custom project types** for specialized workflows
5. **Build enterprise dashboard** for portfolio view

## 📞 **Getting Help**

If you encounter issues:

1. **Check GitHub Actions logs** for detailed error messages
2. **Verify all secrets** are properly configured
3. **Test individual scripts** outside of workflows first
4. **Review repository permissions** for all target projects
5. **Validate configuration syntax** using YAML validators

## 🚀 **Ready to Scale**

Once this basic setup works, you're ready to implement:
- Cross-project Copilot analysis
- Advanced automation workflows  
- Portfolio-level insights
- Predictive analytics
- Resource optimization

**You're now on the path to enterprise-scale scrum master automation!** 🎉
