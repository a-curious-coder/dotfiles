# Dotfiles Sync Guide

Guide for synchronizing your dotfiles across multiple machines using the `sync-dotfiles` script.

## Overview

The sync script helps you:
- Push dotfiles changes from one machine to a Git repository
- Pull dotfiles changes to other machines
- Track which machines have your dotfiles
- Create automatic backups before pulling changes
- Monitor sync status across machines

## Prerequisites

1. **Git repository**: Your dotfiles must be in a Git repository
2. **Remote configured**: Set up a remote (GitHub, GitLab, etc.)
3. **SSH keys** (recommended): For passwordless authentication

## Setup

### Initial Setup on First Machine

1. **Initialize Git repository** (if not already done):
   ```bash
   cd ~/Desktop/Projects/dotfiles
   git init
   git add .
   git commit -m "Initial dotfiles commit"
   ```

2. **Add remote repository**:
   ```bash
   # GitHub
   git remote add origin git@github.com:username/dotfiles.git

   # GitLab
   git remote add origin git@gitlab.com:username/dotfiles.git
   ```

3. **Push to remote**:
   ```bash
   git push -u origin main
   ```

4. **Make sync script executable**:
   ```bash
   chmod +x sync-dotfiles
   ```

### Setup on Additional Machines

1. **Clone your dotfiles**:
   ```bash
   git clone git@github.com:username/dotfiles.git ~/Desktop/Projects/dotfiles
   cd ~/Desktop/Projects/dotfiles
   ```

2. **Make sync script executable**:
   ```bash
   chmod +x sync-dotfiles
   ```

3. **Run setup**:
   ```bash
   ./setup --interactive
   ```

## Usage

### Push Changes (After Making Modifications)

```bash
./sync-dotfiles push
```

This will:
1. Show you what changed
2. Ask for confirmation
3. Request a commit message
4. Commit and push changes to remote
5. Update machine profile

**Example:**
```bash
$ ./sync-dotfiles push
================================
  Dotfiles Sync Manager
================================

ℹ Pushing dotfiles to remote repository...

Modified files:
 M zsh/.zshrc
 M nvim/.config/nvim/lua/plugins/lsp.lua

Do you want to commit and push these changes? [y/N] y

Enter commit message (or press enter for default): Add new LSP config
[main 1a2b3c4] Add new LSP config
 2 files changed, 15 insertions(+), 3 deletions(-)
✓ Successfully pushed to remote!
```

### Pull Changes (On Other Machines)

```bash
./sync-dotfiles pull
```

This will:
1. Check for local changes
2. Offer to create a backup
3. Pull latest changes from remote
4. Remind you to apply changes with stow

**Example:**
```bash
$ ./sync-dotfiles pull
================================
  Dotfiles Sync Manager
================================

ℹ Pulling dotfiles from remote repository...
⚠ You have local changes!
 M zsh/.zsh_aliases

Create backup before pulling? [Y/n] y
ℹ Creating backup...
✓ Backup created: .backups/20240115_143022
✓ Successfully pulled from remote!
ℹ Run './setup' or 'stow <package>' to apply changes
```

### Check Status

```bash
./sync-dotfiles status
```

Shows:
- Git status (modified files)
- Current branch and remote
- How many commits behind/ahead of remote
- Current machine info
- Last sync timestamp

**Example output:**
```bash
$ ./sync-dotfiles status
================================
  Dotfiles Sync Manager
================================

ℹ Dotfiles Status

Git Status:
 M zsh/.zshrc

Branch: main
Remote: origin

Sync Status:
  Behind remote: 0 commits
  Ahead of remote: 1 commits

Current Machine: workstation
OS: Linux x86_64
Last Sync: 2024-01-15T14:22:30+00:00
```

### View Differences

```bash
./sync-dotfiles diff
```

Shows what changed between your local version and remote.

### List Registered Machines

```bash
./sync-dotfiles list-machines
```

Shows all machines that have synced dotfiles:

```bash
$ ./sync-dotfiles list-machines
================================
  Dotfiles Sync Manager
================================

ℹ Registered Machines

Machine: workstation
  OS: Linux
  Last Sync: 2024-01-15T14:22:30+00:00

Machine: laptop
  OS: Darwin
  Last Sync: 2024-01-14T09:15:42+00:00
```

## Workflow Examples

### Scenario 1: Simple Sync Between Two Machines

**On Machine A (Work Desktop):**
```bash
# Made some changes to zshrc
vim zsh/.zshrc

# Push changes
./sync-dotfiles push
# Enter: "Add new git aliases"
```

**On Machine B (Laptop):**
```bash
# Pull latest changes
./sync-dotfiles pull

# Apply changes
stow zsh

# Reload shell
source ~/.zshrc
```

### Scenario 2: Multiple Contributors

**Developer 1:**
```bash
# Check status first
./sync-dotfiles status

# Pull latest changes
./sync-dotfiles pull

# Make changes
vim nvim/.config/nvim/lua/plugins/new-plugin.lua

# Push changes
./sync-dotfiles push
```

**Developer 2:**
```bash
# Pull before starting work
./sync-dotfiles pull

# Work on different files
vim tmux/.tmux.conf

# Push your changes
./sync-dotfiles push
```

### Scenario 3: Conflict Resolution

If you have local changes and remote changes:

