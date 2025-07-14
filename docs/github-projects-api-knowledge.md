# GitHub Projects API Knowledge Base

This document captures critical learnings about GitHub Projects V2 API from the Azure InfraWeave project transformation.

## 🎯 Core API Concepts

### Project Field Types and Management

1. **Native Issue Types**
   - GitHub has native issue types: `Bug`, `Feature`, `Task`
   - Set via GraphQL mutation: `updateIssue` with `issueType` field
   - Different from labels - these are proper GitHub issue classifications

2. **Sprint Field Management**
   - Sprint fields are project-specific custom fields
   - Must be discovered using project field queries
   - Assignment requires specific GraphQL mutations with proper field IDs

3. **Project Views and Layouts**
   - 5 optimized view types: Board, Table, Roadmap, Current Sprint, Backlog
   - Each view can have custom filters, sorting, and grouping
   - Board views support custom columns and swim lanes

## 🔧 Critical GraphQL Patterns

### Issue Type Assignment
```graphql
mutation {
  updateIssue(input: {
    id: "ISSUE_ID"
    issueType: BUG|FEATURE|TASK
  }) {
    issue {
      id
      issueType
    }
  }
}
```

### Sprint Field Assignment
```graphql
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PROJECT_ID"
    itemId: "ITEM_ID"
    fieldId: "SPRINT_FIELD_ID"
    value: {
      singleSelectOptionId: "SPRINT_OPTION_ID"
    }
  }) {
    projectV2Item {
      id
    }
  }
}
```

This knowledge base represents proven patterns from a successful enterprise project transformation.
