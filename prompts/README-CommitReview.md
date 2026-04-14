# Commit List Review Workflow

This guide explains how to review a specific set of commits as a combined changeset, useful when you want to review non-contiguous commits or commits from different branches.

## Quick Start

### 1. Prepare Commits for Review

Invoke the agent with the prepare prompt:

```
@PrepareCommitReview.prompt.md
```

You'll be asked to provide:
- **Commit SHAs**: List of commits to review (e.g., `abc123 def456 ghi789`)
- **Conflict strategy**: How to handle conflicts
  - `abort`: Stop immediately if any conflict occurs (safest)
  - `skip`: Skip conflicting commits and continue with others
  - `theirs`: Auto-resolve using the commit's version
  - `ours`: Auto-resolve using the baseline's version

The agent will:
- Sort commits chronologically (earliest to latest)
- Use the **parent of the earliest commit** as the baseline automatically
- Cherry-pick all commits (including the earliest) in chronological order
  - `abort` - Stop if any conflict (safest, recommended)
  - `skip` - Skip conflicting commits and continue
  - `theirs` - Use commit version for conflicts
  - `ours` - Use baseline version for conflicts

The agent will create a temporary review branch with only those commits applied.

**Important behaviors:**
- Commits are **sorted chronologically** before applying
- Each commit is **preserved individually** (not squashed)
- Cherry-picks happen in date order, earliest to latest

### 2. Run Code Review

After preparation succeeds, start the review:

```
@ReviewLocal.prompt.md
```

This runs the full code review pipeline on the temporary branch.

### 3. Cleanup

After the review is complete, cleanup the temporary branch:

```
@CleanupCommitReview.prompt.md
```

This returns you to your original branch and removes the temporary review branch.

## Example Workflow

```powershell
# Step 1: Prepare
@PrepareCommitReview.prompt.md
# Provide: commits "a1b2c3d e4f5g6h i7j8k9l", strategy "abort"
# Agent will automatically:
#  - Sort commits by date (chronological order)
#  - Find parent of earliest commit as baseline
#  - Cherry-pick all commits individually (preserving commit history)

# Step 2: Review (after prep completes)
@ReviewLocal.prompt.md
# Follow the normal review process (requirements → correctness → parallel audits)

# Step 3: Cleanup (after review finishes)
@CleanupCommitReview.prompt.md
# Choose whether to keep or delete review reports
```

## When to Use This Workflow

- **Reviewing specific commits**: Want to review only certain commits, not entire branch
- **Cross-branch review**: Commits are on different branches
- **Non-contiguous commits**: Reviewing commits that aren't sequential
- **Historical review**: Reviewing older commits without their surrounding changes
- **Selective review**: Excluding teammate commits that occurred between your commits

## How Baseline is Determined

The baseline for comparison is **automatically calculated**:

1. **You provide** a list of commit SHAs
2. **Agent sorts** them chronologically (by commit date)
3. **Agent finds** the parent of the earliest commit
4. **Review compares** your commits against this parent commit

### Why This Matters

This ensures you're reviewing **exactly the commits you specified**, nothing more, nothing less.

**Example:**
```
Your commits to review: A → B → C
Parent of A: P

Timeline in repository:
... → P → A → B → C → D → E (master is here)
              ↑ Your commits

Baseline used: P (parent of A)
Review compares: State at C vs State at P
Result: Only shows changes from A, B, and C
```

This approach:
- ✅ Reviews only your specified commits
- ✅ Doesn't require knowing which branch they came from
- ✅ Works with commits from any branch or multiple branches
- ✅ No confusion about merge-bases or branch states

## Chronological Ordering

Commits are **automatically sorted by date** before being applied:

- **You provide**: Commits in any order (e.g., `C B A`)
- **Agent sorts**: By commit date, earliest to latest
- **Result**: Commits applied in the order they were originally created

### Why This Matters

If commits depend on each other, they must be applied in the correct order:

```
Commit A (Day 1): Adds function foo()
Commit B (Day 2): Calls foo()
Commit C (Day 3): Refactors foo()

If you provide them as: C, A, B
Agent will sort to: A, B, C (chronological order)
Result: Clean application without dependency issues
```

### Preserved Commit History

