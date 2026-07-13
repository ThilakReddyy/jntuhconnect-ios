# iOS parity status

## Implemented and verified

- Native SwiftUI lifecycle, iOS 18+ `TabView`, and root-owned `NavigationStack`
- Obsidian Academic Home with direct primary hall-ticket search and minimized recent students
- Reusable native result-entry sheet with trim/uppercase normalization, 10-character validation, keyboard submission, native detents, and one/two-roll forms
- Academic result, all-attempt results, backlog report, credits checker, result contrast, class academic ranking, class backlog ranking, and grace-marks eligibility
- Grace-marks proof picker/upload for PDF, PNG, and JPEG files up to 5 MB
- Authenticated API integration, including HTTP 202 queued, HTTP 429 retry guidance, FastAPI/business errors, stale-response protection, offline, timeout, and cancellation states
- Real result screens for semesters, attempts, subjects, backlogs, credits by year, two-student comparison, and class summaries/rankings
- Root-owned result navigation so pushed report screens hide the persistent tab bar
- Updates API integration, supported category filtering, pull-to-refresh, safe external links, and error states
- Profile appearance selection, data controls, sharing, and about links
- Adaptive near-monochrome light/dark palette, Dynamic Type layouts, 44-point controls, and VoiceOver labels/grouping
- App icon and in-app mark based on the Android brand asset
- Unit, decoding, endpoint, validation, live API harness, and XCUITest coverage

## Remaining non-result parity milestones

1. Calendars and native PDF viewing
2. Syllabus tree and native PDF viewing
3. Important Questions
4. Careers/jobs
5. Channels and Help Center content
6. Home update previews and richer update pagination
7. APNs/Firebase push registration and notification routing

These are intentionally not represented as live native data until their complete vertical slices are implemented.
