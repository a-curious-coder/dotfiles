
# GitHub Copilot Instructions for Dotfiles Repository

## Repository Context
This is a dotfiles repository using GNU Stow for symlink management, zsh shell configuration, and Ghostty terminal emulator.

## Code Generation Guidelines

### File Structure & Organization
- Follow standard dotfiles conventions with dot-prefixed directories
- Use Stow-compatible directory structure (each application in its own folder)
- Maintain clear separation between different tool configurations

### Shell Configuration (zsh)
- Use modern zsh best practices and Oh My Zsh compatibility
- Include proper error handling and conditionals for missing dependencies
- Use `${HOME}` instead of `~` in scripts for better portability
- Add comments explaining non-obvious configurations

### Terminal Configuration (Ghostty)
- Follow Ghostty's TOML configuration format
- Include accessible color schemes and font settings
- Provide sensible defaults for performance and usability

### Stow Management
- Generate Stow-compatible directory structures
- Include `.stowrc` configuration when relevant
- Suggest proper Stow commands for installation/removal

### Documentation
- Include clear installation instructions
- Provide examples for common use cases
- Document dependencies and prerequisites
- Use accessible language and avoid jargon

### Accessibility Focus
- Prioritize readable configurations over complex optimizations
- Include helpful comments and documentation
- Suggest user-friendly aliases and functions
- Provide fallbacks for missing tools or features

### Best Practices
- Use version control friendly formats
- Avoid hardcoded paths when possible
- Include backup and restore procedures
- Follow XDG Base Directory specification where applicable

USE mcp-compass MCP server to best decide which mcp servers to use.
