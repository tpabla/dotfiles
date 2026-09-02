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
