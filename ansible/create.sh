#!/usr/bin/env bash
set -euo pipefail

# Adjust inventory file path as needed
ANSIBLE_INVENTORY="inventory"

echo "Running creation steps..."
ansible-playbook -i "$ANSIBLE_INVENTORY" main.yml \
  --tags "create-keys,deploy1,deploy2,deploy3,chaininfo"
