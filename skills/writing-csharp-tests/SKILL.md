---
name: writing-csharp-tests
description: Guidelines for writing NUnit tests in CSharp codebase including naming conventions, mocking with Moq, and verification patterns. Use when writing unit tests, test methods, creating test classes, setting up mocks, or when user mentions testing, NUnit, Moq, test cases, assertions, test fixtures, unit testing, mock setup, test standards, or test conventions.
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
- [ ] Read LessonsLearned.GLOBAL.md for process notes
- [ ] Read LessonsLearned.md for codebase-specific type/mock discoveries (if it exists)
```

## Before Writing Tests: Read Both LessonsLearned Files

**Before writing any tests, read:**
- **[LessonsLearned.GLOBAL.md](LessonsLearned.GLOBAL.md)** — Process notes, workflow guidance, and patterns that apply across any C# codebase
- **[LessonsLearned.md](LessonsLearned.md)** — Your codebase-specific discoveries: enum namespaces, non-mockable types, support helper locations, property type surprises (exists on disk but not tracked in git; may not exist in a fresh clone)

These files accumulate codebase-specific knowledge over time. Reading them first prevents compilation errors and avoids repeating past mistakes.

## Complete Example

This example demonstrates all best practices:

```csharp
// Note: Always verify the actual namespace before using enum types.
// — identical enum names can exist across multiple namespaces in a codebase.
[TestCase(Direction.Left, ExpectedResult = 100.0)]
[TestCase(Direction.Right, ExpectedResult = 100.0)]
public double ShouldCalculateValueWhenDirectionIsSet(Direction direction)
{
    var config = TestFixtureHelper.CreateDefaultConfig(name: "test-config");
    
    var mockDep = new Mock<IDependency>();
    mockDep.SetupGet(x => x.Config).Returns(config);
    mockDep.Setup(x => x.Process(direction)).Returns(100.0).Verifiable(Times.Once);
    
    var sut = new ValueCalculator(mockDep.Object);
    
    var result = sut.ComputeValue(direction);
    
    mockDep.Verify();
    return result;
}
```

## Mocking Dependencies

### Prefer Mocking
Mock dependencies (other classes/services) using Moq to isolate the unit under test.
For non-mockable types (records, structs, concrete classes), check `LessonsLearned.md` for project-specific support helpers.

### Verifiable Pattern
For mocked dependencies with expectations, use Verifiable pattern:

```csharp
mock.Setup(x => x.SomeMethod()).Verifiable(Times.Once);
sut.PerformAction(mock.Object);
mock.Verify();
Assert.That(sut.Result, Is.EqualTo(expectedResult));
```

## Feedback Loop

Before starting, read `~/Repos/copilot-configs/skills/writing-csharp-tests/LessonsLearned.GLOBAL.md` and, if it exists on disk, `~/Repos/copilot-configs/skills/writing-csharp-tests/LessonsLearned.md`. Apply any recorded patterns to this session.

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, follow the two-tier feedback loop from `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md`:
- **Codebase findings** (type locations, enum namespaces, non-mockable types, support helpers) → write to `LessonsLearned.md`
- **Process/Model findings** (agent behavior, workflow gaps) → write to `LessonsLearned.GLOBAL.md`
