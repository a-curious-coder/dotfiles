cached_init /opt/homebrew/bin/brew shellenv
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"

# Added by Toolbox App
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Added by Obsidian
[[ -d "/Applications/Obsidian.app/Contents/MacOS" ]] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# direnv + pg16 PATH setup live in .zshrc (interactive shells source it right
# after this file); .zshenv covers non-interactive shells' PATH.
