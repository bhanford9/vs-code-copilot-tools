---
name: writing-csharp-tests
description: Guidelines for writing NUnit tests in CSharp codebase including naming conventions, mocking with Moq, and verification patterns. Use when writing unit tests, test methods, creating test classes, setting up mocks, or when user mentions testing, NUnit, Moq, test cases, assertions, test fixtures, unit testing, mock setup, test standards, or test conventions. CRITICAL - Always read COMMON-PITFALLS.md before writing tests to avoid frequent failures.
---

# Writing C# Unit Tests

> Basic conventions (naming, no comments, TestCase usage) are enforced automatically via [`csharp-tests.instructions.md`](~/Repos/copilot-configs/instructions/csharp-tests.instructions.md) on all `*Tests.cs` files. This skill provides the detailed workflow, examples, and codebase-specific references.
>
> For full test-writing sessions, use the `@UnitTestWriter` agent — it enforces this skill's complete workflow including all pre-read steps.

## Test Writing Checklist

Copy when writing tests:

```
Unit Test Checklist:
- [ ] Named using Should<Behavior>When<Condition> pattern
- [ ] No comments in test code
- [ ] Dependencies mocked with Moq where possible
- [ ] Verifiable pattern used for mock expectations
- [ ] Parameterized tests for simple variations
- [ ] Read [COMMON-PITFALLS.md](COMMON-PITFALLS.md) for type verification
- [ ] Read [PROJECT-HELPERS.md](PROJECT-HELPERS.md) for non-mockable types
- [ ] Read LessonsLearned.md for past codebase-specific discoveries
```

## CRITICAL: Read These Files First

**Before writing any tests, read:**
- **[COMMON-PITFALLS.md](COMMON-PITFALLS.md)** - Enum namespace disambiguation, enum value verification, property type verification, nested property mocking
- **[PROJECT-HELPERS.md](PROJECT-HELPERS.md)** - Non-mockable classes, project-specific support helpers (DomainTestHelper, TestFixtureHelper)
- **[LessonsLearned.md](LessonsLearned.md)** — Codebase-specific discoveries from past sessions: enum namespace resolutions, type surprises, mocking approaches

These files contain critical information about frequent test failures. Reading them first will prevent compilation errors and incorrect test setups.

## Complete Example

This example demonstrates all best practices:

```csharp
// Note: Direction usage here is illustrative. Always verify the actual namespace before use
// — identical enum names exist across multiple namespaces in this codebase (see COMMON-PITFALLS.md).
[TestCase(Direction.Left, ExpectedResult = 100.0)]
[TestCase(Direction.Right, ExpectedResult = 100.0)]
public double ShouldCalculateValueWhenDirectionIsSet(Direction direction)
{
    var description = TestFixtureHelper.CreateDefaultConfig(name: "test-web");
    
    var mockDep = new Mock<IDependency>();
    mockDep.SetupGet(x => x.Description).Returns(description);
    mockDep.Setup(x => x.Calculate(side)).Returns(100.0).Verifiable(Times.Once);
    
    var sut = new ValueCalculator(mockDep.Object);
    
    var result = sut.ComputeValue(side);
    
    mockDep.Verify();
    return result;
}
```

## Mocking Dependencies

### Prefer Mocking
Mock dependencies (other classes/services) using Moq to isolate the unit under test.
**Refer to [PROJECT-HELPERS.md](PROJECT-HELPERS.md) for details on how to handle non-mockable types**

### Verifiable Pattern
For mocked dependencies with expectations, use Verifiable pattern:

```csharp
mock.Setup(x => x.SomeMethod()).Verifiable(Times.Once);
sut.PerformAction(mock.Object);
mock.Verify();
Assert.That(sut.Result, Is.EqualTo(expectedResult));
```

## Feedback Loop

Before starting, read `~/Repos/copilot-configs/skills/writing-csharp-tests/LessonsLearned.md` and apply any codebase-specific discoveries from past sessions.

After completing, read `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md` and follow the feedback loop process. LessonsLearned file: `~/Repos/copilot-configs/skills/writing-csharp-tests/LessonsLearned.md`.