```bash
# Check what's different
./sync-dotfiles diff

# Status shows you're behind
./sync-dotfiles status

# Create backup and pull
./sync-dotfiles pull
# Backup created automatically

# If conflicts occur, resolve manually
git status
# Edit conflicted files
git add <resolved-files>
git rebase --continue

# Push resolved changes
./sync-dotfiles push
```

## Best Practices

### 1. Pull Before Making Changes

Always pull latest changes before editing:
```bash
./sync-dotfiles pull
```

### 2. Commit Related Changes Together

Group related changes in one commit:
```bash
# Edit multiple related files
vim zsh/.zshrc
vim zsh/.zsh_aliases

# Push together with meaningful message
./sync-dotfiles push
# Message: "Add Docker and Kubernetes aliases"
```

### 3. Use Descriptive Commit Messages

Bad:
```
update stuff
fix
changes
```

Good:
```
feat: add Vue.js LSP configuration
fix: correct tmux prefix key binding
refactor: reorganize git aliases
docs: update README with Bruno setup
```

### 4. Regular Syncs

Sync regularly to avoid conflicts:
- Start of day: `./sync-dotfiles pull`
- After changes: `./sync-dotfiles push`
- End of day: `./sync-dotfiles push`

### 5. Backup Important Changes

Before major changes, create a manual backup:
```bash
cp -r ~/.config/nvim ~/.config/nvim.backup
./sync-dotfiles pull
```

### 6. Review Changes Before Pushing

Always review what you're pushing:
```bash
./sync-dotfiles status
git diff
./sync-dotfiles push
```

## Machine Profiles

Each machine creates a profile in `.machines/<hostname>.json`:

```json
{
  "hostname": "workstation",
  "os": "Linux",
  "arch": "x86_64",
  "created_at": "2024-01-15T10:00:00+00:00",
  "last_sync": "2024-01-15T14:30:00+00:00",
  "stowed_packages": []
}
```

This helps track:
- Which machines have your dotfiles
- When each machine last synced
- OS-specific configurations

## Backup Management

Backups are created in `.backups/<timestamp>/`:

```bash
# View backups
ls -la .backups/

# Restore from backup if needed
cp -r .backups/20240115_143022/zsh/.zshrc zsh/.zshrc
```

**Backup cleanup:**
```bash
# Remove old backups (older than 30 days)
find .backups -type d -mtime +30 -exec rm -rf {} +
```

## Troubleshooting

### Problem: "Failed to push"

**Solution:**
```bash
# Pull first, resolve conflicts, then push
./sync-dotfiles pull
# Fix any conflicts
./sync-dotfiles push
```

### Problem: "Not a git repository"

**Solution:**
```bash
cd ~/Desktop/Projects/dotfiles
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

### Problem: "Permission denied (publickey)"

**Solution:**
Set up SSH keys:
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key and add to GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
```

### Problem: Merge conflicts

**Solution:**
```bash
# View conflicted files
git status

# Edit files to resolve conflicts
vim <conflicted-file>

# Mark as resolved
git add <resolved-file>
git rebase --continue

# Push resolved version
./sync-dotfiles push
```

### Problem: Accidentally pushed sensitive data

**Solution:**
```bash
# Remove from history (dangerous!)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive/file" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (be careful!)
git push origin --force --all
```

## Advanced Usage

### Sync Specific Files Only

```bash
# Stage specific files
git add zsh/.zshrc
git commit -m "Update zshrc only"
git push
```

### Create Branches for Experiments

```bash
# Create experimental branch
git checkout -b experiment/new-nvim-config

# Make changes and push
git add nvim/
git commit -m "Experimental Neovim config"
git push -u origin experiment/new-nvim-config

# Merge when ready
git checkout main
git merge experiment/new-nvim-config
./sync-dotfiles push
```

### Sync Subsets of Dotfiles

Create different repositories for different purposes:
```bash
# Main dotfiles
git clone git@github.com:user/dotfiles.git ~/dotfiles

# Work-specific dotfiles
git clone git@github.com:user/dotfiles-work.git ~/dotfiles-work

# Personal dotfiles
git clone git@github.com:user/dotfiles-personal.git ~/dotfiles-personal
```

## Integration with CI/CD

You can set up automated tests for your dotfiles:

```yaml
# .github/workflows/test.yml
name: Test Dotfiles
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test Stow
        run: |
          sudo apt-get install stow
          ./setup --mode dotfiles --dry-run
```

## Security Considerations

1. **Never commit secrets**: Use `.gitignore` for sensitive files
   ```gitignore
   .env
   .env.local
   **/*.key
   **/*.pem
   **/credentials.json
   ```

2. **Use environment variables**: For API keys and tokens
   ```bash
   # In .zshrc
   export API_KEY="${API_KEY:-}"
   ```

3. **Separate sensitive configs**: Keep work configs separate
   ```bash
   # Load work-specific aliases only on work machine
   [[ -f ~/.zsh_aliases_work ]] && source ~/.zsh_aliases_work
   ```

4. **Review before pushing**: Always check what you're committing
   ```bash
   git diff --cached
   ```

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub SSH Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Dotfiles Best Practices](https://dotfiles.github.io/)

---

**Quick Reference:**

```bash
./sync-dotfiles push          # Push local changes
./sync-dotfiles pull          # Pull remote changes
./sync-dotfiles status        # Check sync status
./sync-dotfiles diff          # View differences
./sync-dotfiles list-machines # List synced machines
./sync-dotfiles help          # Show help
```
