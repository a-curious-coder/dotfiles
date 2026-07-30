# User preferences

- Address the user by their first name in every response.

## Shell tools

`fd` and `rg` are installed and are the preferred CLI tools on this machine.

- Searching file *contents*: use the **Grep** tool. It is ripgrep already, and it
  does not spend a Bash call. Shell out to `rg` only for flags Grep lacks.
- Finding files *by name*: use the **Glob** tool. When a shell call is genuinely
  needed, use `fd`, never `find`.
- In any Bash command, pipeline, or script: `rg` not `grep`, `fd` not `find`.
  This includes the middle of a pipe.
- `fd` skips `.gitignore`d paths and hidden files by default. Add `-H` for hidden
  and `-I` for ignored when a full sweep is the point — a bare `fd` is not a
  drop-in `find .`.

**`cd` is zoxide.** `.zshrc` runs `zoxide init zsh --cmd cd`, and this applies
inside agent shells too. `cd <name>` does frecency matching, so a path that does
not exist does not fail — it jumps to whichever remembered directory scores
highest, possibly in another project. Always pass absolute paths to Bash, and
prefer a tool's own path argument over changing directory at all.

<!-- Machine-local personal values (e.g. the actual name) live in the
     gitignored CLAUDE.local.md, imported below. Never commit that file. -->
@CLAUDE.local.md
