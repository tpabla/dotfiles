# Worker brief

Write each brief to a file and pass it to `orch spawn --brief-file`. The worker reads it as its first prompt, so it must stand on its own: the worker has none of your context. Fill in the angle brackets, cut lines that don't apply, and keep the Rules section as it is.

```
Orchestrator (<project>, terminal <your address or tab>) here. You own <item>: <one-line goal>.

Context:
- <what you know: the ticket and how to read it, related PRs, decisions the user already made>
- <links the worker needs; say which tools to use read-only>

Worktree: <path>, branch <branch> (from origin/<default branch>). Work only there.
Read the repo's CLAUDE.md, AGENTS.md or README for its build and test commands, and follow the repo's conventions where they differ from mine.

Process:
1. <steps specific to this item>
2. If the user's CLAUDE.md asks for approval before a step (test cases, placement, signatures),
   put the questions on a page, end the turn with STATUS: needs-orchestrator, and wait.
3. Run the tests, with counts against a baseline taken before your change.
4. Review loop: run /code-review max and fix what it finds. Commit and push, and open a PR
   (draft unless told otherwise) whose title names <item>. Comment `bugbot run` on the PR,
   wait for CI and Bugbot on the head commit, fix or answer every finding, push, and repeat
   until Bugbot has nothing new and CI is green.

Rules:
- Never merge, apply infrastructure, or write to Slack, Notion or Linear unless the orchestrator
  says the user approved it.
- Never print secrets. Never force-push.
- If the user types in your tab, their words override this brief.
- If a permission check blocks an action, stop and say so in your STATUS line. Don't work around it.
- End every turn with exactly one line:
  STATUS: <working|needs-orchestrator|ready-for-review|blocked> - <one sentence>
- herdr-app only: also run
  hc label "$HC_TERMINAL_ID" "orch.status=<state> - <one sentence>"
```

## STATUS states

| State | Meaning | What the orchestrator does |
|---|---|---|
| `working` | the turn ended, but work continues in the background (CI, a long build) | wait again |
| `needs-orchestrator` | a question or a page for the user | answer it, or relabel the tab `needs-you:` and ping the user |
| `ready-for-review` | review loop clean, CI green | verify, relabel `review: <item> #<pr>`, ping the user |
| `blocked` | can't continue (auth, permissions, missing access) | fix it, or ask the user |
