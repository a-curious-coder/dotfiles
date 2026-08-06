# Claude Code skills

Personal skill inventory (name — description). Generated from `~/.claude/skills/*/SKILL.md`.
Most are symlinked from `~/.agents/skills` (managed by a separate skill package manager,
tracked in `~/.agents/.skill-lock.json` — not stowed here, this file is documentation only).

| Skill | Description |
|---|---|
| access-obsidian-vault | Navigate to the user's Obsidian vault ('the-vault') using zoxide, falling back to asking the user for the path if zoxide fails. |
| ask-matt | Ask which skill or flow fits your situation. A router over the skills in this repo. |
| caveman | Ultra-compressed communication mode. Cuts token usage ~75% by dropping filler, articles, and pleasantries while keeping full technical accuracy. |
| claude-handoff | Hand the current conversation off to a fresh background agent that picks up the work immediately. |
| code-review | Review changes since a fixed point along two axes — Standards and Spec — via parallel sub-agents. |
| codebase-design | Shared vocabulary for designing deep modules: interfaces, deepening opportunities, seams, testability. |
| decision-mapping | Turn a loose idea into a sequenced map of investigation tickets, then drive them to resolution one at a time. |
| design-an-interface | Generate multiple radically different interface designs for a module using parallel sub-agents. |
| diagnose | Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test. |
| diagnosing-bugs | Diagnosis loop for hard bugs and performance regressions (shorter variant of `diagnose`). |
| domain-modeling | Build and sharpen a project's domain model / ubiquitous language / architectural decisions. |
| edit-article | Edit and improve articles by restructuring sections, improving clarity, and tightening prose. |
| find-skills | Helps discover and install agent skills when asked "is there a skill for X". |
| generate-diagram | Generate an Excalidraw diagram from a natural-language description, saved into the Obsidian vault. |
| git-guardrails-claude-code | Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc). |
| grill-me | A relentless interview to sharpen a plan or design. |
| grill-with-docs | Same as grill-me, but also creates docs (ADRs, glossary) as it goes. |
| grilling | Grill the user relentlessly about a plan or design to stress-test it before building. |
| handoff | Compact the current conversation into a handoff document for another agent to pick up. |
| implement | Implement a piece of work based on a spec or set of tickets. |
| improve-codebase-architecture | Scan a codebase for deepening opportunities, present as an HTML report, then grill through the chosen one. |
| knowledge-check | Evaluates understanding of the last exchange, tests it, logs confirmed gaps to Knowledge Gaps.md in the vault. |
| log-card | Generate an Obsidian note for a Jira card by key (summary, status, points, linked/merged PRs). |
| log-dev-request | Prepare a resolution doc for a Dev Request card (support-to-dev triage board), matched to a playbook recipe. |
| loop-me | Grill me about specs for workflows I want to build, within this workspace. |
| migrate-to-shoehorn | Migrate test files from `as` type assertions to @total-typescript/shoehorn. |
| next-card | Recommend which Jira card to take next from the open sprint, ranked by points and blocker risk. |
| obsidian-vault | Search, create, and manage notes in the Obsidian vault with wikilinks and index notes. |
| ponytail-review | Over-engineering review — finds what to delete (reinvented stdlib, speculative abstractions, dead flexibility). |
| prototype | Build a throwaway prototype to answer a design question (state model, UI shape). |
| qa | Interactive QA session — user reports bugs conversationally, agent files GitHub issues. |
| request-refactor-plan | Create a detailed refactor plan with tiny commits via interview, filed as a GitHub issue. |
| research | Investigate a question against high-trust primary sources, capture findings as a Markdown file. |
| resolving-merge-conflicts | Resolve an in-progress git merge/rebase conflict. |
| review | Same as code-review — Standards + Spec review via parallel sub-agents. |
| scaffold-exercises | Create exercise directory structures (sections, problems, solutions, explainers) that pass linting. |
| setup-matt-pocock-skills | One-time repo setup (issue tracker, triage labels, domain doc layout) for the other engineering skills. |
| setup-pre-commit | Set up Husky pre-commit hooks with lint-staged, type checking, and tests. |
| shieldcn-badges | Create shadcn-styled README badges, badge groups, charts, headers, sponsor/contributor grids. |
| tdd | Test-driven development — red-green-refactor, integration tests. |
| teach | Teach the user a new skill or concept, within this workspace. |
| to-issues | Break a plan/spec/PRD into independently-grabbable issues using tracer-bullet vertical slices. |
| to-prd | Turn the current conversation into a PRD, published to the project issue tracker. |
| to-spec | Turn the current conversation into a spec, published to the project issue tracker. |
| to-tickets | Break a plan/conversation into tracer-bullet tickets with declared blocking edges, published to the tracker. |
| triage | Move issues/external PRs through a triage state machine: categorise, verify, grill, write agent-ready briefs. |
| ubiquitous-language | Extract a DDD-style glossary from the conversation, flag ambiguities, save to UBIQUITOUS_LANGUAGE.md. |
| wayfinder | Plan work larger than one agent session as a shared map of investigation tickets, resolved one at a time. |
| wizard | Generate an interactive bash wizard for a manual procedure (setup, migration, A→B transition). |
| write-a-skill | Create new agent skills with proper structure, progressive disclosure, and bundled resources. |
| writing-beats | Writing (exploit) — assemble raw material into a journey of beats. |
| writing-fragments | Writing (explore) — mine raw fragments, no structure yet. |
| writing-great-skills | Reference for writing and editing skills well — vocabulary and principles for predictable skills. |
| writing-shape | Writing (exploit) — shape raw material into an article, paragraph by paragraph. |
| zoom-out | Give broader context or a higher-level perspective on unfamiliar code. |

## Not included

Work-only skills from the `nourish-product-brain` plugin (assumption-mapper, brief generators,
Jira/PRD/quarterly-planning skills, etc.) are scoped to that project's `.claude` and are not
personal/portable, so they're left out of this list.
