# App Store review readiness — 2026-10-15

Status: code improved; submission readiness is conditional. Apple approval is not guaranteed.

## Addressed
- Fixed a Swift compilation failure and missing Encodable conformance introduced in the previous offline change.
- Added the UserDefaults required-reason declaration CA92.1 for app-only local data.
- Disclosed locally retained flight positions, route data and save time; provided deletion in Settings.
- Marked restored positions as saved observations, not live; observation timestamps remain visible. Map backgrounds require network availability.
- Added a flight search field beside the full-list button, a support link and explicit unofficial/safety notices.
- Normalize leading zeros only when comparing the same numeric callsign and preserve letter suffixes. Unavailable route data remains unknown; no airport is invented.
- No login, payments, advertising, analytics, tracking, device location permission or account creation is implemented.

## Before App Store submission
1. Guideline 5.2.2: obtain/retain authorization for public app distribution using each provider. Existing noncommercial/private API access does not establish public App Store rights. Provider outages and IP restrictions must be resolved for reliable review (2.1).
2. Guideline 5.2: verify rights to the KAL Radar name and avoid suggesting Korean Air endorsement. The app states it is unofficial; this does not replace rights clearance.
3. Guideline 5.1.1: publish a stable public privacy policy URL, use it in App Store Connect, and ensure the App Privacy answers accurately cover provider/hosting handling of IP/request logs. In-app policy and local deletion are implemented.
4. Provide App Store metadata, support contact, age-rating answers and actual-device screenshots. Do not describe registered routes as current operational flight plans or this app as a navigation tool.
5. Review notes: launch performs a public ADS-B query; the provider and regional fallback are displayed. Settings has an explicitly fictional demo for inspecting UI during provider outages. Demo positions are never saved as live positions.

Source: https://developer.apple.com/app-store/review/guidelines/

Installation is a development-device install, not App Store submission.
