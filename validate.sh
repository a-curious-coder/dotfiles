#!/usr/bin/env bash

# Quick Validation Script
# =======================
# Simple tests for the unified dotfiles system

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Validating Unified Dotfiles System"
echo "======================================"

# Test 1: Check main entry points exist
echo -n "✓ Checking main entry points... "
if [[ -x "$DOTFILES_DIR/setup" ]] && [[ -x "$DOTFILES_DIR/scripts/install-unified.sh" ]]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Check configuration file
echo -n "✓ Checking configuration file... "
if [[ -f "$DOTFILES_DIR/packages.yaml" ]]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Test help output
echo -n "✓ Testing help output... "
if "$DOTFILES_DIR/setup" --help > /dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: Test dry-run
echo -n "✓ Testing dry-run functionality... "
if "$DOTFILES_DIR/setup" --dry-run > /dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Test list functionality
echo -n "✓ Testing list functionality... "
if "$DOTFILES_DIR/scripts/install-unified.sh" --list-categories > /dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo
echo "🎉 All validation tests passed!"
echo "✨ The unified dotfiles system is ready to use."
echo
echo "Quick start:"
echo "  ./setup --help           # Show usage information"
echo "  ./setup --dry-run        # Preview what will be installed"
echo "  ./setup --interactive    # Choose what to install"
echo "  ./setup                  # Full installation"
