---
name: dev-workflow
description: |
  Structured feature development workflow: stub endpoints, write failing tests,
  propose architecture, implement incrementally. Uses TDD, dependency injection,
  and repository pattern throughout.
  TRIGGERS:
  - "build a feature", "implement feature", "new feature", "add endpoint"
  - "dev workflow", "start feature", "scaffold feature"
argument-hint: <feature description>
---

# Dev Workflow

Structured, incremental feature development process. Every phase produces working
(but incomplete) code with tests, gets developer approval, and commits before
moving on.

## Core Principles

Apply these throughout every phase:

- **Dependency Injection**: Constructor injection everywhere. No hard-coded dependencies or service locators.
- **Repository Pattern**: All data access goes through repository interfaces. Services never touch the database directly.
- **Separation of Concerns**: Controllers handle HTTP. Services handle business logic. Repositories handle data access.
- **Swappable Dependencies**: Abstract third-party integrations (databases, payment providers, external APIs) behind interfaces so implementations can be swapped without changing business logic.
- **Testability**: Every piece is independently testable via mocked dependencies.

---

## Phase 1: Stub the Entry Point

**Goal**: Create the HTTP endpoint shell that proves the route exists.

1. **Identify or create** the controller for this feature.
2. **Add the endpoint** (route, method, decorator, params, return type) with a minimal handler that throws `NotImplementedException`.
3. **Wire it into the module** (controller registered, any new module created and imported).
4. **Write E2E/integration tests** that hit the endpoint:
   - Test that the route exists and returns the expected HTTP status (e.g., 501 or the shape of a not-implemented response).
   - Test auth/guard requirements if applicable.
   - These tests should **pass** against the stub (they validate the route exists, not that it works).
5. **Show the code to the developer.** Present:
   - The controller with the stubbed endpoint
   - The module wiring
   - The test file
6. **Ask for approval.** Wait for explicit confirmation before proceeding.
7. **On approval**: commit with a message like `feat(<scope>): stub <feature> endpoint`.

---

## Phase 2: Propose Architecture

**Goal**: Agree on the internal structure before writing it.

1. **Propose the architecture** to the developer. Include:
   - **Modules**: What NestJS modules are needed (new or modified).
   - **Services**: Business logic services with their responsibilities.
   - **Repositories**: Data access repositories with their interfaces.
   - **Entities/Models**: Database entities or domain models.
   - **DTOs**: Request/response shapes (Zod schemas or class-validator classes, match project convention).
   - **Interfaces**: Abstractions for any third-party dependencies (payment providers, external APIs, etc.).
   - **Function signatures**: For every service method and repository method, show the full signature (name, params with types, return type).
   - **Dependency graph**: Which service depends on which repositories/interfaces.

2. **Discuss with the developer.** This is iterative:
   - The developer may ask to rename things, restructure, add/remove pieces, change signatures.
   - Revise and re-present until there is explicit agreement.

3. **Do not write code until the developer approves the architecture.**

---

## Phase 3: Scaffold the Architecture

**Goal**: Create all the agreed-upon pieces as stubs with tests.

1. **Create every agreed piece** with `NotImplementedException` bodies:
   - Service classes with constructor-injected dependencies and stub methods.
   - Repository interfaces/classes with stub methods.
   - Entities/models with their column definitions.
   - DTOs with validation decorators.
   - Interfaces for third-party abstractions.
   - Database migrations if needed.

2. **Wire everything into modules**:
   - Register providers, repositories, imports, exports.
   - Use NestJS DI tokens/interfaces for injectable abstractions.

3. **Write unit tests for each service and repository**:
   - Mock all dependencies via constructor injection.
   - Test each method signature exists and can be called.
   - Write the actual test cases (expected behavior, edge cases, error cases) — they should **fail** because methods throw `NotImplementedException`.
   - Enumerate the test cases and present them to the developer for approval before writing them.

4. **Show all scaffolded code and tests to the developer.**
5. **Ask for approval.** Wait for explicit confirmation.
6. **On approval**: commit with a message like `feat(<scope>): scaffold <feature> services and repositories`.

---

## Phase 4: Implement

**Goal**: Fill in all the stubs and make every test pass.

1. **Implement bottom-up**: repositories first, then services, then update the controller.
2. **Run tests after each piece** to confirm progress.
3. **Handle edge cases** identified in the test cases.
4. **Run the full test suite** (unit + E2E) when implementation is complete.
5. **Show the implementation to the developer** with a summary of what was done.
6. **Ask for approval.**
7. **On approval**: commit with a message like `feat(<scope>): implement <feature>`.

---

## Rules

- **Never skip a phase.** Each phase must be approved and committed before moving to the next.
- **Never assume file locations or naming** — ask the developer if unsure.
- **Always present test cases** before writing them and get approval on the list.
- **Keep commits small and phase-aligned.** One commit per phase.
- **Use the project's existing patterns.** Match the style, conventions, and abstractions already in the codebase.
- **Ask before building.** When in doubt about any decision, pause and ask.
