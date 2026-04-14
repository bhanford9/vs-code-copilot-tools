# Azure Story Template

Use this complete template when creating Azure DevOps stories:

```markdown
# Story #[NUMBER]: [Title]

## Blocked By
[work item links or "None identified"]

## Backing Content
[background information and context for why the work is needed]

## Goal
[1-2 sentences describing product-level goal]

## Details
[specific technical and project details, including any diagrams. No code or implementation specifics. Just where and what the work is]

## Acceptance Criteria
- [ ] [High-level testable requirement 1]
- [ ] [High-level testable requirement 2]
- [ ] [High-level testable requirement 3]
```

## Complete Example

```markdown
# Story #45821: Add User Profile Export Feature

## Blocked By
Story #45789: User profile API endpoint updates

## Backing Content
Customer support has received 150+ requests for users to export their profile data in compliance with GDPR data portability requirements. This feature is required for EU market compliance and will reduce support ticket volume.

## Goal
Enable users to download a complete copy of their profile data in a machine-readable format, satisfying GDPR data portability requirements.

## Details
Work will occur in the user profile module (`src/modules/profile/`) and export service (`src/services/export/`). 

Components affected:
- User profile dashboard UI
- Export service API
- Data transformation layer
- Email notification system

The export will generate JSON format files containing user profile data, preferences, activity history, and associated metadata. Files will be delivered via secure download link sent to user's registered email address.

## Acceptance Criteria
- [ ] User can request profile data export from dashboard
- [ ] Export includes all profile data, preferences, and activity history
- [ ] Export file is delivered within 24 hours of request
- [ ] Download link expires after 7 days
- [ ] Export is available in JSON format
```
