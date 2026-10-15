# Azure Story Examples

The domain in these examples is invented. Match the shape and voice, not the subject.

## XS Example

~~~markdown
# Remove the Unused Retry Helper

`retryTwice` has had no callers since uploads moved to the shared retry policy. It also swallows the final error, so anyone who picks it up later loses the failure details. Delete it.

`src/utils/RetryHelper.js`: remove `retryTwice` and its export.

## Acceptance Criteria
- [ ] `retryTwice` and its export are gone, and nothing references them.
- [ ] Uploads still retry through the shared policy.
~~~

## Standard Example

~~~markdown
# Include the End Date in Order Date Filters

## Blocked By
None

## Backing Content
The order list's date-range filter shows orders placed between two dates. It leaves out every order placed on the end date, and support has had three reports this month from users reconciling monthly totals.

## Goal
Monthly totals from the order list should match the orders actually placed.

## Details
`src/orders/OrderFilter.ts`, in `buildDateRange`, sets the upper bound to midnight at the start of the end date, so anything later that day falls outside the range:

```ts
const end = startOfDay(filter.endDate);
query.where("placedAt", "<=", end);
```

Use an exclusive bound at the start of the next day instead: `placedAt < startOfDay(endDate + 1 day)`. Keep the start date inclusive; the export screen depends on it.

## Acceptance Criteria
- [ ] An order placed at 23:59 on the end date appears in the results.
- [ ] An order placed at 00:00 the day after the end date does not.
- [ ] A single-day range returns that day's orders.
~~~

## Before and After

Before (reads as AI-generated):

> The date-range filter does not consistently honor the inclusive end-date contract. Source inspection of `buildDateRange` confirms that the upper bound is computed at the start of the end date. This is not a claim that every report is affected; time-zone handling was not verified. The change must preserve existing start-date behavior, export compatibility, and representative filter consumers, and must not introduce a broader query redesign.

After: the Backing Content in the Standard example, with the cause moved to Details.

What changed:
- The symptom a user sees replaced jargon ("inclusive end-date contract").
- Process narration ("Source inspection confirms") and the defensive caveat moved out. If the evidence matters, it goes in an attachment.
- The list of things to preserve shrank to the one a developer might actually break (the inclusive start date), and moved to Details.
- Backing Content now says only what the subject is and why it needs to change. The cause moved to Details.

## Acceptance Criteria

Good: observable and checkable by someone other than the author.
- [ ] An order placed at 23:59 on the end date appears in the results.

Bad:
- [ ] The filter honors the date-range contract. (Not observable.)
- [ ] Code is reviewed and unit tests pass. (Process, always implied.)
- [ ] `buildDateRange` uses `<` instead of `<=`. (Restates the implementation.)

## Pointing to Evidence

The body points to the attachment as a short suggestion, not a command:

> A script that shows the problem is attached as `repro-date-filter.cjs`; it runs the real filter. If you want to see it, copy it to the repository root and run `node repro-date-filter.cjs`; it prints the orders it finds. Today the 23:59 order is missing.

The attachment holds the script and, in a comment at the top, how the problem was found and what the script does not cover.