Each commit is cherry-picked **individually**, preserving:
- Original commit messages
- Individual commit authors
- Separate commits in git history

This makes it easier to:
- Review each change independently
- See the progression of changes
- Identify which specific commit introduced an issue

## Conflict Handling Strategies

### `abort` (Recommended)
- **Safest option**
- Stops immediately if any commit conflicts
- Gives you a chance to resolve conflicts manually
- Use this when accuracy is critical

### `skip`
- **Good for quick reviews**
- Skips commits that conflict
- Shows you which commits were skipped
- Final review only includes successfully applied commits

### `theirs`
- **Risky - use with caution**
- Auto-resolves conflicts using the commit's version
- May produce broken code if conflicts are significant
- Only use when conflicts are expected to be minor (e.g., whitespace)

### `ours`
- **Very risky - rarely useful**
- Auto-resolves conflicts using the baseline's version
- Effectively ignores conflicting parts of the commit
- Only use in special cases (e.g., testing baseline compatibility)

## What Gets Created

### Files
- `.code-review-config.json` - Temporary config file (auto-deleted on cleanup)
- `/code-review/*.md` - Review audit reports (optionally kept after cleanup)

### Git Branches
- `code-review-temp-{timestamp}` - Temporary branch with commits in chronological order (auto-deleted on cleanup)

### Git Commits
- Each selected commit is cherry-picked individually
- Commit messages and authorship are preserved
- Commits appear in chronological order on the revwhen applied to the baseline. Options:
1. Use `skip` strategy to review non-conflicting commits only
2. Manually resolve: checkout the review branch, fix conflicts, commit, then continue
3. Review commits in smaller groups

### "Could not find parent of earliest commit"
The earliest commit has no parent (it's an initial commit). You cannot review an initial commit with this workflow.
### "Conflict detected" with abort strategy
The commits you selected conflict with each other or with the baseline. Options:
1. Use `skip` strategy to review non-conflicting commits only
2. Manually resolve: checkout the review branch, fix conflicts, commit, then continue
3. Adjust your commit list to exclude conflicting commits

### "No review configuration found" during cleanup
You may have already cleaned up or never ran prepare. If you manually created a review branch:
```powershell
git checkout <your-original-branch>
git branch -D code-review-temp-*
```

### Review reports are empty or incomplete
Ensure the prepare step completed successfully before running the review. Check for error messages in the prepare output.

### Stuck on review branch
If cleanup fails:
```powershell
git checkout main  # or your original branch
git branch -D code-review-temp-<timestamp>
Remove-Item .code-review-config.json
```

## Files

- **PrepareCommitReview.prompt.md** - Sets up commits for review
- **CleanupCommitReview.prompt.md** - Cleans up after review
- **ReviewLocal.prompt.md** - Runs the actual code review (same as local branch review)

## Comparison: Local Branch vs Commit List Review

| Aspect | Local Branch Review | Commit List Review |
|--------|--------------------|--------------------|
| **What's reviewed** | All changes since master (committed + uncommitted) | Only specified commits |
| **Setup required** | None | Prepare step required |
| **Cleanup required** | None | Cleanup step required |
| **Use case** | Daily development workflow | Selective/historical review |
| **Conflict risk** | None (reviews existing state) | Possible (cherry-picking) |
| **Speed** | Instant start | Prep can take time |

## Best Practices

1. **Always use `abort` strategy first** - Only switch to other strategies if needed
2. **Review the prepare output** - Check which commits were applied/skipped and their order
3. **Verify chronological ordering** - Ensure commits are sorted as expected
4. **Keep review reports** - They're valuable documentation
5. **Clean up promptly** - Don't leave temporary branches lingering
6. **Verify commit SHAs** - Use full or short SHAs, ensure they exist in your repo
7. **Document skipped commits** - If using `skip`, note which commits weren't reviewed
8. **Check commit dependencies** - Ensure selected commits don't depend on unselected ones

## Integration with Existing Pipeline

The commit list review workflow integrates seamlessly with the existing pipeline:

1. **Prepare** creates a temporary branch (new)
2. **Review** uses the existing auditor pipeline (unchanged)
3. **Cleanup** removes temporary artifacts (new)

All existing auditor agents work without modification - they simply review the temporary branch as if it were a normal feature branch.
