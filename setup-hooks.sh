#!/usr/bin/env bash
set -e

echo "🔧 Running setup-hooks.sh..."

# 1. Ensure Lua and Luac are installed (Alpine/Debian support)
if ! command -v lua >/dev/null 2>&1 && ! command -v lua5.4 >/dev/null 2>&1; then
    echo "📦 Installing Lua..."
    if command -v apk >/dev/null 2>&1; then
        # Alpine: 'lua5.4' package usually includes luac
        sudo apk update && sudo apk add --no-cache lua5.4 || sudo apk add --no-cache lua
    else
        # Debian/Ubuntu
        sudo apt-get update && sudo apt-get install -y lua5.4 || sudo apt-get install -y lua
    fi
fi

# 2. Force Git to use the .githooks directory
# We run this globally and locally to ensure it catches the environment
git config core.hooksPath .githooks

# 3. Set permissions
chmod +x .githooks/pre-commit
chmod +x setup-hooks.sh

# 4. Register file changes to git index (preserves permission in repo)
git update-index --add --chmod=+x .githooks/pre-commit 2>/dev/null || true
git update-index --add --chmod=+x setup-hooks.sh 2>/dev/null || true

echo "✅ Git hooks configured. Pre-commit checks are active."