## Core Configuration
## ==================
if status is-interactive
    ## Platform Detection
    ## ------------------
    if string match -qr Darwin (uname)
        # macOS settings
        set -gx HOMEBREW_PREFIX "/opt/homebrew"
    else if string match -qr Linux (uname)
        # Linux settings
        set -gx HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew"
        fish_add_path $HOME/.rbenv/bin
    end
    set -gx GEM_HOME $HOME/.gem

    ## Path Management
    ## -----------------------------
    # Base paths
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/bin

    set -x GOROOT /usr/local/go
    set -x GOPATH $HOME/go
    fish_add_path $GOPATH/bin $GOROOT/bin


    # Platform-specific paths
    if test -d $HOMEBREW_PREFIX/bin
        fish_add_path $HOMEBREW_PREFIX/bin
    end

    # Common development tools
    fish_add_path $HOME/.cargo/bin
    fish_add_path $HOME/go/bin

    ## Visual Environment
    ## ------------------
    # colors
    set fish_color_command green
    set fish_color_param cyan
    
    # Clear section headers
    function fish_greeting
        echo -s (set_color brblue) "🚀 Config Loaded: " (set_color yellow) (date +%H:%M)
    end

    ## Helpers
    ## ------------
    # Quick config reload
    function reload --wraps source
        source ~/.config/fish/config.fish
        echo -s (set_color green) "♻️  Config Reloaded!"
    end

    # Visual file listing
    alias ls "lsd --group-dirs first"
    alias ll "ls -lh"
    alias la "ls -a"
    alias l "ls -lah"
    alias lt "ls --tree"

    ## Development Setup
    ## ----------------
    # Editor detection
    if set -q SSH_CONNECTION
        set -gx EDITOR vim
    else
        set -gx EDITOR nvim
    end

    # Port killer
    function killport --argument port
        echo "🔫 Killing port $port"
        sudo kill -9 (sudo lsof -t -i:$port)
    end

    ## Cross-Platform Tools
    ## --------------------
    # Homebrew setup
    if test -d $HOMEBREW_PREFIX
        set -gx PATH $HOMEBREW_PREFIX/sbin $PATH
        set -gx MANPATH $HOMEBREW_PREFIX/share/man $MANPATH
        set -gx INFOPATH $HOMEBREW_PREFIX/share/info $INFOPATH
    end

    # Ruby environment
    status --is-interactive; and source (rbenv init -|psub)

    # Node Version Manager (install fisher first)
    if not functions -q nvm
        echo "📦 Install NVM support: fisher install jorgebucaran/nvm.fish"
    end
end

