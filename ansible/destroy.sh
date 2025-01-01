#!/usr/bin/env bash
set -euo pipefail

# Adjust inventory file path as needed
ANSIBLE_INVENTORY="inventory"

echo "Running destruction steps..."
ansible-playbook -i "$ANSIBLE_INVENTORY" main.yml \
  --tags "destroy1,destroy2,destroy3"
