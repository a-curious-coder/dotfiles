#!/usr/bin/env bash

# ┌─────────────────────────────────────────────────────────────┐
# │ Neovim Configuration Test Script                           │
# │ Purpose: Validate nvim configuration before deployment      │
# └─────────────────────────────────────────────────────────────┘

# Note: Not using 'set -e' to allow all tests to run even if some fail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Neovim Configuration Test Suite ===${NC}\n"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo -e "\n${BLUE}### $1 ###${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_DIR="$SCRIPT_DIR/.config/nvim"

# ============================================
# Test 1: Directory Structure
# ============================================
section "Directory Structure"

if [[ -f "$NVIM_DIR/init.lua" ]]; then
    pass "init.lua exists"
else
    fail "init.lua not found"
fi

if [[ -f "$NVIM_DIR/lua/vim-options.lua" ]]; then
    pass "vim-options.lua exists"
else
    fail "vim-options.lua not found"
fi

if [[ -d "$NVIM_DIR/lua/lsp" ]]; then
    pass "lsp directory exists"
else
    fail "lsp directory not found"
fi

if [[ -d "$NVIM_DIR/lua/plugins" ]]; then
    pass "plugins directory exists"
else
    fail "plugins directory not found"
fi

# ============================================
# Test 2: LSP Configuration Files
# ============================================
section "LSP Configuration"

for file in servers.lua keymaps.lua utils.lua; do
    if [[ -f "$NVIM_DIR/lua/lsp/$file" ]]; then
        pass "lsp/$file exists"
    else
        fail "lsp/$file not found"
    fi
done

# ============================================
# Test 3: Lua Syntax Validation
# ============================================
section "Lua Syntax Validation"

# Check if nvim is installed
if ! command -v nvim &> /dev/null; then
    warn "Neovim not installed - skipping syntax checks"
else
    NVIM_VERSION=$(nvim --version | head -n1)
    info "Testing with: $NVIM_VERSION"
    
    # Test init.lua
    if nvim --headless -c "luafile $NVIM_DIR/init.lua" -c "qa" 2>/dev/null; then
        pass "init.lua syntax valid"
    else
        fail "init.lua has syntax errors"
    fi
    
    # Test vim-options.lua
    if nvim --headless -c "luafile $NVIM_DIR/lua/vim-options.lua" -c "qa" 2>/dev/null; then
        pass "vim-options.lua syntax valid"
    else
        fail "vim-options.lua has syntax errors"
    fi
    
    # Test LSP files
    for file in servers.lua keymaps.lua utils.lua; do
        if nvim --headless -c "luafile $NVIM_DIR/lua/lsp/$file" -c "qa" 2>/dev/null; then
            pass "lsp/$file syntax valid"
        else
            fail "lsp/$file has syntax errors"
        fi
    done
fi

# ============================================
# Test 4: Documentation Files
# ============================================
section "Documentation"

cd "$SCRIPT_DIR"

for file in DESIGN_PLAN.md IMPLEMENTATION.md QUICKREF.md; do
    if [[ -f "$file" ]]; then
        pass "$file exists"
    else
        fail "$file not found"
    fi
done

if [[ -f "$NVIM_DIR/README.md" ]]; then
    pass "README.md exists"
else
    fail "README.md not found"
fi

# ============================================
# Test 5: Stow Compatibility
# ============================================
section "Stow Compatibility"

# Check directory structure matches Stow requirements
if [[ -d "$SCRIPT_DIR/.config" ]]; then
    pass "Stow-compatible directory structure (.config/nvim)"
else
    fail "Not Stow-compatible - missing .config directory"
fi

# Check for absolute paths (bad for portability)
if grep -r "\/Users\/" "$NVIM_DIR/lua" 2>/dev/null | grep -v "Binary file" | grep -q .; then
    fail "Found absolute paths in configuration"
else
    pass "No absolute paths in configuration"
fi

# Check for hardcoded home directory references
if grep -r "~/" "$NVIM_DIR/lua" 2>/dev/null | grep -v "Binary file" | grep -q .; then
    warn "Found ~ references (use \${HOME} or vim.fn.stdpath instead)"
