# KALRadar parallel platforms

Minimize token usage. Preserve existing changes.

Maintain the iOS application and Web version together for feature updates. Shared/radar.json is the canonical version, API provider, filter, disclaimer and demo data source. Never hand edit KERadar/SharedRadar.swift or Web/shared/radar.json.

Run Scripts/generate-project.js and Web/scripts/build.mjs after shared changes. Check synchronization with Scripts/sync-shared.mjs --check, run Web/scripts/check.mjs and validate-artifact.mjs, and build iOS. If UI or platform-specific behavior changes, implement the equivalent supported behavior on the other platform and report any difference. Native and web UI source files are separate; generation does not translate SwiftUI to HTML.

Use Web/.openai/hosting.json's existing project_id for Sites updates and preserve owner-private audience. Publish verified Web edits using the Sites source/publishing workflow unless requested local-only. iOS installations require a connected device and a signed build; never claim device installation from compilation alone.
