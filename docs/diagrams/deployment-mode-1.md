# Deployment Mode 1: Separate Repository

flowchart LR
    A[Target Repo] -->|Webhook/Schedule| B[Semi-Autonomous Scrum Master Repo]
    B -->|GitHub Actions| C[Analysis & Planning]
    C -->|GitHub API| D[Update Target Repo Project]
