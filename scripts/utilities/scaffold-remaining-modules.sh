#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup/config-helper.sh"

# Load project configuration
load_config


# Script to complete scaffolding of remaining InfraWeave modules
# This will add proper content to placeholder files and create missing module.yaml files

set -e

echo "🚀 Completing scaffolding for remaining InfraWeave modules..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(dirname "$0")/../modules"

# Function to create module.yaml
create_module_yaml() {
    local module_path="$1"
    local module_name="$2"
    local category="$3"
    local description="$4"
    
    cat > "$module_path/module.yaml" << EOF
apiVersion: infraweave.io/v1
kind: Module
metadata:
  name: $module_name
  namespace: $REPO_NAME
  labels:
    category: $category
    provider: azure
    version: "1.0.0"
    security-level: "platform-2.0"
spec:
  moduleName: $module_name
  version: "1.0.0"
  description: "$description"
  provider:
    name: azurerm
    version: "~> 3.0"
  dependencies: []
  parameters:
    - name: name
      type: string
      required: true
      description: "Name of the resource"
    - name: resource_group_name
      type: string
      required: true
      description: "Name of the resource group"
    - name: location
      type: string
      required: true
      description: "Azure region for deployment"
  outputs:
    - name: id
      description: "ID of the created resource"
    - name: name
      description: "Name of the created resource"
  tags:
    infraweave.io/module: "$module_name"
    infraweave.io/version: "1.0.0"
    infraweave.io/category: "$category"
EOF
}

# Function to create versions.tf
create_versions_tf() {
    local module_path="$1"
    
    cat > "$module_path/versions.tf" << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
EOF
}

# Function to create basic main.tf
create_main_tf() {
    local module_path="$1"
    local resource_type="$2"
    
    cat > "$module_path/main.tf" << EOF
# $resource_type module
# This module creates an Azure $resource_type with Platform 2.0 security features

locals {
  common_tags = merge(var.tags, {
    "infraweave.io/module"   = "$resource_type"
    "infraweave.io/version"  = "1.0.0"
    "infraweave.io/managed"  = "true"
  })
}

# TODO: Implement $resource_type resource configuration
# This is a placeholder - implement the actual Azure resource here
# Example:
# resource "azurerm_example" "this" {
#   name                = var.name
#   resource_group_name = var.resource_group_name
#   location           = var.location
#   
#   tags = local.common_tags
# }
EOF
}

# Function to create variables.tf
create_variables_tf() {
    local module_path="$1"
    
    cat > "$module_path/variables.tf" << 'EOF'
variable "name" {
  description = "Name of the resource"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "tags" {
  description = "Additional tags for the resource"
  type        = map(string)
  default     = {}
}
EOF
}

# Function to create outputs.tf
create_outputs_tf() {
    local module_path="$1"
    
    cat > "$module_path/outputs.tf" << 'EOF'
output "id" {
  description = "ID of the created resource"
  value       = "placeholder-id" # TODO: Replace with actual resource ID
}

output "name" {
  description = "Name of the created resource"
  value       = var.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "location" {
  description = "Location of the resource"
  value       = var.location
}
EOF
}

# List of modules to scaffold (path:module_name:category:description)
MODULES=(
    "compute/virtual-machine-scale-set:VirtualMachineScaleSet:compute:Azure Virtual Machine Scale Set with auto-scaling capabilities"
    "containers/aks-cluster:AKSCluster:containers:Azure Kubernetes Service cluster with Platform 2.0 security"
    "containers/container-instance:ContainerInstance:containers:Azure Container Instances for serverless containers"
    "database/cosmosdb:CosmosDB:database:Azure Cosmos DB multi-model database service"
    "database/mysql:MySQL:database:Azure Database for MySQL flexible server"
    "foundation/management-group:ManagementGroup:foundation:Azure Management Group for governance hierarchy"
    "foundation/subscription:Subscription:foundation:Azure Subscription configuration and governance"
    "monitoring/log-analytics:LogAnalytics:monitoring:Azure Log Analytics workspace for centralized logging"
    "monitoring/monitor-alerts:MonitorAlerts:monitoring:Azure Monitor alerts and notification rules"
    "networking/application-gateway:ApplicationGateway:networking:Azure Application Gateway for Layer 7 load balancing"
    "networking/load-balancer:LoadBalancer:networking:Azure Load Balancer for Layer 4 load balancing"
    "networking/route-table:RouteTable:networking:Azure Route Table for custom routing configurations"
    "networking/vpn-gateway:VPNGateway:networking:Azure VPN Gateway for site-to-site connectivity"
    "security/security-center:SecurityCenter:security:Azure Security Center configuration and policies"
    "storage/file-share:FileShare:storage:Azure Files share configuration and management"
    "storage/managed-disk:ManagedDisk:storage:Azure Managed Disk for VM storage"
)

# Process each module
for module_info in "${MODULES[@]}"; do
    IFS=':' read -r module_path module_name category description <<< "$module_info"
    full_path="$BASE_DIR/$module_path"
    
    echo -e "${YELLOW}📦 Processing module: $module_path${NC}"
    
    # Create module.yaml if it doesn't exist
    if [ ! -f "$full_path/module.yaml" ]; then
        echo "  ✨ Creating module.yaml"
        create_module_yaml "$full_path" "$module_name" "$category" "$description"
    else
        echo "  ✅ module.yaml already exists"
    fi
    
    # Update placeholder files if they're empty or contain only comments
    if [ ! -s "$full_path/versions.tf" ] || grep -q "^# versions.tf" "$full_path/versions.tf" 2>/dev/null; then
        echo "  ✨ Creating versions.tf"
        create_versions_tf "$full_path"
    else
        echo "  ✅ versions.tf already complete"
    fi
    
    if [ ! -s "$full_path/main.tf" ] || grep -q "^# main.tf" "$full_path/main.tf" 2>/dev/null; then
        echo "  ✨ Creating main.tf"
        create_main_tf "$full_path" "$module_name"
    else
        echo "  ✅ main.tf already complete"
    fi
    
    if [ ! -s "$full_path/variables.tf" ] || grep -q "^# variables.tf" "$full_path/variables.tf" 2>/dev/null; then
        echo "  ✨ Creating variables.tf"
        create_variables_tf "$full_path"
    else
        echo "  ✅ variables.tf already complete"
    fi
    
    if [ ! -s "$full_path/outputs.tf" ] || grep -q "^# outputs.tf" "$full_path/outputs.tf" 2>/dev/null; then
        echo "  ✨ Creating outputs.tf"
        create_outputs_tf "$full_path"
    else
        echo "  ✅ outputs.tf already complete"
    fi
    
    echo -e "${GREEN}  ✅ Module $module_path completed${NC}"
    echo ""
done

echo -e "${GREEN}🎉 All modules have been scaffolded!${NC}"
echo ""
echo "Next steps:"
echo "1. Run validation: ./scripts/validate-modules.sh"
echo "2. Implement actual resource configurations in main.tf files"
echo "3. Update module-specific variables and outputs"
echo "4. Add comprehensive documentation and examples"
