# Repository Analysis Engine Workflow

sequenceDiagram
    participant User
    participant Trigger as GitHub Actions
    participant Analyzer as Repository Analyzer
    participant TechDetector as Technology Detector
    participant DocParser as Documentation Parser
    participant StateAssessor as Project State Assessor
    participant GitHub as GitHub API

    User->>Trigger: Repository Event (push/schedule)
    Trigger->>Analyzer: Initialize Analysis
    
    rect rgb(200, 230, 255)
    note over Analyzer: Repository Discovery Phase
    Analyzer->>GitHub: Get repository metadata
    GitHub-->>Analyzer: Repository info (language, topics, etc.)
    Analyzer->>GitHub: Get directory structure
    GitHub-->>Analyzer: File tree
    end
    
    rect rgb(255, 230, 200)
    note over Analyzer: Technology Detection Phase
    Analyzer->>TechDetector: Analyze tech stack
    TechDetector->>GitHub: Read package.json/requirements.txt/etc
    GitHub-->>TechDetector: Dependency files
    TechDetector-->>Analyzer: Technology profile
    end
    
    rect rgb(230, 255, 200)
    note over Analyzer: Documentation Analysis Phase
    Analyzer->>DocParser: Parse documentation
    DocParser->>GitHub: Read README.md, docs/**
    GitHub-->>DocParser: Documentation content
    DocParser->>DocParser: Extract requirements
    DocParser->>DocParser: Identify project goals
    DocParser-->>Analyzer: Project understanding
    end
    
    rect rgb(255, 200, 230)
    note over Analyzer: Current State Assessment Phase
    Analyzer->>StateAssessor: Assess current state
    StateAssessor->>GitHub: Check existing issues
    GitHub-->>StateAssessor: Issue list
    StateAssessor->>GitHub: Check existing project boards
    GitHub-->>StateAssessor: Project boards
    StateAssessor->>GitHub: Check workflows
    GitHub-->>StateAssessor: CI/CD workflows
    StateAssessor-->>Analyzer: Current state profile
    end
    
    Analyzer-->>Trigger: Complete analysis result
    Trigger-->>User: Analysis complete
