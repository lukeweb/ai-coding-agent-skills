---
name: unit-testing
description: >
  Guidelines for designing, writing, reviewing and improving
  language-agnostic unit tests: scenarios, edge cases, test doubles
  (mocks, stubs, fakes), assertions, isolation, determinism and
  flaky or fragile tests. Use whenever the user asks to add, fix,
  review or extend tests, cover a function with tests, find missing
  scenarios, or reports flaky or failing tests, even if they do not
  say "unit test". If a language-specific unit-testing skill is
  available, use it together with this one. Not for end-to-end,
  performance or infrastructure testing.
---

# Unit Testing

## Purpose and scope

Ensure unit tests are reliable, readable, maintainable and verify observable behavior. This is the baseline skill; a language-specific skill may add framework, naming and tooling details.

In scope: test design, writing, improving and reviewing unit tests.

Out of scope: end-to-end, performance and infrastructure testing. A unit test verifies focused behavior in isolation from uncontrolled external systems and side effects. Do not depend on live network services, shared databases, external infrastructure or uncontrolled wall-clock time. Controlled in-memory implementations, temporary resources and deterministic local dependencies are acceptable when they help verify the unit's behavior without compromising isolation or reliability.

If a requested test requires live external systems, explain that it belongs in integration testing. If code depends on global state or singletons without a test seam, report the limitation instead of working around it by patching globals.

## Precedence

Resolve conflicts in this order:

1. Explicit user instructions.
2. This skill's Core Principles and Constraints.
3. Existing project conventions, frameworks and helpers.
4. Language-specific skill.
5. Test design guidance in this skill.

Project conventions and language-specific guidance must not override Core Principles or Constraints. Workflow, Verification, Reporting and Reviewing Existing Tests always apply unless the user explicitly instructs otherwise.

## Core principles

### 1. Test the contract, not the implementation

- Verify observable behavior: return values, public state changes, errors and contractually required side effects.
- Do not test private members or implementation details; verify their behavior through the public API. Tests should survive refactoring that preserves behavior.
- Derive expectations primarily from requirements, acceptance criteria and authoritative documentation. Public APIs, signatures and existing tests are supporting evidence; the current implementation is evidence of actual behavior, not the specification.
- If implementation contradicts the established contract, report the discrepancy instead of encoding the defect in a test.
- If expected behavior is unclear:
  - Ask when ambiguity affects important scenarios or multiple tests and the user can clarify.
  - Otherwise use the most conservative interpretation, document the assumption in the test and report it.
- If no contract exists for legacy code and the user explicitly asks to pin current behavior before refactoring, write clearly identified characterization tests and state in the report that they record actual, not verified, behavior.

### 2. Isolation and determinism

- Tests must be independent of execution order and shared mutable state. Each test establishes and cleans up its own state and resources.
- Results must be reproducible across runs, machines and environments.
- Control sources of non-determinism: time/date, randomness, UUIDs and IDs, external services, environment configuration, collection iteration order, locale/time zone, floating-point comparisons and concurrent scheduling.
- Prefer dependency injection to control such dependencies.
- A fixed random seed is acceptable only when the generator is injected and assertions do not depend on specific generated values.
- Prefer real, deterministic, fast in-process collaborators when they do not compromise isolation or reliability. Use stubs, fakes, mocks or spies when dependencies introduce uncontrolled side effects, external state, non-determinism or unnecessary complexity.

## Workflow

When writing or improving tests:

1. Read an available language-specific testing skill.
2. Inspect the unit, public API and documentation to establish its contract.
3. Review existing tests, framework, conventions and helpers.
4. Run relevant existing tests to establish a baseline. Record pre-existing failures; do not attribute them to your changes and do not fix them unless asked.
5. Identify the unit's responsibilities, dependencies and relevant failure scenarios.
6. Decide which dependencies remain real and which need test doubles.
7. Identify relevant scenarios and prioritize those that could realistically break.
8. Implement tests using project conventions.
9. Perform the verification below and report results, assumptions and limitations.

When reviewing existing tests, follow **Reviewing Existing Tests** instead.

## Test design

### Scenarios

Consider relevant cases, not every theoretical combination:

- Normal execution.
- Boundaries: empty, zero, one, maximum and off-by-one values.
- Invalid input and error/failure paths.
- Important state transitions and meaningful condition combinations.
- Invariants that must always hold; consider property-based tests when supported.

