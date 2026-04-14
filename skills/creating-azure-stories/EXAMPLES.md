# Azure Story Examples

Examples of good and bad content for each story section.

## Blocked By Section

**Good:**
```markdown
## Blocked By
Story #12345: User authentication service deployment
Story #12346: Database migration to v2 schema
```

**Good:**
```markdown
## Blocked By
External dependency: Payment gateway vendor approval
```

**Good:**
```markdown
## Blocked By
None identified
```

**Bad:**
```markdown
## Blocked By
We need to wait for Bob to finish his work
```
(Use story numbers, not names)

## Backing Content Section

**Good:**
```markdown
## Backing Content
Analytics show 40% of mobile users abandon checkout due to slow page load times (>5 seconds). Competitor analysis indicates industry standard is <2 seconds. Improving performance will reduce cart abandonment and increase conversion rate.
```

**Good:**
```markdown
## Backing Content
GDPR compliance audit identified gaps in our data export capabilities. EU regulations require we provide user data exports within 30 days of request. Currently we have no automated mechanism, requiring 8 hours of manual work per request.
```

**Bad:**
```markdown
## Backing Content
We should make the app faster.
```
(Too vague, no context or justification)

**Bad:**
```markdown
## Backing Content
This story implements caching using Redis to improve performance by storing frequently accessed data in memory.
```
(Implementation details belong in Details, not Backing Content)

## Goal Section

**Good:**
```markdown
## Goal
Reduce checkout page load time to under 2 seconds to decrease cart abandonment and improve conversion rate.
```

**Good:**
```markdown
## Goal
Enable users to export their complete profile data in JSON format to comply with GDPR data portability requirements.
```

**Bad:**
```markdown
## Goal
Implement Redis caching layer and optimize database queries.
```
(Implementation details, not outcome-focused)

**Bad:**
```markdown
## Goal
Make the system better and faster with improved code quality and performance optimizations across multiple services.
```
(Too vague, too long, not measurable)

## Details Section

**Good:**
```markdown
## Details
Work occurs in checkout module (`src/modules/checkout/`) and API gateway (`src/gateway/`).

Components affected:
- Checkout page React components
- Product API service
- Image optimization pipeline
- CDN configuration

Will implement caching strategy for product data and images, optimize bundle size, and enable lazy loading for below-fold content. CDN will cache static assets with 24-hour TTL.
```

**Good:**
```markdown
## Details
Export functionality added to user profile service (`src/services/profile/export/`).

Affected systems:
- User profile API
- Background job processor
- Email notification service
- S3 storage for export files

Export generates JSON file with user data, stores in S3, sends secure download link via email. Link expires after 7 days.

```mermaid
graph LR
    A[User Request] --> B[Export Service]
    B --> C[Generate JSON]
    C --> D[Upload to S3]
    D --> E[Email Link]
```

**Bad:**
```markdown
## Details
```python
def export_profile(user_id):
    data = get_user_data(user_id)
    return json.dumps(data)
```

We'll add this function to handle exports.
```
(Code snippets not allowed - focus on WHAT and WHERE, not HOW)

**Bad:**
```markdown
## Details
This will make things faster by using caching.
```
(Too vague - need specifics about where and what)

## Acceptance Criteria

**Good:**
```markdown
## Acceptance Criteria
- [ ] Checkout page loads in under 2 seconds on 4G connection
- [ ] Product images are lazy-loaded below the fold
- [ ] Page load time is tracked in analytics dashboard
- [ ] Cache invalidation occurs when product data updates
```

**Good:**
```markdown
## Acceptance Criteria
- [ ] User can request data export from profile settings
- [ ] Export includes profile, preferences, and activity history
- [ ] Download link delivered within 24 hours
- [ ] Link expires after 7 days
- [ ] Export file is in valid JSON format
```

**Bad:**
```markdown
## Acceptance Criteria
- [ ] Code has unit tests
- [ ] No linting errors
- [ ] Code review approved
```
(These are development process requirements, not business requirements)

**Bad:**
```markdown
## Acceptance Criteria
- [ ] Redis cache returns data in <50ms
- [ ] API endpoint returns HTTP 200
- [ ] Database query uses proper indexes
```
(Implementation details, not user-facing requirements)

**Bad:**
```markdown
## Acceptance Criteria
- [ ] System works correctly
- [ ] Performance is good
- [ ] Users are happy
```
(Too vague, not testable or measurable)

## Complete Story Example

**Good complete story:**

```markdown
# Story #45901: Implement Email Notification Preferences

## Description

### Blocked By
None identified

### Backing Content
User surveys indicate 65% of users want granular control over email notifications. Current all-or-nothing approach leads to users disabling all emails, missing critical account security notifications. Competitor products offer detailed preference controls.

### Goal
Allow users to selectively enable/disable different categories of email notifications while ensuring critical security notifications always send.

### Details
Work in user preferences module (`src/modules/preferences/`) and notification service (`src/services/notifications/`).

Components affected:
- User settings UI
- Preference storage (user_preferences table)
- Email notification service
- Notification categories configuration

Notification categories:
- Marketing emails (user-controllable)
- Product updates (user-controllable)  
- Account activity (user-controllable)
- Security alerts (always enabled)

UI will display toggle switches for each category. Backend validates security notifications cannot be disabled.

## Acceptance Criteria
- [ ] User can enable/disable marketing, product, and activity notifications
- [ ] Security notifications always send regardless of preferences
- [ ] Preference changes apply to future notifications within 5 minutes
- [ ] UI clearly indicates which notifications cannot be disabled
- [ ] Preferences persist across sessions and devices
```
