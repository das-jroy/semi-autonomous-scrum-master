# Scripts Directory Structure

This directory contains all the automation scripts for the Semi-Autonomous Scrum Master tool, organized into logical categories for better maintainability.

## Directory Structure

### 📁 setup/
Initial project configuration and setup scripts
- `config-helper.sh` - Core configuration management (sourced by all scripts)
- `setup-wizard.sh` - Interactive setup wizard
- `setup-project.sh` - Main project setup
- `setup-project-board.sh` - GitHub project board setup
- `final-project-setup.sh` - Final configuration steps
- `working-project-setup.sh` - Working project configuration

### 📁 project-management/
GitHub Projects, issues, fields, and sprint management
- `create-github-issues.sh` - Generate project issues
- `add-issues-to-project.sh` - Add issues to project board
- `create-project-views.sh` - Create project board views
- `sprint-planning.sh` - Sprint planning automation
- `setup-roadmap-dates.sh` - Configure roadmap timeline
- `update-issues-metadata.sh` - Bulk update issue metadata

### 📁 automation/
Workflow automation and kanban management
- `automated-kanban-setup.sh` - Automated kanban board setup
- `complete-kanban-automation.sh` - Complete kanban automation
- `browser-console-kanban.sh` - Browser-based kanban operations
- `quick-view-switch.sh` - Quick view switching automation

### 📁 validation/
Health checks, validation, and testing scripts
- `validate-workflow.sh` - Workflow validation
- `validate-genericization.sh` - Ensure tool remains generic
- `health-check.sh` - System health monitoring
- `check-view-health.sh` - Project view health checks
- `field-analysis.sh` - Custom field analysis

### 📁 reporting/
Progress reporting and status summaries
- `before-after-comparison.sh` - Show implementation progress
- `final-status-report.sh` - Final project status
- `detailed-progress.sh` - Detailed progress tracking
- `milestone-completion-summary.sh` - Milestone summaries

### 📁 utilities/
Helper utilities and documentation tools
- `todo-management.sh` - TODO tracking and management
- `implementation-checklist.sh` - Implementation checklist
- `process-documentation.sh` - Generate process documentation

## Usage

All scripts source the configuration helper:
```bash
# For scripts in subdirectories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"
```

## Getting Started

1. Start with setup scripts:
   ```bash
   ./scripts/setup/setup-wizard.sh
   ```

2. Use project management scripts for daily operations:
   ```bash
   ./scripts/project-management/create-github-issues.sh
   ```

3. Run validation scripts to ensure health:
   ```bash
   ./scripts/validation/health-check.sh
   ```

4. Generate reports for progress tracking:
   ```bash
   ./scripts/reporting/final-status-report.sh
   ```
