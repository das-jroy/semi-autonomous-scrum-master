# Deployment Mode 2: Embedded Integration

flowchart LR
    A[Target Repo] -->|PR Addition| B[.github/workflows/scrum-master.yml]
    B -->|Trigger| C[Scrum Master Actions]
    C -->|Update| D[Local Project Board]
