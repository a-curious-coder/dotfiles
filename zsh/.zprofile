
cached_init /opt/homebrew/bin/brew shellenv

# Added by Toolbox App
export PATH="$PATH:/Users/callummclennan/Library/Application Support/JetBrains/Toolbox/scripts"

if [[ -z "${TMUX:-}" ]]; then
  # Avoid startup lock contention from implicit `pyenv rehash`.
  cached_init pyenv init --path --no-rehash
fi

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# direnv + pg16 PATH setup live in .zshrc (interactive shells source it right
# after this file); .zshenv covers non-interactive shells' PATH.