else
    pass "No hardcoded home directory paths"
fi

# ============================================
# Test 6: Plugin Configuration
# ============================================
section "Plugin Configuration"

PLUGIN_COUNT=$(find "$NVIM_DIR/lua/plugins" -name "*.lua" -type f 2>/dev/null | wc -l | tr -d ' ')

if [[ $PLUGIN_COUNT -gt 0 ]]; then
    pass "Found $PLUGIN_COUNT plugin configuration files"
else
    fail "No plugin files found"
fi

# Check for common plugin files
for plugin in telescope.lua lsp-config.lua completions.lua; do
    if [[ -f "$NVIM_DIR/lua/plugins/$plugin" ]]; then
        pass "plugins/$plugin exists"
    else
        warn "plugins/$plugin not found (optional)"
    fi
done

# ============================================
# Test 7: Required Dependencies Check
# ============================================
section "System Dependencies"

# Check for Git
if command -v git &> /dev/null; then
    pass "Git installed: $(git --version | head -n1)"
else
    fail "Git not installed (required for plugin installation)"
fi

# Check for Node.js
if command -v node &> /dev/null; then
    pass "Node.js installed: $(node --version)"
else
    warn "Node.js not installed (required for LSP servers)"
fi

# Check for ripgrep
if command -v rg &> /dev/null; then
    pass "ripgrep installed: $(rg --version | head -n1)"
else
    warn "ripgrep not installed (required for Telescope grep)"
fi

# Check for fd
if command -v fd &> /dev/null; then
    pass "fd installed: $(fd --version)"
else
    warn "fd not installed (optional but recommended)"
fi

# ============================================
# Test 8: File Content Validation
# ============================================
section "Content Validation"

# Check init.lua contains lazy.nvim bootstrap
if grep -q "lazy.nvim" "$NVIM_DIR/init.lua"; then
    pass "init.lua contains lazy.nvim bootstrap"
else
    fail "init.lua missing lazy.nvim bootstrap"
fi

# Check vim-options.lua sets leader key
if grep -q "mapleader" "$NVIM_DIR/lua/vim-options.lua"; then
    pass "vim-options.lua sets leader key"
else
    fail "vim-options.lua missing leader key configuration"
fi

# Check lsp/servers.lua has server configs
if grep -q "server_configs" "$NVIM_DIR/lua/lsp/servers.lua"; then
    pass "lsp/servers.lua contains server configurations"
else
    fail "lsp/servers.lua missing server configurations"
fi

# ============================================
# Test 9: No Duplicates Check
# ============================================
section "Duplicate Settings Check"

# Check for duplicate vim.opt.number
if [[ $(grep -c "vim.opt.number = true" "$NVIM_DIR/lua/vim-options.lua" 2>/dev/null) -gt 1 ]]; then
    fail "Duplicate vim.opt.number found in vim-options.lua"
else
    pass "No duplicate vim.opt.number settings"
fi

# Check for duplicate leader key definitions
if [[ $(grep -c "mapleader" "$NVIM_DIR/lua/vim-options.lua" 2>/dev/null) -gt 2 ]]; then
    fail "Multiple leader key definitions found"
else
    pass "Single leader key definition (normal)"
fi

# ============================================
# Test 10: Documentation Quality
# ============================================
section "Documentation Quality"

# Check README has prerequisites section
if grep -qi "prerequisite" "$NVIM_DIR/README.md"; then
    pass "README includes prerequisites"
else
    warn "README missing prerequisites section"
fi

# Check README has installation section
if grep -qi "installation" "$NVIM_DIR/README.md"; then
    pass "README includes installation section"
else
    fail "README missing installation section"
fi

# Check for keybinding documentation
if grep -qi "key\|keybinding\|keymap" "$NVIM_DIR/README.md"; then
    pass "README includes keybinding documentation"
else
    warn "README missing keybinding documentation"
fi

# ============================================
# Summary
# ============================================
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✓ All tests passed! Configuration is ready.${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed. Please review the output above.${NC}"
    exit 1
fi
