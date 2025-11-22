#!/usr/bin/env bash
set -e

echo "🔧 Running setup-hooks.sh..."

# Ensure Lua exists (Codespace sometimes needs reinstall on restart)
if ! command -v lua >/dev/null 2>&1 && ! command -v lua5.4 >/dev/null 2>&1; then
    echo "📦 Installing Lua..."
    sudo apt-get update
    sudo apt-get install -y lua5.4
fi

# Configure Git hooks path
git config core.hooksPath .githooks

# Make sure pre-commit is executable
chmod +x .githooks/pre-commit

echo "✅ setup-hooks.sh completed."
