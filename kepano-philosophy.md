# Kepano Philosophy Reference

Steph Ango (Kepano), CEO of Obsidian, has developed a workspace philosophy focused on longevity, minimalism, and reducing friction. This document distills his principles for application to desktop environments, themes, and tools.

---

## Core Principles

### 1. File Over App (Longevity)

Your data should outlive the software used to create it.

**Applied to desktop/theming:**
- Prefer plain text configs (JSONC, YAML, CSS) over binary formats or GUI-only settings
- Self-contained configs over complex include chains
- Avoid tool-specific abstractions that lock you in
- Comment the "why" in configs - your future self is the audience
- Version control your dotfiles

**Questions to ask:**
- Will this config be readable in 10 years?
- Can I migrate this to another tool if needed?
- Does this depend on something that might disappear?

---

### 2. Radical Minimalism & Legibility

Remove anything that isn't the content itself.

**Applied to desktop/theming:**
- Remove UI chrome: borders, shadows, rounded corners unless functional
- No decorations for decoration's sake
- High contrast, legible typography
- Disable animations and transitions (they draw attention to UI, not work)
- Hide what you don't actively use
- Monospace fonts for technical interfaces

**The Flexoki test:** Every visual element should either:
1. Communicate state (active, urgent, disabled)
2. Aid readability
3. Provide necessary affordance (clickable areas need size)

If it does none of these, remove it.

**Questions to ask:**
- Does this border/shadow/gradient help me think?
- Is this animation informing me or distracting me?
- Would I notice if this element disappeared?

---

### 3. Reducing Friction & Decision Fatigue

Tools should amplify the mind by removing small, repetitive choices.

**Applied to desktop/theming:**
- Establish a personal style guide and apply it everywhere:
  - One date format: `YYYY-MM-DD` (ISO 8601)
  - One time format: 24-hour
  - One font stack
  - One color palette
- Use keybinds over menus (faster, no visual hunting)
- Prefer search over hierarchical navigation
- Consistent spacing/padding values across all apps

**The style guide principle:** Collapse hundreds of future micro-decisions into one decision made today.

**Questions to ask:**
- Am I making this choice repeatedly?
- Can I encode this decision once and forget it?
- Does this require me to remember something?

---

### 4. Intentional Constraints

The creative power of limits. Less capability, more focus.

**Applied to desktop/theming:**
- Start vanilla, add only when friction is unbearable
- Fewer modules/widgets/plugins
- Fixed workspace count (constraint breeds organization)
- Limited color palette (Flexoki uses ~10 colors)
- One tool per job, not one tool for everything

**The vanilla test:** Before adding a plugin/module/feature:
1. Live without it for a week
2. Note actual friction points
3. Only add if the friction is genuinely unbearable

**Questions to ask:**
- What's the minimum I need to do this task?
- Am I adding this because I might need it, or because I do need it?
- Does this tool do one thing well, or everything poorly?

---

### 5. Bottom-Up Organization

Build systems that accommodate laziness and speed.

**Applied to desktop/theming:**
- Show only what exists (no phantom/placeholder elements)
- Let structure emerge from use, don't impose it upfront
- Per-monitor/per-context configs rather than global complexity
- Quick capture over careful filing

**Questions to ask:**
- Am I creating structure I'll actually use?
- Does this reflect reality or an ideal?
- Can I find things through search instead of hierarchy?

---

## Practical Checklist

When theming or configuring any tool, run through this:

```
[ ] Is the config self-contained and portable?
[ ] Are comments explaining "why" not "what"?
[ ] Have I removed all non-functional decorations?
[ ] Is there a consistent style guide applied?
[ ] Am I showing only real state, not placeholders?
[ ] Did I start minimal and add only what's needed?
[ ] Does every color/element serve a purpose?
[ ] Are animations disabled or minimal?
[ ] Can I accomplish tasks via keyboard?
[ ] Will this still make sense in 5 years?
```

---

## Color Philosophy (Flexoki)

Ango's Flexoki color scheme is designed for "prose and code" - extended reading/working sessions.

**Key characteristics:**
- Warm, not clinical (slightly yellow-shifted neutrals)
- "Inky" - like quality printing on good paper
- Limited palette (~10 colors) with clear semantic meaning
- High contrast for text, muted for UI elements
- No pure black (#000) or pure white (#fff)

**Flexoki Dark base colors:**
```
Background:  #100f0f (black, warm)
UI dim:      #6f6e69 (base-600)
UI normal:   #878580 (base-500)
Text:        #cecdc3 (base-200)
Text bright: #fffcf0 (paper)
```

**Semantic colors (use sparingly):**
```
Red:    #d14d41  (errors, urgent, destructive)
Orange: #da702c  (warnings)
Yellow: #d0a215  (caution, highlight)
Green:  #879a39  (success, positive)
Cyan:   #3aa99f  (info, links)
Blue:   #4385be  (accent, interactive)
Purple: #8b7ec8  (special)
Magenta:#ce5d97  (accent alt)
```

---

## Anti-Patterns to Avoid

1. **Feature creep**: Adding widgets "because I might want them"
2. **Decoration theater**: Rounded corners, shadows, gradients with no function
3. **Placeholder anxiety**: Showing empty slots for things that don't exist
4. **Animation fetish**: Transitions that slow you down
5. **Color overload**: Rainbow UIs where nothing stands out
6. **Config sprawl**: Dozens of files that include each other
7. **Tool maximalism**: One app that does 50 things vs. 5 apps that each do 1 thing well

---

## Sources

- Steph Ango's essays: https://stephango.com/
- Flexoki color scheme: https://stephango.com/flexoki
- "File over app": https://stephango.com/file-over-app
- Obsidian Minimal theme: https://github.com/kepano/obsidian-minimal
