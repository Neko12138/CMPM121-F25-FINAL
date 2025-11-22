#!/usr/bin/env bash
set -e

echo "🔧 Running setup-hooks.sh..."

# Ensure Lua exists (Codespace sometimes needs reinstall on restart)
if ! command -v lua >/dev/null 2>&1 && ! command -v lua5.4 >/dev/null 2>&1; then
    echo "📦 Installing Lua..."

    # Prefer apk if we are on Alpine
    if command -v apk >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            apk update
            apk add --no-cache lua5.4 || apk add --no-cache lua
        else
            sudo apk update
            sudo apk add --no-cache lua5.4 || sudo apk add --no-cache lua
        fi
    else
        # Fallback for Debian/Ubuntu images
        if [ "$(id -u)" -eq 0 ]; then
            apt-get update
            apt-get install -y lua5.4 || apt-get install -y lua
        else
            sudo apt-get update
            sudo apt-get install -y lua5.4 || sudo apt-get install -y lua
        fi
    fi
fi

# Configure Git hooks path (idempotent)
git config core.hooksPath .githooks || true

# Make sure pre-commit is executable
chmod +x .githooks/pre-commit || true

# Try to set the git index executable bit so that the file remains executable when cloned
git update-index --add --chmod=+x .githooks/pre-commit >/dev/null 2>&1 || true

echo "✅ setup-hooks.sh completed."
