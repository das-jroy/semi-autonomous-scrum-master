# Semi-Autonomous Scrum Master

🤖 AI-powered project management automation that converts documentation into actionable GitHub issues, sprints, and project boards.

## 🎯 Features

- **Document Analysis**: Automatically extract actionable items from documentation
- **Intelligent Issue Creation**: Generate properly categorized GitHub issues
- **AI-Powered Sprint Planning**: Distribute work across sprints intelligently
- **Project Board Automation**: Set up optimized project views and workflows
- **Continuous Optimization**: Monitor progress and suggest improvements

## 🚀 Quick Start

1. **Install Dependencies**:
   ```bash
   # Ensure GitHub CLI is installed and authenticated
   gh auth status
   ```

2. **Configure Project**:
   ```bash
   # Copy your documentation to examples/sample-docs/
   # Run the document processor
   ./scripts/core/process-documentation.sh
   ```

3. **Generate Project**:
   ```bash
   # Create issues and project board
   ./scripts/core/setup-project.sh
   ```

## 📚 Documentation

- [Setup Guide](docs/setup-guide.md)
- [API Reference](docs/api-reference.md)
- [Examples](docs/examples/)

## 🏗️ Architecture

Built on GitHub-native technologies:
- **GitHub Actions** for workflow orchestration
- **GitHub Copilot Agents** for intelligent processing
- **GitHub Projects V2** for advanced project management
- **GitHub CLI/API** for seamless integration

## 🎉 Getting Started

See [Setup Guide](docs/setup-guide.md) for detailed instructions.