Do not add tests just to increase coverage numbers.

For bug fixes, first write a reproducer and confirm it fails for the correct reason. If the fix is in scope, verify that it passes afterwards. If production changes are not authorized, report the reproducer and ask whether to keep an intentionally failing test.

### Test doubles

- **Stub:** supplies controlled responses.
- **Fake:** provides a simplified working implementation.
- **Mock:** verifies expected interactions.
- **Spy:** records interactions for later verification.

Prefer simple in-memory fakes over mocks when they represent meaningful dependency behavior. Assert interactions only when they are part of the contract (for example, a notification must be sent or a call must not happen). Do not assert call counts or order unless explicitly required by the contract.

Never mock the unit under test. Do not mock types you do not own when an existing wrapper or a boundary fake is available. Creating a production wrapper requires user approval.

### Assertions

- Assert specific, observable outcomes, not merely successful execution or non-null results.
- Assertions must distinguish correct from incorrect behavior; checking only a result's length is insufficient when its contents matter.
- For errors, verify stable contract properties such as type, category or code. Assert message text only when it is contractual or a meaningful stable guarantee.
- Do not assert log output unless logging is part of the contract.

### Structure, naming and data

- Each test focuses on one logical scenario. Multiple assertions are fine when they verify aspects of that same behavior.
- Name tests by scenario and expected result; follow project naming conventions.
- Use Arrange / Act / Assert when it improves clarity.
- Keep expected values literal and explicit. Never calculate them using the implementation's logic.
- Use loops only for explicit case tables or framework parametrization/property-based testing. Split tests when branching on case fields becomes complex.
- Use self-explanatory synthetic data. Never use real credentials, personal data or production dumps.
- Prefer project parametrization for structurally similar cases; otherwise keep cases separate.
- Prefer small, clear duplication over abstractions that hide test intent. Reuse helpers when they improve clarity. Comment only on non-obvious behavior or decisions.

Avoid testing third-party/framework code, trivial getters/setters without logic, and sleeping to synchronize concurrent code. Control time or use explicit synchronization instead.

## Reviewing Existing Tests

1. Establish the unit's contract using **Core principles**.
2. Evaluate each test against this skill. Verify suspected problems by running tests where possible; repeat runs when investigating flakiness.
3. Report findings first, ordered by priority:
   - **High:** passes despite broken behavior, encodes a defect, is flaky or order-dependent.
   - **Medium:** coupled to implementation or missing important scenarios.
   - **Low:** naming, readability or duplication.
4. List missing scenarios separately.
5. Modify tests only after reporting findings, unless the user explicitly requested fixes.

## Constraints

- Do not modify production code just to make tests pass. If a unit lacks a test seam (for time, randomness or dependencies), report the problem and propose the smallest required change. Apply it only with explicit user approval.
- Existing tests may be refactored or improved, but must never verify less than before. Do not delete, disable or weaken tests to obtain a passing suite.
- Do not change existing expected values unless requirements legitimately changed; explain such changes in the report. Making an assertion stricter or more precise is allowed.
- Do not introduce test frameworks or dependencies when existing project tools are sufficient.

## Verification

1. Run new or modified tests with the project's own commands, then relevant package/module tests and the full suite unless it is too slow. Report skipped checks and why.
2. Check test sensitivity for important tests covering conditions, boundaries and error paths. Identify at least one realistic production behavior change that should make each test fail (for example, a flipped condition, shifted boundary or removed error handling). Strengthen assertions if they would not detect it. Exclude trivial mapping/pass-through tests.
3. Run configured mutation testing on changed code, if available.
4. Manual production-code mutation is allowed only if the touched file has no uncommitted changes or work is done in a disposable copy/worktree, and the original is restored exactly. Otherwise skip it and report why. Never overwrite or revert unrelated user changes.
5. Check reliability: repeat tests and vary/randomize execution order when supported. Check for leftover state, resources and side effects.
6. Investigate failures, classify each as a test defect or production defect, and identify its likely root cause. Never change assertions solely to make tests pass.

## Report

Provide a concise summary of:

- Tests created or modified.
- Commands executed and actual results.
- Pre-existing failures (not caused by your changes).
- Suspected production defects.
- Assumptions about expected behavior.
- Verification steps skipped or impossible, with reasons.
- Unresolved failures with their likely causes, and limitations.

Never claim a test passed unless it was actually executed.
