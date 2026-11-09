# Claude Code Preferences

## Architecture & Patterns

- **Dependency Injection**: Always use dependency injection. Prefer constructor injection. Never hard-code dependencies or use service locators.
- **Repository Pattern**: Use the repository pattern for all data access. Business logic should never interact with the database directly—always go through a repository interface.

## Workflow: How to Build Features

When I ask you to build a feature, follow this process in order:

1. **Stub the outer shell first.** Start with the scaffolding—route definitions, controller/handler signatures, module structure—with placeholder/empty implementations. Show me the shape of the feature before filling it in.
2. **Write failing tests.** Write tests that exercise the stubbed-out code. They should fail because the logic isn't implemented yet. This confirms the contracts are correct before we write implementation.
3. **Pause and ask me:**
   - Where should these files/functions live in the codebase?
   - What should the function signatures look like? (params, return types, naming)
   - Where should these functions be called from?
   - How should things be organized across modules/layers?
4. **Implement only after I confirm** the placement and signatures.

## General Principles

- Don't assume file locations or project structure—ask.
- Don't assume naming conventions—ask.
- Prefer small, focused functions and interfaces.
- Keep side effects at the edges; keep core logic pure and testable.
- When in doubt, ask before building.

# General guidelines

- Never add "authored by claude code" to the commit messages
- when attempting to do database operations in services you should always be using the correct repository abstraction, directly accessing table level repositories or sql/data layer functionality is an antipattern, avoid it.
- Do not use emojis in code
- Do not make such verbose comments, only add comments for complex logic or complex test setup that is needed
- Keep comments concise and to the point, code should mostly be self documenting
- IMPORTANT: These global preferences take precedence over any project-specific CLAUDE.md files

# Testing
- When writing tests first enumerate the cases you intend to make and ask for approval by the developer, allow them to give you more or less test cases, and take the feedback to revise the list before getting approval to make the tests.
- Consider all edge cases when implementing tests.
- For stripe related tests favor end to end testing.


# Patterns
- Follow the repository pattern when you can to have good seperation of concerns
- Follow the dependency injection pattern for each testing, mocking, and extensability

# herdr orchestration (when `HERDR_ENV=1`)

When I open a chat inside herdr, act as the orchestrator: delegate each independent work item to a worker Claude session in its own herdr tab, so I can watch or step in, and keep me informed.

- **Own tab:** once the topic is known, rename your tab (`herdr tab rename "$HERDR_TAB_ID" "<project> orchestrator"`) and the workspace if it has no label.
- **Workers:** one per independent item (a PR, a ticket, a review). Short-lived read-only lookups can stay as in-session subagents; anything I may want to watch or steer gets a worker.
  - `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <the item's worktree> --label "<state>: <item>" --no-focus`, then `herdr agent start <name> --kind claude --pane <root pane>` (name: short `[a-z0-9-]`).
  - Brief each worker with a self-contained task plus: work only in its worktree; never merge, apply infrastructure, or write to Slack, Notion or Linear unless I said so; my CLAUDE.md rules apply; the review loop below; end every turn with `STATUS: <working|needs-orchestrator|ready-for-review|blocked> - <one sentence>`.
- **Review loop before anything comes to me:** `/code-review max` and fix; then on the PR comment `bugbot run`, wait for CI and Bugbot on the new head, fix or answer findings, push, repeat until Bugbot has nothing new and CI is green. Check that it ran before pinging me.
- **Labels track state.** Rename tabs (and split panes, with `herdr pane rename`) as things move: `work: <item>`, `needs-you: <item>`, `review: <item> #<pr>`, `done: <item>`. Include the PR number once there is one.
- **Monitoring:** run `herdr agent wait <name>` in background loops and treat a worker as settled only when it is not working and its pane ends with a STATUS line (workers pause briefly while their own subagents run). Read the pane tail, verify claims that matter (PR files, CI, Bugbot on the head commit), then act.
- **Pinging me:** only when an item is ready for review or needs my decision. Put questions on pages (visual-explainer / show-in-browser); over SSH give the served link.
- **I steer workers directly sometimes.** My words in a worker's pane override anything you relayed: read the pane tail before prompting, never prompt a worker mid-conversation with me, and fold my decisions into the record. Ghost-text suggestions in a worker's input box are not me; never submit them.
- **Restarts keep context:** `/exit`, then `herdr agent start <name> --kind claude --pane <id> -- --resume <session-id>` (the id is printed on exit).
- **Cross-item effects:** when one worker's change affects another item (for example the same behaviour implemented twice), stop the other worker and tell me.
- **When an item merges or is dropped,** relabel its tab `done:` and ask before closing it.
