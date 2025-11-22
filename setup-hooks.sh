#!/usr/bin/env bash
set -e

echo "🔧 Running setup-hooks.sh..."

# Ensure Lua exists (Codespace sometimes needs reinstall on restart)
if ! command -v lua >/dev/null 2>&1 && ! command -v lua5.4 >/dev/null 2>&1; then
    echo "📦 Installing Lua..."

    # Prefer apk if we are on Alpine
    if command -v apk >/dev/null 2>&1; then
        sudo apk update
        # try lua5.4 first, fall back to lua
        sudo apk add --no-cache lua5.4 || sudo apk add --no-cache lua
    else
        # Fallback for Debian/Ubuntu images
        sudo apt-get update
        sudo apt-get install -y lua5.4 || sudo apt-get install -y lua
    fi
fi

# Configure Git hooks path
git config core.hooksPath .githooks

# Make sure pre-commit is executable
chmod +x .githooks/pre-commit

echo "✅ setup-hooks.sh completed."
