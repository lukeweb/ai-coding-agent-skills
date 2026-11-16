---
name: unit-testing
description: >
  Guidelines for designing, writing, reviewing and improving
  language-agnostic unit tests: test cases, edge cases, test
  doubles (mocks, stubs, fakes), flaky or fragile tests, missing
  scenarios. Use whenever the user asks to add, fix, review or
  extend tests, cover a function with tests, or reports a flaky
  or failing test, even if they do not say "unit test". If a
  language-specific unit-testing skill is available, use it
  together with this one. Not for end-to-end, performance or
  infrastructure testing.
---

# Unit Testing

## Purpose

Ensure that unit tests are reliable, readable, maintainable
and verify observable behavior.

This is the baseline skill. A language-specific skill may add
framework, naming and tooling details but must not contradict
the Core Principles or Constraints below.

## Scope

In scope:

- Designing test cases.
- Writing new unit tests.
- Improving and reviewing existing unit tests.

Out of scope:

- End-to-end testing.
- Performance testing.
- Infrastructure testing.

A unit test verifies a focused unit of behavior in isolation
from uncontrolled external systems and side effects.

Unit tests should not depend on live network services,
shared databases, external infrastructure or uncontrolled
wall-clock time.

Controlled in-memory implementations, temporary resources
and deterministic local dependencies are acceptable when
they help verify the unit's behavior without compromising
isolation or reliability.

If the user asks for a test that requires live external
systems, state that it is outside this skill and suggest an
integration test instead.

Code that depends on global state or singletons without a seam
for tests is handled through Constraints: report it instead of
working around it (e.g. by patching globals).

## Precedence

When instructions conflict, apply this order:

1. Explicit user instructions.
2. Core Principles and Constraints of this skill.
3. Existing project conventions and utilities (framework,
   naming, structure, helpers).
4. Language-specific skill.
5. Test Design guidance in this skill.

A project convention never overrides Core Principles or
Constraints (e.g. a convention of verifying every mock call
does not justify testing implementation details).

## Core Principles

### Test behavior, not implementation

Verify the observable contract: return values, state changes
visible through the public API, errors, and side effects that
are part of the contract (e.g. an event published, a record
saved).

Tests must stay valid when the implementation is refactored
without changing behavior.

Do not test private members directly; verify their behavior
through the public API.

### Derive expectations from the contract, not from the code

The expected behavior must be derived primarily from
explicit requirements, acceptance criteria and authoritative
documentation.

Use the public API, method names, signatures and existing
tests as supporting evidence, not as definitive specifications.

Treat the current implementation as evidence of actual
behavior, not as the source of expected behavior.

If the implementation contradicts the established contract,
report the discrepancy instead of encoding the incorrect
behavior in a test.

If the expected behavior is unclear:

- If the ambiguity affects several tests or the outcome of an
  important scenario, and the user can be asked, ask before
  writing those tests.
- Otherwise choose the most conservative interpretation, mark
  the test with a short comment stating the assumption, and
  list the assumption in the report.

If no contract exists (legacy code) and the user explicitly
asks to pin current behavior before a refactor, write
characterization tests: name or mark them as such, and state
in the report that they record actual, not verified, behavior.

### Keep tests isolated

Each test must be independent of execution order and shared
mutable state.

Each test should establish and clean up its own required state
and resources.

Tests must not depend on side effects from other tests.

### Keep tests deterministic

Tests must produce predictable and reproducible results
regardless of execution order, machine or environment.

Control sources of non-determinism:

- Current time and date.
- Random number generators.
- UUID and ID generation.
- External services.
- Environment-dependent configuration.
- Iteration order of maps and sets.
- Time zone and locale.
- Floating-point comparisons.
- Thread or task scheduling.

Prefer dependency injection to make non-deterministic
dependencies controllable.

A fixed seed is acceptable only when the generator is injected
into the unit and the test asserts behavior that does not
depend on the specific generated values.

Prefer real implementations for deterministic, fast,
in-process collaborators when they do not compromise
test isolation or reliability.

Use appropriate test doubles when dependencies introduce
uncontrolled side effects, external state, non-determinism
or unnecessary complexity.

## Workflow

When writing or improving unit tests:

1. If a language-specific unit-testing skill is available,
   read it before starting.
2. Read the unit under test, its public API and documentation
   to identify the expected contract.
3. Review existing tests: framework, naming, structure,
   conventions and available helpers.
4. Run the existing relevant tests to establish a baseline.
   Note any pre-existing failures; do not attribute them to
   your changes and do not fix them unless asked.
5. Identify the responsibilities and dependencies of the unit.
6. Decide which dependencies should remain real and which
   require test doubles.
7. Identify relevant scenarios and prioritize those that
   could realistically break.
8. Implement the tests following project conventions.
9. Run the verification steps below.
10. Report the results, assumptions and unresolved issues.

When asked to review existing tests instead, follow
"Reviewing Existing Tests".

## Test Design

### Scenario checklist

Consider the following scenarios when relevant:

- Normal execution paths.
- Boundary conditions (empty, zero, one, maximum values,
  off-by-one cases).
- Invalid inputs.
- Error handling and failure paths.
- Important state transitions.
- Meaningful combinations of conditions.
- Important invariants that must always hold. Property-based
  tests are a good fit for invariants when the project's
  tooling supports them.

Do not add tests solely to increase code coverage numbers.

