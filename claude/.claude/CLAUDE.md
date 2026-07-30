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

# context-mode

Raw tool output floods your context window. Use context-mode MCP tools to keep raw data in the sandbox.

## Tool Selection

1. **GATHER**: `batch_execute(commands, queries)` — Primary tool for research. Runs all commands, auto-indexes, and searches. ONE call replaces many individual steps.
2. **FOLLOW-UP**: `search(queries: ["q1", "q2", ...])` — Use for all follow-up questions. ONE call, many queries.
3. **PROCESSING**: `execute(language, code)` or `execute_file(path, language, code)` — Use for API calls, log analysis, and data processing.
4. **WEB**: `fetch_and_index(url)` then `search(queries)` — Fetch, index, then query. Never dump raw HTML.

## Rules

- DO NOT use Bash for commands producing >20 lines of output — use `execute` or `batch_execute`.
- DO NOT use Read for analysis — use `execute_file`. Read IS correct for files you intend to Edit.
- DO NOT use WebFetch — use `fetch_and_index` instead.
- DO NOT use curl/wget in Bash — use `execute` or `fetch_and_index`.
- Bash is ONLY for git, mkdir, rm, mv, navigation, and short commands.

## Output

- Keep responses under 500 words.
- Write artifacts (code, configs) to FILES — never return them as inline text.
- Return only: file path + 1-line description.
