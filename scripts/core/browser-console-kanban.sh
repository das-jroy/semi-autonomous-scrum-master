#!/bin/bash

# Browser Console Kanban Setup Script
# This generates JavaScript commands that can be run in the browser console

echo "🌐 Browser Console Kanban Setup"
echo "==============================="

cat << 'EOF'

# Browser Console Commands for Adding Kanban Status Options

## 🚀 How to Use:

1. **Open your project board**: https://github.com/orgs/dasdigitalplatform/projects/3
2. **Open Developer Tools**: Press F12 or right-click → Inspect
3. **Go to Console tab**
4. **Copy and paste each command below one by one**

## 📋 Commands to Run:

### Command 1: Add "Review" Status Option
```javascript
// Add Review status option
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: `
      mutation {
        updateProjectV2Field(input: {
          fieldId: "PVTSSF_lADOC-2N484A9m2CzgxQnNU"
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
    `
  })
}).then(response => response.json())
  .then(data => console.log('Added Review option:', data))
  .catch(error => console.error('Error:', error));
```

### Command 2: Add "Blocked" Status Option  
```javascript
// Add Blocked status option (after Review is added)
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: `
      mutation {
        updateProjectV2Field(input: {
          fieldId: "PVTSSF_lADOC-2N484A9m2CzgxQnNU"
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
    `
  })
}).then(response => response.json())
  .then(data => console.log('Added Blocked option:', data))
  .catch(error => console.error('Error:', error));
```

### Command 3: Create Sprint Board View
```javascript
// Create a Sprint Board view
fetch('/orgs/dasdigitalplatform/memexes/16149890/views', {
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
  .then(data => console.log('Created Sprint Board view:', data))
  .catch(error => console.error('Error:', error));
```

### Command 4: Verify Status Options
```javascript
// Verify the status options were added
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  body: JSON.stringify({
    query: `
      query {
        node(id: "PVT_kwDOC-2N484A9m2C") {
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
    `
  })
}).then(response => response.json())
  .then(data => {
    const statusField = data.data.node.fields.nodes.find(field => field.name === 'Status');
    console.log('Current Status Options:', statusField.options.map(opt => opt.name));
  })
  .catch(error => console.error('Error:', error));
```

## ✅ Expected Results:

After running these commands, you should see:
- "Review" option added to Status field
- "Blocked" option added to Status field  
- "Sprint Board" view created
- Verification showing all 5 status options

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

EOF

echo ""
echo "🎯 Browser console commands generated!"
echo "Copy the JavaScript commands above and run them in your browser console."
echo ""
echo "Visit: https://github.com/orgs/dasdigitalplatform/projects/3"
echo "Then open Developer Tools (F12) → Console tab"
EOF
