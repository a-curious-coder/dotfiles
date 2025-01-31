# Neovim Keybindings Documentation

## Global
- `<Space>` - Leader key

## File Navigation
- `<C-n>` - Open Neo-tree file explorer
- `<leader>e` - Toggle Neo-tree
- `<C-p>` - Find git files (Telescope)
- `<leader>pf` - Find all files (Telescope)
- `<leader>ps` - Grep search with input
- `<leader>pws` - Search word under cursor
- `<leader>pWs` - Search WORD under cursor
- `<leader><leader>` - Show recent files
- `-` - Toggle oil.nvim float

## Buffer Management (Barbar)
- `<leader>bp` - Previous buffer
- `<leader>bn` - Next buffer
- `<leader>bc` - Delete current buffer
- `<leader>bl` - Go to last buffer
- `<leader>1-9` - Go to buffer 1-9
- `<A-<>` - Move buffer left
- `<A->>` - Move buffer right
- `<A-p>` - Pin buffer
- `<leader>bT` - Toggle buffer bar
- `<leader>bf` - Open buffer explorer in float

## Window Navigation
- `<C-h>` - Move to left window
- `<C-j>` - Move to down window
- `<C-k>` - Move to up window
- `<C-l>` - Move to right window

## Quick File Access (Harpoon)
- `<leader>a` - Add file to harpoon
- `<C-e>` - Toggle harpoon menu
- `<C-t>` - Navigate to file 1
- `<C-s>` - Navigate to file 2
- `<C-b>` - Navigate to file 3
- `<C-g>` - Navigate to file 4

## LSP and Code Navigation
- `K` - Show documentation
- `<leader>gd` - Go to definition
- `<leader>gr` - Find references
- `<leader>ca` - Code actions
- `<leader>f` - Format file

## Git Integration
- `<leader>gs` - Git status (Neo-tree)
- `<leader>gp` - Preview hunk (Gitsigns)
- `<leader>gt` - Toggle line blame
- `<leader>gg` - Open LazyGit
- `<leader>gf` - LazyGit file history
- `<leader>gl` - LazyGit log
- `<leader>gB` - Git browse
- `<leader>gb` - Git blame line

## Testing
- `<leader>t` - Test nearest
- `<leader>T` - Test file
- `<leader>a` - Test suite
- `<leader>l` - Test last
- `<leader>g` - Test visit

## Debugging
- `<leader>dt` - Toggle breakpoint
- `<leader>dc` - Continue
- `<leader>dj` - Step over
- `<leader>di` - Step into
- `<leader>do` - Step out
- `<leader>dr` - Open REPL
- `<leader>dl` - Run last
- `<leader>du` - Toggle UI
- `<leader>db` - List breakpoints
- `<leader>dv` - Show variables
- `<leader>df` - Show frames

## Code Folding
- `zR` - Open all folds
- `zM` - Close all folds
- `zK` - Peek fold under cursor

## UI Toggles
- `<leader>us` - Toggle spelling
- `<leader>uw` - Toggle wrap
- `<leader>uL` - Toggle relative numbers
- `<leader>ud` - Toggle diagnostics
- `<leader>ul` - Toggle line numbers
- `<leader>uc` - Toggle conceallevel
- `<leader>uT` - Toggle treesitter
- `<leader>ub` - Toggle dark/light background
- `<leader>uh` - Toggle inlay hints
- `<leader>ug` - Toggle indent
- `<leader>uD` - Toggle dim
- `<leader>un` - Dismiss notifications

## Terminal
- `<c-_>` - Toggle terminal

## Navigation
- `]]` - Next reference
- `[[` - Previous reference

## Potential Conflicts:
1. `<leader>a` is used by both:
   - Harpoon (Add file)
   - Test suite runner
   
2. `<leader>g` is used by both:
   - Test visit
   - Multiple git commands (gs, gp, gt, etc.)

3. `<C-h/j/k/l>` might conflict between:
   - Window navigation
   - tmux navigation (but handled by the plugin)

## Notes:
- Most keybindings are well-organized and follow logical groupings
- The `<leader>` key (Space) is heavily utilized but organized by category
- Git commands are consistently prefixed with `<leader>g`
- UI toggles are consistently prefixed with `<leader>u`
- Debug commands are consistently prefixed with `<leader>d` 