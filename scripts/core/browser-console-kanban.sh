#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-helper.sh"

# Load project configuration
load_config

# Validate required configuration
if [[ -z "$PROJECT_ID" ]]; then
    echo "❌ PROJECT_ID not configured!"
    echo "Please set project.project_id in your configuration file:"
    echo "  configs/project-config.json"
    echo ""
    echo "You can find your project ID in the GitHub project URL:"
    echo "  https://github.com/orgs/YOUR_ORG/projects/PROJECT_ID"
    exit 1
fi

# Browser Console Kanban Setup Script
# This generates JavaScript commands that can be run in the browser console

echo "🌐 Browser Console Kanban Setup"
echo "==============================="
echo "Repository: $REPO_OWNER"
echo "Project ID: $PROJECT_ID"
echo ""

cat << EOF

# Browser Console Commands for Adding Kanban Status Options

## 🚀 How to Use:

1. **Open your project board**: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID
2. **Open Developer Tools**: Press F12 or right-click → Inspect
3. **Go to Console tab**
4. **Copy and paste each command below one by one**

## 📋 Commands to Run:

### Command 1: Discover Status Field ID
\`\`\`javascript
// First, discover the Status field ID for your project
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: \`
      query {
        organization(login: "$REPO_OWNER") {
          projectV2(number: $PROJECT_ID) {
            id
            fields(first: 20) {
              nodes {
                ... on ProjectV2SingleSelectField {
                  id
                  name
                  options {
                    id
                    name
                  }
                }
              }
            }
          }
        }
      }
    \`
  })
}).then(response => response.json())
  .then(data => {
    console.log('Project data:', data);
    const statusField = data.data.organization.projectV2.fields.nodes.find(field => field.name === 'Status');
    if (statusField) {
      console.log('✅ Status Field ID:', statusField.id);
      console.log('Current options:', statusField.options.map(opt => opt.name));
      
      // Store the field ID in a global variable for next commands
      window.STATUS_FIELD_ID = statusField.id;
      window.PROJECT_NODE_ID = data.data.organization.projectV2.id;
      
      console.log('📝 Field ID stored in window.STATUS_FIELD_ID');
      console.log('📝 Project ID stored in window.PROJECT_NODE_ID');
      console.log('🚀 Now run Command 2 to add status options');
    } else {
      console.error('❌ Status field not found!');
    }
  })
  .catch(error => console.error('Error:', error));
\`\`\`

### Command 2: Add "Review" Status Option
\`\`\`javascript
// Add Review status option (run after Command 1)
if (!window.STATUS_FIELD_ID) {
  console.error('❌ STATUS_FIELD_ID not found! Run Command 1 first.');
} else {
  fetch('/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: JSON.stringify({
      query: \`
        mutation {
          updateProjectV2Field(input: {
            fieldId: "\${window.STATUS_FIELD_ID || 'FIELD_ID_NOT_SET'}"
            singleSelectField: {
              options: [
                {name: "Todo"},
                {name: "In Progress"}, 
                {name: "Review"},
                {name: "Done"}
              ]
            }
          }) {
            projectV2Field {
              ... on ProjectV2SingleSelectField {
                id
                options {
                  id
                  name
                }
              }
            }
          }
        }
      \`
    })
  }).then(response => response.json())
    .then(data => {
      console.log('✅ Added Review option:', data);
      console.log('🚀 Now run Command 3 to add Blocked option');
    })
    .catch(error => console.error('Error:', error));
}
\`\`\`

### Command 3: Add "Blocked" Status Option
\`\`\`javascript
// Add Blocked status option (run after Command 2)
if (!window.STATUS_FIELD_ID) {
  console.error('❌ STATUS_FIELD_ID not found! Run Command 1 first.');
} else {
  fetch('/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: JSON.stringify({
      query: \`
        mutation {
          updateProjectV2Field(input: {
            fieldId: "\${window.STATUS_FIELD_ID || 'FIELD_ID_NOT_SET'}"
            singleSelectField: {
              options: [
                {name: "Todo"},
                {name: "In Progress"}, 
                {name: "Review"},
                {name: "Blocked"},
                {name: "Done"}
              ]
            }
          }) {
            projectV2Field {
              ... on ProjectV2SingleSelectField {
                id
                options {
                  id
                  name
                }
              }
            }
          }
        }
      \`
    })
  }).then(response => response.json())
    .then(data => {
      console.log('✅ Added Blocked option:', data);
      console.log('🚀 Now run Command 4 to create Sprint Board view');
    })
    .catch(error => console.error('Error:', error));
}
\`\`\`

### Command 4: Create Sprint Board View
\`\`\`javascript
// Create a Sprint Board view (run after Command 3)
fetch('/orgs/$REPO_OWNER/memexes/$PROJECT_ID/views', {
  method: 'POST',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    view: {
      layout: 'board_layout',
      name: 'Sprint Board',
      description: 'Kanban board grouped by status'
    }
  })
}).then(response => response.json())
  .then(data => {
    console.log('✅ Created Sprint Board view:', data);
    console.log('🚀 Now run Command 5 to verify everything');
  })
  .catch(error => console.error('Error:', error));
\`\`\`

### Command 5: Verify Status Options
\`\`\`javascript
// Verify the status options were added (run after Command 4)
if (!window.PROJECT_NODE_ID) {
  console.error('❌ PROJECT_NODE_ID not found! Run Command 1 first.');
} else {
  fetch('/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: JSON.stringify({
      query: \`
        query {
          node(id: "\${window.PROJECT_NODE_ID}") {
            ... on ProjectV2 {
              fields(first: 20) {
                nodes {
                  ... on ProjectV2SingleSelectField {
                    name
                    options {
                      name
                    }
                  }
                }
              }
            }
          }
        }
      \`
    })
  }).then(response => response.json())
    .then(data => {
      const statusField = data.data.node.fields.nodes.find(field => field.name === 'Status');
      if (statusField) {
        console.log('✅ Current Status Options:', statusField.options.map(opt => opt.name));
        console.log('🎉 Kanban setup complete!');
      } else {
        console.error('❌ Status field not found in verification');
      }
    })
    .catch(error => console.error('Error:', error));
}
\`\`\`

## ✅ Expected Results:

After running these commands in sequence, you should see:
1. **Command 1**: Status field ID discovered and stored
2. **Command 2**: "Review" option added to Status field
3. **Command 3**: "Blocked" option added to Status field  
4. **Command 4**: "Sprint Board" view created
5. **Command 5**: Verification showing all 5 status options

## 🎯 Final Workflow:
1. 📋 **Todo** - Ready to implement
2. ⚡ **In Progress** - Actively being developed
3. 👀 **Review** - Code review, validation, testing
4. 🚫 **Blocked** - Waiting for dependencies/decisions  
5. ✅ **Done** - Fully complete, tested, documented

## 💡 Alternative: Manual UI Method

If the console commands don't work, use the manual method:
1. Go to project Settings → Fields → Edit Status field
2. Click "+ Add option" for each new status
3. Create a new Board view grouped by Status

## 🔧 Troubleshooting

If you get errors:
- **"STATUS_FIELD_ID not found"**: Run Command 1 first
- **"Unauthorized"**: Make sure you're logged into GitHub in the same browser
- **"Field not found"**: Your project might not have a Status field yet - create it manually first

EOF

echo ""
echo "🎯 Browser console commands generated!"
echo "📋 Run commands in sequence (1 → 2 → 3 → 4 → 5)"
echo "🔍 Command 1 will discover and store the Status field ID automatically"
echo ""
echo "Visit: https://github.com/orgs/$REPO_OWNER/projects/$PROJECT_ID"
echo "Then open Developer Tools (F12) → Console tab"
EOF