For a bug fix, first write a test that reproduces the bug and
confirm it fails for the right reason. If the fix is in scope,
confirm the test passes afterwards. If production changes are
not authorized, report the reproducer instead of leaving a
failing test unannounced, and ask whether to keep it.

### Test doubles

Use test doubles deliberately and choose the appropriate
type for the scenario:

- Stubs provide controlled responses to dependency calls.
- Fakes provide simplified working implementations.
- Mocks verify expected interactions with dependencies.
- Spies record interactions for later verification.

Prefer fakes (simple in-memory implementations) over mocks
when the dependency has meaningful behavior that can be
represented by a lightweight implementation.

Assert interactions only when the interaction itself is
part of the expected contract, e.g. a notification must be
sent or a call must NOT happen.

Do not assert call counts or call order unless they are
explicitly part of the expected behavior.

Do not mock types you do not own when an existing wrapper or
a fake at the boundary is available. Creating a new wrapper in
production code requires user approval (see Constraints).

Never mock the unit under test.

### Assertions

Assert specific outcomes, not just that execution completed
without errors or that a result is not null.

Assertions should verify observable behavior and distinguish
between correct and incorrect outcomes.

For errors, assert the relevant error contract:
type, category, code or other stable error properties.

Assert message content only when it is part of the expected
behavior or provides a stable, meaningful guarantee.

Avoid assertions that would still pass if the behavior were
wrong (e.g. checking only the length of a result).

Do not assert on log output unless logging is part of
the expected contract.

### Structure and naming

Each test should focus on one logical scenario or behavior.

Multiple assertions are acceptable when they verify
different aspects of the same behavior.

Name tests by scenario and expected result, e.g.
`rejects_expired_token`, not `test1` or `testValidate`.
The naming style is illustrative; follow project conventions.

Use Arrange / Act / Assert when it improves readability.

Keep expected values literal and explicit. Never compute
expected values in the test, especially by reusing the
implementation's logic.

Loops are acceptable only to iterate over an explicit table
of cases or inside the framework's parametrization or
property-based mechanism. If a test body branches on case
fields (e.g. error vs success) and the branches grow, split
into separate tests or tables.

Make test data self-explanatory. Name or comment values
whose meaning is not obvious.

Use synthetic test data. Never use real credentials, personal
data or production dumps.

Use the project's parametrization mechanism when several
cases share the same structure; otherwise keep cases separate.

Prefer a little duplication in tests over an abstraction
that hides what a test does.

Reuse existing project helpers when they improve clarity
and consistency.

Add comments only for non-obvious behavior or testing
decisions.

### Anti-patterns not covered above

- Testing third-party or framework code instead of the
  unit's own behavior.
- Testing trivial getters or setters without logic.
- Sleeping to synchronize concurrent code instead of
  controlling time or using explicit synchronization.

## Reviewing Existing Tests

When asked to review tests rather than write them:

1. Establish the contract of the unit (see Core Principles).
2. Check each test against Core Principles and Test Design.
   Confirm suspected problems by running the tests where
   possible (e.g. repeated runs for suspected flakiness)
   instead of guessing.
3. Report findings first, ordered by priority:
   - High: passes when behavior is broken, encodes a bug,
     is flaky or order-dependent.
   - Medium: coupled to implementation, missing important
     scenarios.
   - Low: naming, readability, duplication.
4. List missing scenarios separately.
5. Change the tests only after reporting findings, unless
   the user asked for fixes directly.

## Constraints

- Do not modify production code just to make tests pass.
  If the unit is hard to test (e.g. no seam for time,
  randomness or a dependency), report the problem and propose
  the smallest necessary change. Apply it only with explicit
  user approval.

- Existing tests may be refactored or improved but must never
  end up verifying less than before. Do not delete, disable
  or weaken them to get a passing suite.

- Do not change the expected values of existing assertions
  unless requirements have legitimately changed; explain such
  changes in the report. Making an assertion stricter or more
  precise is allowed.

- Do not introduce new test frameworks or dependencies when
  existing project tools are sufficient.

## Verification

1. Run the new or modified tests using the project's own
   test commands.

2. Run the surrounding package or module tests, then the
   full test suite unless it is too slow. If the full suite
   is skipped, say so in the report.

3. Check test sensitivity.

   Important tests are those covering conditional logic, error
   paths and boundary values; trivial mapping or pass-through
   tests are excluded.

   For each important test, identify at least one realistic
   change in production behavior that would make it fail
   (flipped condition, shifted boundary, removed error
   handling). If you cannot, strengthen the assertion.

   If a mutation testing tool is already configured in the
   project, run it on the changed code.

   Manual mutation of production code is allowed only when
   the touched file has no uncommitted changes (or the work
   is done in a disposable copy or worktree) and the original
   is restored exactly afterwards. Otherwise skip it and say
   so in the report. Never overwrite or revert unrelated
   user changes.

4. Check reliability.

   Verify that tests pass on repeated runs and in random
   or reversed order when the tooling supports it.

   Check for leftover state, resources or side effects.

5. Investigate failures.

   Identify the root cause and classify each failure as
   a test defect or a production defect.

   Never modify assertions solely to make tests pass.

   Report unresolved failures and their likely causes.

## Report

Provide a concise summary containing:

- Tests created or modified.
- Commands executed and their results.
- Pre-existing failures observed (not caused by your changes).
- Suspected production defects found.
- Assumptions made about expected behavior.
- Verification steps skipped or impossible, with the reason.
  Never report tests as passing unless they were executed.
- Unresolved failures or limitations.
