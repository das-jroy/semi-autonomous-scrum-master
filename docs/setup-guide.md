# Setup Guide

## Prerequisites

1. **GitHub CLI**: Install and authenticate
   ```bash
   gh auth login
   ```

2. **Repository Access**: Ensure you have admin access to target repositories

3. **Dependencies**: 
   - `jq` for JSON processing
   - `curl` for API calls
   - Standard Unix tools

## Basic Setup

### 1. Process Documentation

Place your documentation in `examples/sample-docs/` and run:

```bash
./scripts/core/process-documentation.sh examples/sample-docs/
```

This will analyze your documentation and generate issue definitions.

### 2. Create Project

Generate the GitHub project and issues:

```bash
./scripts/core/setup-project.sh examples/generated-issues/issues.json your-org your-repo
```

## Advanced Configuration

### Project Types

Configure different project types in `configs/project-types/`:
- `infrastructure.json` - Infrastructure projects
- `web-app.json` - Web applications  
- `api-service.json` - API services

### Team Profiles

Set up team configurations in `configs/team-profiles/` to customize:
- Sprint duration
- Team capacity
- Complexity estimation factors

### Custom Workflows

Create custom GitHub Actions workflows in `.github/workflows/` for:
- Automated documentation processing
- Scheduled project updates
- Progress reporting

## Next Steps

1. Customize the configuration files for your team
2. Set up automated workflows
3. Integrate with your existing documentation process
4. Monitor and optimize the generated projects
